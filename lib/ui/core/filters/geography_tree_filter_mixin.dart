import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/static_home_routes_repository.dart';
import '../../../domain/models/route_feed_models.dart';
import 'been_here_search_filter_controller.dart';

/// Anasayfa (Rota Akışı), Mekan Arama (Mekan Keşfi) ve Rota Oluşturma
/// ekranlarının ortak kullandığı:
/// 1) Toggle / Kaldırılabilir Filtre Hapları & Kıta/Bölge Arama Önerileri (`BeenHereSearchFilterController`)
/// 2) Hiyerarşik Coğrafya Ağacı (Kıta > Ülke > Şehir) ve Akıllı Ağaç Arama
/// 3) Anlık Konum (Yakınımdaki Konumlar - Konum Öncelikli)
/// 4) 3 Karakter + 5 Saniye Debounce'lu Metin Arama Mixin'i.
mixin GeographyTreeFilterMixin on ChangeNotifier
    implements BeenHereSearchFilterController {
  /// Kullanıcı yazmayı bıraktıktan sonra otomatik arama için beklenecek süre (5 sn)
  static const Duration searchDebounceDuration = Duration(seconds: 5);

  /// Arama ve debounce tetiklenmesi için zorunlu minimum karakter sayısı
  static const int minSearchChars = 3;

  final Set<ContinentFilter> _selectedFullContinents = <ContinentFilter>{};
  final Set<String> _selectedFullCountryCodes = <String>{};
  final Set<String> _selectedCities = <String>{};

  final Set<ContinentFilter> _expandedContinents = <ContinentFilter>{};
  final Set<String> _expandedCountryCodes = <String>{};

  /// Hiyerarşik bölge ağacı çekmecesinin en üstündeki akıllı filtre metni
  String _treeSearchQuery = '';

  /// Yakınımdaki Konumları Göster (Anlık Konum) modu aktif mi?
  bool _isNearbyMode = false;

  /// Yakınımdaki Konumlar aktifken gösterilen anlık konum doğrulama metni
  final String _detectedLocationLabel = 'Konak / İzmir / Türkiye';

  /// Kullanıcının arama kutucuğuna anlık yazdığı metin
  String _draftSearchInput = '';

  /// 5 sn sonunda veya "Ara" butonuna basıldığında aktifleşen arama metni
  String _committedSearchQuery = '';

  /// 5 saniyelik geri sayım (debounce) bekleniyor mu?
  bool _isWaitingForDebounce = false;
  int _debounceCycleId = 0;

  Timer? _searchDebounceTimer;

  /// Rotalar için Çift Taraflı Bütçe Aralığı (TL) Filtresi Sınırları
  static const double minBudgetLimitTl = 0.0;
  static const double maxBudgetLimitTl = 100000.0;

  double _selectedMinBudgetTl = minBudgetLimitTl;
  double _selectedMaxBudgetTl = maxBudgetLimitTl;

  /// Ortak arama paneli ve filtre çubuğunda kullanılan toggle/kaldırılabilir filtre hapları
  final List<RouteFeedFilterPill> _filterPills = <RouteFeedFilterPill>[];

  static const Map<String, ({String nameTr, String continentName, List<String> cities})>
      _popularExtraCatalog = {
    'ES': (
      nameTr: 'İspanya',
      continentName: 'Avrupa',
      cities: ['Madrid', 'Barselona', 'Sevilla', 'Cadiz'],
    ),
  };

  /// Alt sınıfların sağlaması gereken ülke ve şehir veri kaynakları
  List<CountryFilterOption> getCountriesForContinent(ContinentFilter continent);
  List<String> getCitiesForCountry(String countryCode);

  // --- BeenHereSearchFilterController: Filtre Hapları & Arama Kataloğu ---

  @override
  List<RouteFeedFilterPill> get filterPills =>
      List<RouteFeedFilterPill>.unmodifiable(_filterPills);

  List<RouteFeedFilterPill> get enabledFilterPills =>
      _filterPills.where((p) => p.isEnabled).toList(growable: false);

  @override
  bool get hasFilterPills => _filterPills.isNotEmpty;

  @override
  int get enabledFilterPillsCount =>
      _filterPills.where((p) => p.isEnabled).length;

  @override
  int get activeFilterCount =>
      enabledFilterPillsCount + (isBudgetFilterActive ? 1 : 0);

  @override
  List<RouteContinentCatalogItem> get searchContinentsCatalog =>
      StaticHomeRoutesRepository.continentsCatalog;

  @override
  int countItemsForContinent(ContinentFilter continent) =>
      getCountriesForContinent(continent).length;

  @override
  int countItemsForRegion(RouteRegionCatalogItem region) =>
      region.countryCodes.length;

  @override
  String get itemCountUnitLabel => 'Ülke';

  @override
  void applyFilterPills(List<RouteFeedFilterPill> pills) {
    _filterPills.clear();
    final seenIds = <String>{};
    for (final pill in pills) {
      if (seenIds.add(pill.id)) {
        _filterPills.add(pill);
      }
    }
    notifyListeners();
  }

  /// Hapın gövdesine dokunulduğunda hapı silmeden aktif/pasif durumunu değiştirir.
  @override
  void toggleFilterPill(String pillId) {
    final index = _filterPills.indexWhere((p) => p.id == pillId);
    if (index == -1) return;
    _filterPills[index] = _filterPills[index].copyWith(
      isEnabled: !_filterPills[index].isEnabled,
    );
    notifyListeners();
  }

  /// Hapın sağındaki X ikonuna basıldığında hapı listeden kalıcı olarak kaldırır.
  @override
  void removeFilterPill(String pillId) {
    final before = _filterPills.length;
    _filterPills.removeWhere((p) => p.id == pillId);
    if (_filterPills.length != before) {
      notifyListeners();
    }
  }

  @override
  void clearAllFilterPills() {
    if (_filterPills.isEmpty) return;
    _filterPills.clear();
    notifyListeners();
  }

  static String _continentDisplayName(ContinentFilter continent) {
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

  @override
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    final trimmed = query.trim();
    final q = normalizeTr(trimmed);

    if (q.isEmpty) {
      return [
        const RouteSearchSuggestion(
          id: 'popular:city:marmaris',
          type: RouteSearchSuggestionType.city,
          title: 'Marmaris',
          subtitle: 'Avrupa - Türkiye',
          pill: RouteFeedFilterPill(
            id: 'city:marmaris',
            type: RouteFilterPillType.city,
            label: 'Marmaris',
            cityName: 'Marmaris',
            countryCode: 'TR',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:city:roma',
          type: RouteSearchSuggestionType.city,
          title: 'Roma',
          subtitle: 'Avrupa - İtalya',
          pill: RouteFeedFilterPill(
            id: 'city:roma',
            type: RouteFilterPillType.city,
            label: 'Roma',
            cityName: 'Roma',
            countryCode: 'IT',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:city:madrid',
          type: RouteSearchSuggestionType.city,
          title: 'Madrid',
          subtitle: 'Avrupa - İspanya',
          pill: RouteFeedFilterPill(
            id: 'city:madrid',
            type: RouteFilterPillType.city,
            label: 'Madrid',
            cityName: 'Madrid',
            countryCode: 'ES',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:region:western_europe',
          type: RouteSearchSuggestionType.region,
          title: 'Batı Avrupa',
          subtitle: 'Avrupa - Bölge',
          pill: RouteFeedFilterPill(
            id: 'region:western_europe',
            type: RouteFilterPillType.region,
            label: 'Batı Avrupa',
            regionId: 'western_europe',
            continent: ContinentFilter.europe,
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:continent:EUROPE',
          type: RouteSearchSuggestionType.continent,
          title: 'Avrupa',
          subtitle: 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:EUROPE',
            type: RouteFilterPillType.continent,
            label: 'Avrupa',
            continent: ContinentFilter.europe,
          ),
        ),
      ];
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
    final seenCountryCodes = <String>{};
    final allCountries = <CountryFilterOption>[
      for (final continent in selectableContinents)
        ...getCountriesForContinent(continent),
    ];

    // 1. Repository şehirleri (ülkelere göre)
    for (final country in allCountries) {
      final continentName = _continentDisplayName(country.continent);
      final cities = getCitiesForCountry(country.code);
      for (final city in cities) {
        final normCity = normalizeTr(city);
        if (normCity.contains(q) && seenCityIds.add(normCity)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'city:$normCity',
              type: RouteSearchSuggestionType.city,
              title: city,
              subtitle: '$continentName - ${country.nameTr}',
              pill: RouteFeedFilterPill(
                id: 'city:$normCity',
                type: RouteFilterPillType.city,
                label: city,
                cityName: city,
                countryCode: country.code,
              ),
            ),
          );
        }
      }
    }

    // 2. Popüler katalog şehirleri (örn: Madrid / İspanya)
    for (final entry in _popularExtraCatalog.entries) {
      for (final city in entry.value.cities) {
        final normCity = normalizeTr(city);
        if (normCity.contains(q) && seenCityIds.add(normCity)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'city:$normCity',
              type: RouteSearchSuggestionType.city,
              title: city,
              subtitle: '${entry.value.continentName} - ${entry.value.nameTr}',
              pill: RouteFeedFilterPill(
                id: 'city:$normCity',
                type: RouteFilterPillType.city,
                label: city,
                cityName: city,
                countryCode: entry.key,
              ),
            ),
          );
        }
      }
    }

    // 3. Eşleşen ülkeler
    for (final country in allCountries) {
      if ((normalizeTr(country.nameTr).contains(q) ||
              normalizeTr(country.code) == q) &&
          seenCountryCodes.add(country.code)) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'country:${country.code}',
            type: RouteSearchSuggestionType.country,
            title: country.nameTr,
            subtitle: '${_continentDisplayName(country.continent)} - Ülke',
            pill: RouteFeedFilterPill(
              id: 'country:${country.code}',
              type: RouteFilterPillType.country,
              label: country.nameTr,
              countryCode: country.code,
            ),
          ),
        );
      }
    }
    for (final entry in _popularExtraCatalog.entries) {
      if ((normalizeTr(entry.value.nameTr).contains(q) ||
              normalizeTr(entry.key) == q) &&
          seenCountryCodes.add(entry.key)) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'country:${entry.key}',
            type: RouteSearchSuggestionType.country,
            title: entry.value.nameTr,
            subtitle: '${entry.value.continentName} - Ülke',
            pill: RouteFeedFilterPill(
              id: 'country:${entry.key}',
              type: RouteFilterPillType.country,
              label: entry.value.nameTr,
              countryCode: entry.key,
            ),
          ),
        );
      }
    }

    // 4. Eşleşen alt bölgeler ve kıtalar
    for (final continent in searchContinentsCatalog) {
      for (final region in continent.regions) {
        if (normalizeTr(region.name).contains(q)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'region:${region.id}',
              type: RouteSearchSuggestionType.region,
              title: region.name,
              subtitle: '${continent.name} - Bölge',
              pill: RouteFeedFilterPill(
                id: 'region:${region.id}',
                type: RouteFilterPillType.region,
                label: region.name,
                regionId: region.id,
                continent: continent.continent,
              ),
            ),
          );
        }
      }
      if (normalizeTr(continent.name).contains(q)) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'continent:${continent.continent.code}',
            type: RouteSearchSuggestionType.continent,
            title: continent.name,
            subtitle: 'Kıta',
            pill: RouteFeedFilterPill(
              id: 'continent:${continent.continent.code}',
              type: RouteFilterPillType.continent,
              label: continent.name,
              continent: continent.continent,
            ),
          ),
        );
      }
    }

    return suggestions;
  }

  /// Türkçe karakter duyarlı küçük harfe çevirme (İ->i, I->ı)
  static String normalizeTr(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  // --- Konum, Bütçe & Metin Arama Getter ve Aksiyonları ---

  @override
  bool get isNearbyMode => _isNearbyMode;
  @override
  String get detectedLocationLabel => _detectedLocationLabel;
  String get draftSearchInput => _draftSearchInput;
  String get committedSearchQuery => _committedSearchQuery;
  bool get isWaitingForDebounce => _isWaitingForDebounce;
  int get debounceCycleId => _debounceCycleId;

  @override
  double get selectedMinBudgetTl => _selectedMinBudgetTl;
  @override
  double get selectedMaxBudgetTl => _selectedMaxBudgetTl;
  @override
  bool get isBudgetFilterActive =>
      _selectedMinBudgetTl > minBudgetLimitTl ||
      _selectedMaxBudgetTl < maxBudgetLimitTl;

  static String formatTlCurrency(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '₺$buffer';
  }

  @override
  String get budgetFilterCompactLabel =>
      '${formatTlCurrency(_selectedMinBudgetTl)} – ${formatTlCurrency(_selectedMaxBudgetTl)}';

  @override
  void updateBudgetRange(double minTl, double maxTl) {
    final clampedMin = minTl.clamp(minBudgetLimitTl, maxBudgetLimitTl);
    final clampedMax = maxTl.clamp(clampedMin, maxBudgetLimitTl);
    if (_selectedMinBudgetTl == clampedMin &&
        _selectedMaxBudgetTl == clampedMax) {
      return;
    }
    _selectedMinBudgetTl = clampedMin;
    _selectedMaxBudgetTl = clampedMax;
    notifyListeners();
  }

  @override
  void resetBudgetFilter() {
    if (!isBudgetFilterActive) return;
    _selectedMinBudgetTl = minBudgetLimitTl;
    _selectedMaxBudgetTl = maxBudgetLimitTl;
    notifyListeners();
  }

  @override
  void toggleNearbySearch() {
    _isNearbyMode = !_isNearbyMode;
    notifyListeners();
  }

  /// Kullanıcı her harfe bastığında API'ye istek atılmaz;
  /// yalnızca en az 3 karakter girildikten sonra 5 saniyelik debounce başlar.
  void onSearchInputChanged(String value) {
    _draftSearchInput = value;
    _searchDebounceTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _isWaitingForDebounce = false;
      _committedSearchQuery = '';
      notifyListeners();
      return;
    }

    if (trimmed.length < minSearchChars) {
      _isWaitingForDebounce = false;
      notifyListeners();
      return;
    }

    _isWaitingForDebounce = true;
    _debounceCycleId++;
    notifyListeners();

    _searchDebounceTimer = Timer(searchDebounceDuration, () {
      executeTextSearchNow();
    });
  }

  /// Manuel "Ara" butonuna basıldığında (debounce dolmadan) veya 5 sn dolduğunda
  /// 3 karakter kontrolü yaparak aramayı çalıştırır.
  bool executeTextSearchNow() {
    final trimmed = _draftSearchInput.trim();
    if (trimmed.length < minSearchChars) {
      return false;
    }

    _searchDebounceTimer?.cancel();
    _isWaitingForDebounce = false;
    _committedSearchQuery = trimmed;
    notifyListeners();
    return true;
  }

  void clearSearchInput() {
    _searchDebounceTimer?.cancel();
    _draftSearchInput = '';
    _committedSearchQuery = '';
    _isWaitingForDebounce = false;
    notifyListeners();
  }

  @protected
  void disposeSearchDebounce() {
    _searchDebounceTimer?.cancel();
  }

  // --- Coğrafi Ağaç Getter ve Aksiyonları ---

  String get treeSearchQuery => _treeSearchQuery;

  void updateTreeSearchQuery(String query) {
    _treeSearchQuery = query;
    notifyListeners();
  }

  void clearTreeSearchQuery() {
    if (_treeSearchQuery.isEmpty) return;
    _treeSearchQuery = '';
    notifyListeners();
  }

  List<ContinentFilter> get selectableContinents => ContinentFilter.values
      .where((c) => c != ContinentFilter.global)
      .toList(growable: false);

  /// Ağaç içi arama metnine göre eşleşen kıtaları döndürür
  List<ContinentFilter> get filteredContinentsForTree {
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty) {
      return selectableContinents
          .where((continent) => getCountriesForContinent(continent).isNotEmpty)
          .toList(growable: false);
    }

    return selectableContinents.where((continent) {
      if (normalizeTr(continent.label).contains(q)) {
        return getCountriesForContinent(continent).isNotEmpty;
      }
      return getFilteredCountriesForTree(continent).isNotEmpty;
    }).toList(growable: false);
  }

  /// Ağaç içi arama metnine göre kıtanın altındaki eşleşen ülkeleri döndürür
  List<CountryFilterOption> getFilteredCountriesForTree(
    ContinentFilter continent,
  ) {
    final allCountries = getCountriesForContinent(continent);
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty || normalizeTr(continent.label).contains(q)) {
      return allCountries;
    }

    return allCountries.where((country) {
      if (normalizeTr(country.nameTr).contains(q) ||
          normalizeTr(country.code).contains(q)) {
        return true;
      }
      final cities = getCitiesForCountry(country.code);
      return cities.any((city) => normalizeTr(city).contains(q));
    }).toList(growable: false);
  }

  /// Ağaç içi arama metnine göre ülkenin altındaki eşleşen şehirleri döndürür
  List<String> getFilteredCitiesForTree(CountryFilterOption country) {
    final allCities = getCitiesForCountry(country.code);
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty ||
        normalizeTr(country.nameTr).contains(q) ||
        normalizeTr(country.code).contains(q)) {
      return allCities;
    }

    final matchingCities =
        allCities.where((c) => normalizeTr(c).contains(q)).toList();
    return matchingCities.isNotEmpty ? matchingCities : allCities;
  }

  bool get isGlobalSelected =>
      _selectedFullContinents.isEmpty &&
      _selectedFullCountryCodes.isEmpty &&
      _selectedCities.isEmpty;

  Set<ContinentFilter> get selectedFullContinents =>
      Set<ContinentFilter>.unmodifiable(_selectedFullContinents);
  Set<String> get selectedFullCountryCodes =>
      Set<String>.unmodifiable(_selectedFullCountryCodes);
  Set<String> get selectedCities => Set<String>.unmodifiable(_selectedCities);

  bool isContinentChecked(ContinentFilter continent) =>
      _selectedFullContinents.contains(continent);

  bool isContinentExpanded(ContinentFilter continent) {
    if (isContinentChecked(continent)) return false;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty) {
      return getFilteredCountriesForTree(continent).isNotEmpty;
    }
    return _expandedContinents.contains(continent);
  }

  bool isCountryChecked(String countryCode) =>
      _selectedFullCountryCodes.contains(countryCode);

  bool isCountryExpanded(String countryCode) {
    if (isCountryChecked(countryCode)) return false;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty) {
      final cities = getCitiesForCountry(countryCode);
      if (cities.any((c) => normalizeTr(c).contains(q))) {
        return true;
      }
    }
    return _expandedCountryCodes.contains(countryCode);
  }

  bool isCityChecked(String city) => _selectedCities.contains(city);

  /// Kıta checkbox'ı işaretli DEĞİLKEN altındaki ülke/şehir seçim özetini döndürür
  String? getContinentPartialSelectionBadge(ContinentFilter continent) {
    if (isContinentChecked(continent)) return null;
    final countries = getCountriesForContinent(continent);
    int checkedCountryCount = 0;
    int checkedCityCount = 0;

    for (final c in countries) {
      if (_selectedFullCountryCodes.contains(c.code)) {
        checkedCountryCount++;
      } else {
        final cities = getCitiesForCountry(c.code);
        checkedCityCount += cities.where(_selectedCities.contains).length;
      }
    }

    if (checkedCountryCount > 0 && checkedCityCount > 0) {
      return '$checkedCountryCount ülke • $checkedCityCount şehir';
    } else if (checkedCountryCount > 0) {
      return '$checkedCountryCount ülke seçili';
    } else if (checkedCityCount > 0) {
      return '$checkedCityCount şehir seçili';
    }
    return null;
  }

  /// Ülke checkbox'ı işaretli DEĞİLKEN altındaki şehir seçim özetini döndürür
  String? getCountryPartialSelectionBadge(String countryCode) {
    if (isCountryChecked(countryCode)) return null;
    final cities = getCitiesForCountry(countryCode);
    final count = cities.where(_selectedCities.contains).length;
    if (count > 0) {
      return '$count şehir seçili';
    }
    return null;
  }

  /// Seçili kıta, ülke ve şehirleri okunaklı hiyerarşik özet metni olarak döndürür.
  /// Örn: "🇪🇺 Avrupa (Tümü)" veya "🇮🇹 İtalya: Como, Milano, Cinque Terre"
  String get geographyFilterButtonTitle {
    if (isGlobalSelected) {
      return 'Global (Tüm Dünya)';
    }
    final parts = <String>[];
    final handledCities = <String>{};

    for (final continent in _selectedFullContinents) {
      parts.add('${continent.label} (Tümü)');
    }

    for (final continent in selectableContinents) {
      if (_selectedFullContinents.contains(continent)) continue;
      for (final country in getCountriesForContinent(continent)) {
        if (_selectedFullCountryCodes.contains(country.code)) {
          parts.add('${country.flagEmoji} ${country.nameTr} (Tümü)');
        } else {
          final countryCities = getCitiesForCountry(country.code);
          final selectedInCountry =
              countryCities.where(_selectedCities.contains).toList();
          if (selectedInCountry.isNotEmpty) {
            handledCities.addAll(selectedInCountry);
            parts.add(
              '${country.flagEmoji} ${country.nameTr}: ${selectedInCountry.join(', ')}',
            );
          }
        }
      }
    }

    for (final city in _selectedCities) {
      if (!handledCities.contains(city)) {
        parts.add('📍 $city');
      }
    }

    return parts.join('  •  ');
  }

  // --- Hiyerarşik Coğrafya Ağacı Aksiyonları ---

  void resetToGlobal() {
    final hadPills = _filterPills.isNotEmpty;
    _filterPills.clear();
    if (isGlobalSelected &&
        _expandedContinents.isEmpty &&
        _expandedCountryCodes.isEmpty) {
      if (hadPills) {
        notifyListeners();
      }
      return;
    }
    _selectedFullContinents.clear();
    _selectedFullCountryCodes.clear();
    _selectedCities.clear();
    _expandedContinents.clear();
    _expandedCountryCodes.clear();
    notifyListeners();
  }

  /// Kıta checkbox'ı işaretlendiğinde o kıtadaki ülkeleri görüntülemeye gerek kalmaz (alt ağaç kapanır).
  void toggleContinentCheckbox(ContinentFilter continent) {
    _isNearbyMode = false;
    if (_selectedFullContinents.contains(continent)) {
      _selectedFullContinents.remove(continent);
    } else {
      _selectedFullContinents.add(continent);
      _expandedContinents.remove(continent);

      for (final country in getCountriesForContinent(continent)) {
        _selectedFullCountryCodes.remove(country.code);
        _expandedCountryCodes.remove(country.code);
        for (final city in getCitiesForCountry(country.code)) {
          _selectedCities.remove(city);
        }
      }
    }
    notifyListeners();
  }

  /// Kıta checkbox'ı işaretli değilse altındaki ülkeleri açıp kapatır
  void toggleContinentExpanded(ContinentFilter continent) {
    if (_selectedFullContinents.contains(continent)) return;
    if (_expandedContinents.contains(continent)) {
      _expandedContinents.remove(continent);
    } else {
      _expandedContinents.add(continent);
    }
    notifyListeners();
  }

  /// Ülke checkbox'ı işaretlendiğinde o ülkeye ait şehirler otomatik dahil edilir ve şehir ağacı kapanır.
  void toggleCountryCheckbox(String countryCode) {
    _isNearbyMode = false;
    if (_selectedFullCountryCodes.contains(countryCode)) {
      _selectedFullCountryCodes.remove(countryCode);
    } else {
      _selectedFullCountryCodes.add(countryCode);
      _expandedCountryCodes.remove(countryCode);

      for (final city in getCitiesForCountry(countryCode)) {
        _selectedCities.remove(city);
      }
    }
    notifyListeners();
  }

  /// Ülke checkbox'ı işaretli değilse altındaki şehirleri açıp kapatır
  void toggleCountryExpanded(String countryCode) {
    if (_selectedFullCountryCodes.contains(countryCode)) return;
    if (_expandedCountryCodes.contains(countryCode)) {
      _expandedCountryCodes.remove(countryCode);
    } else {
      _expandedCountryCodes.add(countryCode);
    }
    notifyListeners();
  }

  /// Tekil şehir seçimi (Ülke checkbox'ı işaretli değilken çalışır)
  void toggleCityCheckbox(String city) {
    _isNearbyMode = false;
    if (_selectedCities.contains(city)) {
      _selectedCities.remove(city);
    } else {
      _selectedCities.add(city);
    }
    notifyListeners();
  }
}
