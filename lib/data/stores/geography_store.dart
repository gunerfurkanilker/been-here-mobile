import 'package:flutter/foundation.dart';

import '../../domain/models/geography_models.dart';
import '../../domain/models/route_feed_models.dart';
import '../services/been_here_api_client.dart';
import '../services/geography_api_service.dart';

/// Backend `/geography/tree` verisini merkezi olarak önbelleğe alan ve
/// çoklu dil (`name_translations`) destekli coğrafya araması/filtrelemesi sunan
/// Vuex-tarzı reaktif Store katmanı.
class GeographyStore extends ChangeNotifier {
  GeographyStore({required this.apiService});

  final GeographyApiService apiService;

  GeographyTreeResponse? _tree;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _lang = 'tr';
  Future<void>? _inFlightLoad;
  String? _inFlightLang;
  int _loadGeneration = 0;
  final Map<String, List<GeographySearchResultItem>> _remoteSearchResultsByQuery =
      <String, List<GeographySearchResultItem>>{};
  final Set<String> _inFlightRemoteQueries = <String>{};
  final Map<String, GeographyExchangeRate> _exchangeRatesByCode =
      <String, GeographyExchangeRate>{};
  Future<void>? _inFlightExchangeRatesLoad;

  GeographyTreeResponse? get tree => _tree;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get lang => _lang;
  Map<String, GeographyExchangeRate> get exchangeRates =>
      Map<String, GeographyExchangeRate>.unmodifiable(_exchangeRatesByCode);

  /// Türkçe karakter duyarlı küçük harfe çevirme (`İ->i`, `I->ı`).
  static String normalizeTr(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  /// Kıta enum'unun varsayılan Türkçe görünen adını döndürür.
  static String continentDisplayName(ContinentFilter continent) {
    switch (continent) {
      case ContinentFilter.global:
        return 'Global';
      case ContinentFilter.europe:
        return 'Avrupa';
      case ContinentFilter.asia:
        return 'Asya';
      case ContinentFilter.northAmerica:
        return 'Kuzey Amerika';
      case ContinentFilter.southAmerica:
        return 'Güney Amerika';
      case ContinentFilter.africa:
        return 'Afrika';
      case ContinentFilter.oceania:
        return 'Okyanusya';
    }
  }

  /// Coğrafya ağacı henüz yüklenmediyse (veya dil değiştiyse) backend'den yükler.
  /// Eşzamanlı çağrıları tek bir aktif istekte birleştirir.
  Future<void> ensureLoaded({String lang = 'tr'}) {
    final normalizedLang = _normalizeLang(lang);
    if (_hasLoaded && _tree != null && _lang == normalizedLang) {
      return Future<void>.value();
    }
    if (_inFlightLoad != null && _inFlightLang == normalizedLang) {
      return _inFlightLoad!;
    }
    return _startLoad(lang: normalizedLang);
  }

  /// Coğrafya ağacını backend'den zorla yeniden yükler.
  Future<void> refresh({String lang = 'tr'}) {
    final normalizedLang = _normalizeLang(lang);
    return _startLoad(lang: normalizedLang);
  }

  String _normalizeLang(String rawLang) {
    final trimmed = rawLang.trim().toLowerCase();
    return trimmed.isNotEmpty ? trimmed : 'tr';
  }

  Future<void> _startLoad({required String lang}) {
    final generation = ++_loadGeneration;
    _inFlightLang = lang;
    final future = _performLoad(lang: lang, generation: generation);
    _inFlightLoad = future;
    return future;
  }

  Future<void> _performLoad({
    required String lang,
    required int generation,
  }) async {
    _lang = lang;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.fetchGeographyTree(lang: lang);
      if (generation != _loadGeneration) return;
      _tree = response;
      _applyExchangeRates(response.exchangeRates);
      _hasLoaded = true;
      _errorMessage = null;
    } on BeenHereApiException catch (error) {
      if (generation != _loadGeneration) return;
      _errorMessage = error.message;
    } catch (_) {
      if (generation != _loadGeneration) return;
      _errorMessage = 'Coğrafya verileri yüklenemedi.';
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        _inFlightLoad = null;
        _inFlightLang = null;
        notifyListeners();
      }
    }
  }

  /// `GET /geography/exchange-rates` üzerinden güncel DB döviz kurlarını çeker,
  /// `_exchangeRatesByCode` haritasını günceller ve `notifyListeners()` tetikler.
  Future<void> refreshExchangeRates() {
    final inFlight = _inFlightExchangeRatesLoad;
    if (inFlight != null) return inFlight;

    final future = _performRefreshExchangeRates();
    _inFlightExchangeRatesLoad = future;
    return future;
  }

  Future<void> _performRefreshExchangeRates() async {
    try {
      final rates = await apiService.fetchExchangeRates();
      if (rates.isNotEmpty) {
        _applyExchangeRates(rates);
        notifyListeners();
      }
    } catch (_) {
      // Döviz kuru yenileme başarısız olursa mevcut DB/fallback kurlarla devam edilir.
    } finally {
      _inFlightExchangeRatesLoad = null;
    }
  }

  void _applyExchangeRates(List<GeographyExchangeRate> rates) {
    if (rates.isEmpty) return;
    _exchangeRatesByCode.clear();
    for (final rate in rates) {
      final code = rate.code.trim().toUpperCase();
      if (code.isEmpty || rate.ratePerUsd <= 0) continue;
      _exchangeRatesByCode[code] = rate;
    }
  }

  /// Verilen ISO 4217 para birimi kodu için DB'deki güncel kuru döndürür;
  /// DB'de henüz yoksa güvenli taban (baseline) katalog kuruna fallback yapar.
  GeographyExchangeRate? rateFor(String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final liveRate = _exchangeRatesByCode[normalized];
    if (liveRate != null && liveRate.ratePerUsd > 0) {
      return liveRate;
    }
    return resolveBaselineExchangeRate(normalized);
  }

  /// `amount` tutarını `fromCode` para biriminden `toCode` para birimine çevirir.
  double convertAmount(
    double amount, {
    required String fromCode,
    required String toCode,
  }) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    if (from.isEmpty || to.isEmpty || from == to) {
      return amount;
    }
    final fromRate = rateFor(from)?.ratePerUsd;
    final toRate = rateFor(to)?.ratePerUsd;
    if (fromRate == null || fromRate <= 0 || toRate == null || toRate <= 0) {
      return amount;
    }
    return (amount / fromRate) * toRate;
  }

  // --- Arama / Filtre Yardımcıları ---

  List<GeographyContinentNode> get continents =>
      _tree?.continents ?? const <GeographyContinentNode>[];

  /// DB verisi yüklendiyse DB kıtalarını ve alt bölgelerini (ör. `Balkanlar` dahil) döndürür.
  List<RouteContinentCatalogItem> get continentsCatalog {
    return continents
        .where((c) => c.continentFilter != ContinentFilter.global)
        .map((c) => c.toRouteContinentCatalogItem(lang: _lang))
        .toList(growable: false);
  }

  GeographyContinentNode? findContinent(ContinentFilter continent) {
    for (final node in continents) {
      if (node.continentFilter == continent) {
        return node;
      }
    }
    return null;
  }

  GeographyCountryNode? findCountry(String countryCode) {
    final target = countryCode.trim().toUpperCase();
    if (target.isEmpty) return null;
    for (final continent in continents) {
      for (final country in continent.countries) {
        if (country.code.toUpperCase() == target) {
          return country;
        }
      }
    }
    return null;
  }

  GeographyRegionNode? findRegion(String regionId) {
    final target = regionId.trim();
    if (target.isEmpty) return null;
    final lowerTarget = target.toLowerCase();
    for (final continent in continents) {
      for (final region in continent.regions) {
        if (region.id == target ||
            region.code == target ||
            region.id.toLowerCase() == lowerTarget ||
            region.code.toLowerCase() == lowerTarget) {
          return region;
        }
      }
    }
    return null;
  }

  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent, {
    bool useRoutesCount = false,
  }) {
    if (continent == ContinentFilter.global) {
      return continents
          .expand((c) => c.countries)
          .map(
            (c) => c.toCountryFilterOption(
              useRoutesCount: useRoutesCount,
              lang: _lang,
            ),
          )
          .toList(growable: false);
    }

    final node = findContinent(continent);
    if (node == null) return const <CountryFilterOption>[];
    return node.countries
        .map(
          (c) => c.toCountryFilterOption(
            useRoutesCount: useRoutesCount,
            lang: _lang,
          ),
        )
        .toList(growable: false);
  }

  List<GeographyCityNode> getCityNodesForCountry(String countryCode) {
    return findCountry(countryCode)?.cities ?? const <GeographyCityNode>[];
  }

  List<String> getCitiesForCountry(String countryCode) {
    return getCityNodesForCountry(countryCode)
        .map((city) => city.localizedName(_lang))
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  GeographyCityNode? findCity(String countryCode, String cityNameOrSlug) {
    final target = normalizeTr(cityNameOrSlug);
    if (target.isEmpty) return null;
    final cities = countryCode.trim().isNotEmpty
        ? getCityNodesForCountry(countryCode)
        : continents.expand((c) => c.countries).expand((c) => c.cities);
    for (final city in cities) {
      if (normalizeTr(city.slug) == target ||
          normalizeTr(city.name) == target ||
          normalizeTr(city.defaultName) == target ||
          city.nameTranslations.values.any((val) => normalizeTr(val) == target)) {
        return city;
      }
    }
    return null;
  }

  List<GeographyDistrictNode> getDistrictNodesForCity(
    String countryCode,
    String cityNameOrSlug,
  ) {
    return findCity(countryCode, cityNameOrSlug)?.districts ??
        const <GeographyDistrictNode>[];
  }

  List<String> getDistrictsForCity(
    String countryCode,
    String cityNameOrSlug,
  ) {
    return getDistrictNodesForCity(countryCode, cityNameOrSlug)
        .map((district) => district.localizedName(_lang))
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  int countPlacesForContinent(ContinentFilter continent) {
    if (continent == ContinentFilter.global) {
      final globalCount = _tree?.globalOption?.placesCount;
      if (globalCount != null) return globalCount;
      return continents.fold<int>(0, (sum, c) => sum + c.placesCount);
    }
    return findContinent(continent)?.placesCount ?? 0;
  }

  int countRoutesForContinent(ContinentFilter continent) {
    if (continent == ContinentFilter.global) {
      final globalCount = _tree?.globalOption?.routesCount;
      if (globalCount != null) return globalCount;
      return continents.fold<int>(0, (sum, c) => sum + c.routesCount);
    }
    return findContinent(continent)?.routesCount ?? 0;
  }

  int countPlacesForRegion(String regionId) {
    return findRegion(regionId)?.placesCount ?? 0;
  }

  int countRoutesForRegion(String regionId) {
    return findRegion(regionId)?.routesCount ?? 0;
  }

  /// Canlı `/geography/search` araması yapar ve sonuçları önbelleğe alır.
  ///
  /// En az 2 karakter gerektirir; ağ/sunucu hatasında yerel ağaç önerileriyle
  /// sessizce devam eder.
  Future<void> searchRemote(String query, {String lang = 'tr'}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    final effectiveLang = _normalizeLang(lang.trim().isNotEmpty ? lang : _lang);
    final normalizedKey = normalizeTr(trimmed);
    final cacheKey = '$effectiveLang:$normalizedKey';
    if (_remoteSearchResultsByQuery.containsKey(cacheKey) ||
        _inFlightRemoteQueries.contains(cacheKey)) {
      return;
    }

    _inFlightRemoteQueries.add(cacheKey);
    try {
      final results = await apiService.searchGeography(
        query: trimmed,
        lang: effectiveLang,
        limit: 25,
      );
      _remoteSearchResultsByQuery[cacheKey] =
          List<GeographySearchResultItem>.unmodifiable(results);
      notifyListeners();
    } catch (_) {
      // Uzak coğrafya araması başarısız olduğunda yerel önerilerle devam edilir.
    } finally {
      _inFlightRemoteQueries.remove(cacheKey);
    }
  }

  /// Arama çubuğu ve keşif paneli için önerileri oluşturur.
  ///
  /// - `query` boşken DB'den gelen `popularCities`, `popularRegions` (ör. `Balkanlar`,
  ///   `Batı Avrupa`) ve `popularContinents` önerilerini döner.
  /// - `query` doluyken kelime önerisi ile birlikte tüm şehir, ilçe, ülke (ve `aliases`),
  ///   alt bölge ve kıtaların `name_translations` değerlerinin tamamında eşleştirme yapar.
  ///   Varsa canlı `/geography/search` sonuçlarını tekilleştirerek birleştirir.
  List<RouteSearchSuggestion> buildSearchSuggestions(
    String query, {
    String lang = 'tr',
  }) {
    final effectiveLang = lang.trim().isNotEmpty ? lang.trim() : _lang;
    final trimmed = query.trim();
    final q = normalizeTr(trimmed);
    final tree = _tree;

    if (q.isEmpty) {
      if (tree == null) return const <RouteSearchSuggestion>[];
      return _buildPopularSuggestions(tree, effectiveLang);
    }

    final suggestions = <RouteSearchSuggestion>[
      RouteSearchSuggestion(
        id: 'keyword:$q',
        type: RouteSearchSuggestionType.keyword,
        title: '$trimmed ile arama yap',
        subtitle: '(kelime ile arama)',
        pill: RouteFeedFilterPill(
          id: 'keyword:$q',
          type: RouteFilterPillType.keyword,
          label: '"$trimmed"',
          keyword: trimmed,
        ),
      ),
    ];

    final seenCityIds = <String>{};
    final seenDistrictIds = <String>{};
    final seenDistrictKeys = <String>{};
    final seenCountryCodes = <String>{};
    final seenRegionIds = <String>{};
    final seenContinentCodes = <String>{};

    if (tree != null) {

    // 1. Şehirler (kıta -> ülke -> şehir ağacındaki tüm şehirler)
    for (final continent in tree.continents) {
      final continentTitle = continent.localizedName(effectiveLang);
      final continentName = continentTitle.isNotEmpty
          ? continentTitle
          : continentDisplayName(continent.continentFilter);

      for (final country in continent.countries) {
        final countryTitle = country.localizedName(effectiveLang);
        final countryName =
            countryTitle.isNotEmpty ? countryTitle : country.code;

        for (final city in country.cities) {
          if (!city.matchesQuery(q, normalizeTr)) continue;
          final cityTitle = city.localizedName(effectiveLang);
          if (cityTitle.isEmpty) continue;
          final normCity = normalizeTr(cityTitle);
          if (!seenCityIds.add(normCity)) continue;

          suggestions.add(
            RouteSearchSuggestion(
              id: 'city:$normCity',
              type: RouteSearchSuggestionType.city,
              title: cityTitle,
              subtitle: '$continentName - $countryName',
              pill: RouteFeedFilterPill(
                id: 'city:$normCity',
                type: RouteFilterPillType.city,
                label: cityTitle,
                cityName: cityTitle,
                countryCode: country.code,
              ),
            ),
          );
        }
      }
    }

    // Popüler şehirler arasında henüz görülmemiş bir kayıt varsa onu da tara
    for (final city in tree.popularCities) {
      if (!city.matchesQuery(q, normalizeTr)) continue;
      final cityTitle = city.localizedName(effectiveLang);
      if (cityTitle.isEmpty) continue;
      final normCity = normalizeTr(cityTitle);
      if (!seenCityIds.add(normCity)) continue;

      final country = findCountry(city.countryCode);
      final continentFilter =
          country?.continentFilter ?? ContinentFilter.global;
      final continentName = _resolveContinentName(
        continentFilter,
        effectiveLang,
      );
      final countryName =
          country?.localizedName(effectiveLang) ?? city.countryCode;
      final subtitle = countryName.isNotEmpty
          ? '$continentName - $countryName'
          : continentName;

      suggestions.add(
        RouteSearchSuggestion(
          id: 'city:$normCity',
          type: RouteSearchSuggestionType.city,
          title: cityTitle,
          subtitle: subtitle,
          pill: RouteFeedFilterPill(
            id: 'city:$normCity',
            type: RouteFilterPillType.city,
            label: cityTitle,
            cityName: cityTitle,
            countryCode: city.countryCode,
          ),
        ),
      );
    }

    // 1b. İlçeler (şehir -> ilçe düğümleri)
    for (final continent in tree.continents) {
      final continentTitle = continent.localizedName(effectiveLang);
      final continentName = continentTitle.isNotEmpty
          ? continentTitle
          : continentDisplayName(continent.continentFilter);

      for (final country in continent.countries) {
        final countryTitle = country.localizedName(effectiveLang);
        final countryName =
            countryTitle.isNotEmpty ? countryTitle : country.code;

        for (final city in country.cities) {
          final cityTitle = city.localizedName(effectiveLang);
          for (final district in city.districts) {
            if (!district.matchesQuery(q, normalizeTr)) continue;
            final districtTitle = district.localizedName(effectiveLang);
            if (districtTitle.isEmpty) continue;
            final suggestionId = district.slug.isNotEmpty
                ? 'district:${district.slug}'
                : 'district:${normalizeTr(districtTitle)}';
            final districtKey =
                '${normalizeTr(cityTitle)}|${normalizeTr(districtTitle)}';
            if (!seenDistrictIds.add(suggestionId) ||
                !seenDistrictKeys.add(districtKey)) {
              continue;
            }

            final hasCity = cityTitle.isNotEmpty;
            suggestions.add(
              RouteSearchSuggestion(
                id: suggestionId,
                type: RouteSearchSuggestionType.district,
                title: hasCity ? '$districtTitle, $cityTitle' : districtTitle,
                subtitle: hasCity
                    ? '$continentName - $countryName ($cityTitle İlçesi)'
                    : '$continentName - $countryName',
                pill: RouteFeedFilterPill(
                  id: suggestionId,
                  type: RouteFilterPillType.district,
                  label: hasCity ? '$districtTitle ($cityTitle)' : districtTitle,
                  districtName: districtTitle,
                  cityName: hasCity ? cityTitle : null,
                  countryCode: country.code,
                ),
              ),
            );
          }
        }
      }
    }

    // 2. Ülkeler (name_translations + aliases + code)
    for (final continent in tree.continents) {
      final continentTitle = continent.localizedName(effectiveLang);
      final continentName = continentTitle.isNotEmpty
          ? continentTitle
          : continentDisplayName(continent.continentFilter);

      for (final country in continent.countries) {
        if (!country.matchesQuery(q, normalizeTr)) continue;
        if (!seenCountryCodes.add(country.code)) continue;
        final countryTitle = country.localizedName(effectiveLang);
        final displayTitle =
            countryTitle.isNotEmpty ? countryTitle : country.code;

        suggestions.add(
          RouteSearchSuggestion(
            id: 'country:${country.code}',
            type: RouteSearchSuggestionType.country,
            title: displayTitle,
            subtitle: '$continentName - Ülke',
            pill: RouteFeedFilterPill(
              id: 'country:${country.code}',
              type: RouteFilterPillType.country,
              label: displayTitle,
              countryCode: country.code,
            ),
          ),
        );
      }
    }

    // 3. Alt Bölgeler (ör. Balkanlar / Balkans)
    for (final continent in tree.continents) {
      final continentTitle = continent.localizedName(effectiveLang);
      final continentName = continentTitle.isNotEmpty
          ? continentTitle
          : continentDisplayName(continent.continentFilter);

      for (final region in continent.regions) {
        if (!region.matchesQuery(q, normalizeTr)) continue;
        final regionId = region.id.isNotEmpty ? region.id : region.code;
        if (!seenRegionIds.add(regionId)) continue;
        final regionTitle = region.localizedName(effectiveLang);

        suggestions.add(
          RouteSearchSuggestion(
            id: 'region:$regionId',
            type: RouteSearchSuggestionType.region,
            title: regionTitle,
            subtitle: '$continentName - Bölge',
            pill: RouteFeedFilterPill(
              id: 'region:$regionId',
              type: RouteFilterPillType.region,
              label: regionTitle,
              regionId: regionId,
              continent: continent.continentFilter,
            ),
          ),
        );
      }
    }

    // 4. Kıtalar (ör. Avrupa / Europe)
    for (final continent in tree.continents) {
      if (continent.continentFilter == ContinentFilter.global) continue;
      if (!continent.matchesQuery(q, normalizeTr)) continue;
      final code = continent.continentFilter.code;
      if (!seenContinentCodes.add(code)) continue;
      final continentTitle = continent.localizedName(effectiveLang);

      suggestions.add(
        RouteSearchSuggestion(
          id: 'continent:$code',
          type: RouteSearchSuggestionType.continent,
          title: continentTitle,
          subtitle: 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:$code',
            type: RouteFilterPillType.continent,
            label: continentTitle,
            continent: continent.continentFilter,
          ),
        ),
      );
    }
    }

    // 5. Canlı /geography/search sonuçlarını (yeni keşfedilen veya trigram fuzzy eşleşmeler) tekilleştirerek ekle
    final remoteCacheKey = '${_normalizeLang(effectiveLang)}:$q';
    final remoteResults = _remoteSearchResultsByQuery[remoteCacheKey];
    if (remoteResults != null && remoteResults.isNotEmpty) {
      for (final item in remoteResults) {
        final suggestion = _remoteItemToSuggestion(
          item,
          lang: effectiveLang,
          seenCityIds: seenCityIds,
          seenDistrictIds: seenDistrictIds,
          seenDistrictKeys: seenDistrictKeys,
          seenCountryCodes: seenCountryCodes,
          seenRegionIds: seenRegionIds,
          seenContinentCodes: seenContinentCodes,
        );
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
    }

    return suggestions;
  }

  RouteSearchSuggestion? _remoteItemToSuggestion(
    GeographySearchResultItem item, {
    required String lang,
    required Set<String> seenCityIds,
    required Set<String> seenDistrictIds,
    required Set<String> seenDistrictKeys,
    required Set<String> seenCountryCodes,
    required Set<String> seenRegionIds,
    required Set<String> seenContinentCodes,
  }) {
    final localized = item.localizedName(lang);
    switch (item.type) {
      case 'district':
        if (localized.isEmpty) return null;
        final cityTitle = (item.cityName ?? '').trim();
        final slugOrKey = item.code.isNotEmpty
            ? item.code
            : (item.id.isNotEmpty ? item.id : normalizeTr(localized));
        final suggestionId = 'district:$slugOrKey';
        final districtKey =
            '${normalizeTr(cityTitle)}|${normalizeTr(localized)}';
        if (!seenDistrictIds.add(suggestionId) ||
            !seenDistrictKeys.add(districtKey)) {
          return null;
        }
        final hasCity = cityTitle.isNotEmpty;
        final countryCode = item.countryCode?.trim().toUpperCase();
        final subtitle = item.subtitle.isNotEmpty
            ? item.subtitle
            : (hasCity
                ? '${countryCode ?? ''} ($cityTitle İlçesi)'.trim()
                : 'İlçe');
        return RouteSearchSuggestion(
          id: suggestionId,
          type: RouteSearchSuggestionType.district,
          title: hasCity ? '$localized, $cityTitle' : localized,
          subtitle: subtitle,
          pill: RouteFeedFilterPill(
            id: suggestionId,
            type: RouteFilterPillType.district,
            label: hasCity ? '$localized ($cityTitle)' : localized,
            districtName: localized,
            cityName: hasCity ? cityTitle : null,
            countryCode:
                (countryCode != null && countryCode.isNotEmpty) ? countryCode : null,
          ),
        );
      case 'city':
        final cityTitle =
            localized.isNotEmpty ? localized : (item.cityName ?? '').trim();
        if (cityTitle.isEmpty) return null;
        final normCity = normalizeTr(cityTitle);
        if (!seenCityIds.add(normCity)) return null;
        final countryCode = item.countryCode?.trim().toUpperCase();
        final continentFilter = item.continentFilter ?? ContinentFilter.global;
        final fallbackSubtitle = countryCode != null && countryCode.isNotEmpty
            ? '${_resolveContinentName(continentFilter, lang)} - $countryCode'
            : _resolveContinentName(continentFilter, lang);
        return RouteSearchSuggestion(
          id: 'city:$normCity',
          type: RouteSearchSuggestionType.city,
          title: cityTitle,
          subtitle: item.subtitle.isNotEmpty ? item.subtitle : fallbackSubtitle,
          pill: RouteFeedFilterPill(
            id: 'city:$normCity',
            type: RouteFilterPillType.city,
            label: cityTitle,
            cityName: cityTitle,
            countryCode:
                (countryCode != null && countryCode.isNotEmpty) ? countryCode : null,
          ),
        );
      case 'country':
        final countryCode =
            (item.countryCode ?? item.code).trim().toUpperCase();
        if (countryCode.isEmpty || !seenCountryCodes.add(countryCode)) {
          return null;
        }
        final displayTitle = localized.isNotEmpty ? localized : countryCode;
        final continentFilter = item.continentFilter ?? ContinentFilter.global;
        return RouteSearchSuggestion(
          id: 'country:$countryCode',
          type: RouteSearchSuggestionType.country,
          title: displayTitle,
          subtitle: item.subtitle.isNotEmpty
              ? item.subtitle
              : '${_resolveContinentName(continentFilter, lang)} - Ülke',
          pill: RouteFeedFilterPill(
            id: 'country:$countryCode',
            type: RouteFilterPillType.country,
            label: displayTitle,
            countryCode: countryCode,
          ),
        );
      case 'region':
        final regionId = (item.regionCode ??
                (item.code.isNotEmpty ? item.code : item.id))
            .trim();
        if (regionId.isEmpty || !seenRegionIds.add(regionId)) return null;
        final regionTitle = localized.isNotEmpty ? localized : regionId;
        final continentFilter = item.continentFilter;
        return RouteSearchSuggestion(
          id: 'region:$regionId',
          type: RouteSearchSuggestionType.region,
          title: regionTitle,
          subtitle: item.subtitle.isNotEmpty
              ? item.subtitle
              : (continentFilter != null
                  ? '${_resolveContinentName(continentFilter, lang)} - Bölge'
                  : 'Bölge'),
          pill: RouteFeedFilterPill(
            id: 'region:$regionId',
            type: RouteFilterPillType.region,
            label: regionTitle,
            regionId: regionId,
            continent: continentFilter,
          ),
        );
      case 'continent':
        final continentFilter =
            item.continentFilter ?? ContinentFilter.fromCode(item.code);
        if (continentFilter == ContinentFilter.global ||
            !seenContinentCodes.add(continentFilter.code)) {
          return null;
        }
        final continentTitle = localized.isNotEmpty
            ? localized
            : _resolveContinentName(continentFilter, lang);
        return RouteSearchSuggestion(
          id: 'continent:${continentFilter.code}',
          type: RouteSearchSuggestionType.continent,
          title: continentTitle,
          subtitle: item.subtitle.isNotEmpty ? item.subtitle : 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:${continentFilter.code}',
            type: RouteFilterPillType.continent,
            label: continentTitle,
            continent: continentFilter,
          ),
        );
      default:
        return null;
    }
  }

  List<RouteSearchSuggestion> _buildPopularSuggestions(
    GeographyTreeResponse tree,
    String lang,
  ) {
    final suggestions = <RouteSearchSuggestion>[];
    final seenIds = <String>{};

    for (final city in tree.popularCities) {
      final cityTitle = city.localizedName(lang);
      if (cityTitle.isEmpty) continue;
      final normCity = normalizeTr(cityTitle);
      final suggestionId = 'popular:city:$normCity';
      if (!seenIds.add(suggestionId)) continue;

      final country = findCountry(city.countryCode);
      final continentFilter =
          country?.continentFilter ?? ContinentFilter.global;
      final continentName = _resolveContinentName(continentFilter, lang);
      final countryName = country?.localizedName(lang) ?? city.countryCode;
      final subtitle = countryName.isNotEmpty
          ? '$continentName - $countryName'
          : continentName;

      suggestions.add(
        RouteSearchSuggestion(
          id: suggestionId,
          type: RouteSearchSuggestionType.city,
          title: cityTitle,
          subtitle: subtitle,
          pill: RouteFeedFilterPill(
            id: 'city:$normCity',
            type: RouteFilterPillType.city,
            label: cityTitle,
            cityName: cityTitle,
            countryCode: city.countryCode,
          ),
        ),
      );
    }

    for (final region in tree.popularRegions) {
      final regionId = region.id.isNotEmpty ? region.id : region.code;
      final suggestionId = 'popular:region:$regionId';
      if (!seenIds.add(suggestionId)) continue;

      final regionTitle = region.localizedName(lang);
      final continentName = _resolveContinentName(region.continentFilter, lang);

      suggestions.add(
        RouteSearchSuggestion(
          id: suggestionId,
          type: RouteSearchSuggestionType.region,
          title: regionTitle,
          subtitle: '$continentName - Bölge',
          pill: RouteFeedFilterPill(
            id: 'region:$regionId',
            type: RouteFilterPillType.region,
            label: regionTitle,
            regionId: regionId,
            continent: region.continentFilter,
          ),
        ),
      );
    }

    for (final continent in tree.popularContinents) {
      final code = continent.continentFilter.code;
      final suggestionId = 'popular:continent:$code';
      if (!seenIds.add(suggestionId)) continue;
      final continentTitle = continent.localizedName(lang);

      suggestions.add(
        RouteSearchSuggestion(
          id: suggestionId,
          type: RouteSearchSuggestionType.continent,
          title: continentTitle,
          subtitle: 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:$code',
            type: RouteFilterPillType.continent,
            label: continentTitle,
            continent: continent.continentFilter,
          ),
        ),
      );
    }

    return suggestions;
  }

  String _resolveContinentName(ContinentFilter continent, String lang) {
    final node = findContinent(continent);
    if (node != null) {
      final localized = node.localizedName(lang);
      if (localized.isNotEmpty) return localized;
    }
    return continentDisplayName(continent);
  }
}
