import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/static_home_routes_repository.dart';
import '../../../data/stores/geography_store.dart';
import '../../../domain/models/geography_models.dart';
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

  /// Alt sınıfların konum, arama veya filtre hapı değişikliklerinde uzak veri
  /// kaynağını yeniden sorgulayabilmesi için opsiyonel yaşam döngüsü kancası.
  @protected
  void onSearchAndLocationFiltersChanged() {}

  /// Alt sınıfların çekmece taslak oturumu açılırken ek durumları (ör. seçili kategori)
  /// yakalayabilmesi için opsiyonel yaşam döngüsü kanca metotları.
  @protected
  void captureDrawerSessionExtraState() {}

  @protected
  void restoreDrawerSessionExtraState() {}

  @protected
  bool get hasExtraDrawerChanges => false;

  /// Çekmece oturumu aktifken yalnızca taslak UI'ı günceller; dışarıda hem
  /// dinleyicileri hem de backend/liste yeniden sorgusunu tetikler.
  @protected
  void notifyFilterSelectionChanged() {
    notifyListeners();
    if (!_isInDrawerSession) {
      onSearchAndLocationFiltersChanged();
    }
  }

  /// Alt sınıfların merkezi [GeographyStore] kaynağını bağlayabilmesi için
  /// opsiyonel getter. Bağlı ve yüklü olduğunda DB çoklu dil verisi önceliklenir.
  @protected
  GeographyStore? get geographyStore => null;

  final Set<ContinentFilter> _selectedFullContinents = <ContinentFilter>{};
  final Set<String> _selectedFullCountryCodes = <String>{};
  final Set<String> _selectedCities = <String>{};
  final Set<String> _selectedDistricts = <String>{};
  final Map<String, String> _selectedDistrictLabels = <String, String>{};

  final Set<ContinentFilter> _expandedContinents = <ContinentFilter>{};
  final Set<String> _expandedCountryCodes = <String>{};
  final Set<String> _expandedCities = <String>{};

  /// Hiyerarşik bölge ağacı çekmecesinin en üstündeki akıllı filtre metni
  String _treeSearchQuery = '';

  /// Ülke içi hızlı şehir/ilçe arama metinleri (0 HTTP isteği, yalnızca lokal filtreleme)
  final Map<String, String> _countryCitySearchQueries = <String, String>{};

  /// Çekmece Taslak Oturumu (Draft Session & Snapshot Rollback)
  bool _isInDrawerSession = false;
  final Set<ContinentFilter> _snapshotFullContinents = <ContinentFilter>{};
  final Set<String> _snapshotFullCountryCodes = <String>{};
  final Set<String> _snapshotCities = <String>{};
  final Set<String> _snapshotDistricts = <String>{};
  final Map<String, String> _snapshotDistrictLabels = <String, String>{};
  final List<RouteFeedFilterPill> _snapshotFilterPills =
      <RouteFeedFilterPill>[];
  bool _snapshotIsNearbyMode = false;

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

  /// Seçili şehir için ilçe düğümlerini döndürür (`GeographyStore` yüklüyse DB verisi).
  List<GeographyDistrictNode> getDistrictNodesForCity(
    String countryCode,
    String city,
  ) {
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      return store.getDistrictNodesForCity(countryCode, city);
    }
    return const <GeographyDistrictNode>[];
  }

  /// Seçili coğrafya dili (`tr` / `en`).
  String get geographyLang => geographyStore?.lang ?? 'tr';

  /// DB yüklüyse ilgili şehrin mekan sayısını döndürür.
  int? getCityPlacesCount(String countryCode, String city) {
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      return store.findCity(countryCode, city)?.placesCount;
    }
    return null;
  }

  @override
  Future<void> triggerRemoteGeographySearch(String query) async {
    final store = geographyStore;
    if (store == null || (store.hasLoaded && store.tree != null)) return;
    await store.searchRemote(query, lang: store.lang);
  }

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
  List<RouteContinentCatalogItem> get searchContinentsCatalog {
    final store = geographyStore;
    if (store != null &&
        store.hasLoaded &&
        store.continentsCatalog.isNotEmpty) {
      return store.continentsCatalog;
    }
    return StaticHomeRoutesRepository.continentsCatalog;
  }

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
      if (pill.type == RouteFilterPillType.keyword) {
        _filterPills.removeWhere((p) {
          if (p.type == RouteFilterPillType.keyword) {
            seenIds.remove(p.id);
            return true;
          }
          return false;
        });
      }
      if (seenIds.add(pill.id)) {
        _filterPills.add(pill);
      }
    }
    notifyListeners();
    onSearchAndLocationFiltersChanged();
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
    onSearchAndLocationFiltersChanged();
  }

  /// Hapın sağındaki X ikonuna basıldığında hapı listeden kalıcı olarak kaldırır.
  @override
  void removeFilterPill(String pillId) {
    final before = _filterPills.length;
    _filterPills.removeWhere((p) => p.id == pillId);
    if (_filterPills.length != before) {
      notifyListeners();
      onSearchAndLocationFiltersChanged();
    }
  }

  @override
  void clearAllFilterPills() {
    if (_filterPills.isEmpty) return;
    _filterPills.clear();
    notifyListeners();
    onSearchAndLocationFiltersChanged();
  }

  /// Kıta enum'unun Türkçe görünen adını döndürür.
  static String geographyDisplayNameForContinent(ContinentFilter continent) =>
      GeographyStore.continentDisplayName(continent);

  @override
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      final dbSuggestions = store.buildSearchSuggestions(
        query,
        lang: store.lang,
      );
      if (dbSuggestions.isNotEmpty) {
        return dbSuggestions;
      }
    }

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
      final continentName = geographyDisplayNameForContinent(country.continent);
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
            subtitle: '${geographyDisplayNameForContinent(country.continent)} - Ülke',
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
  static String normalizeTr(String input) => GeographyStore.normalizeTr(input);

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
    onSearchAndLocationFiltersChanged();
  }

  /// Kullanıcı her harfe bastığında API'ye istek atılmaz;
  /// yalnızca en az 3 karakter girildikten sonra 5 saniyelik debounce başlar.
  void onSearchInputChanged(String value) {
    _draftSearchInput = value;
    _searchDebounceTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      final hadCommittedQuery = _committedSearchQuery.isNotEmpty;
      _isWaitingForDebounce = false;
      _committedSearchQuery = '';
      notifyListeners();
      if (hadCommittedQuery) {
        onSearchAndLocationFiltersChanged();
      }
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
    onSearchAndLocationFiltersChanged();
    return true;
  }

  void clearSearchInput() {
    _searchDebounceTimer?.cancel();
    _draftSearchInput = '';
    _committedSearchQuery = '';
    _isWaitingForDebounce = false;
    notifyListeners();
    onSearchAndLocationFiltersChanged();
  }

  @protected
  void disposeSearchDebounce() {
    _searchDebounceTimer?.cancel();
  }

  // --- Çekmece Taslak Oturumu & Snapshot Yönetimi ---

  bool get hasActiveGeographyDrawerSession => _isInDrawerSession;

  void beginGeographyDrawerSession() {
    _snapshotFullContinents
      ..clear()
      ..addAll(_selectedFullContinents);
    _snapshotFullCountryCodes
      ..clear()
      ..addAll(_selectedFullCountryCodes);
    _snapshotCities
      ..clear()
      ..addAll(_selectedCities);
    _snapshotDistricts
      ..clear()
      ..addAll(_selectedDistricts);
    _snapshotDistrictLabels
      ..clear()
      ..addAll(_selectedDistrictLabels);
    _snapshotFilterPills
      ..clear()
      ..addAll(_filterPills);
    _snapshotIsNearbyMode = _isNearbyMode;
    captureDrawerSessionExtraState();
    _isInDrawerSession = true;
  }

  bool get hasPendingGeographyDrawerChanges {
    if (!_isInDrawerSession) return false;
    if (_snapshotIsNearbyMode != _isNearbyMode) return true;
    if (!setEquals(_selectedFullContinents, _snapshotFullContinents)) {
      return true;
    }
    if (!setEquals(_selectedFullCountryCodes, _snapshotFullCountryCodes)) {
      return true;
    }
    if (!setEquals(_selectedCities, _snapshotCities)) return true;
    if (!setEquals(_selectedDistricts, _snapshotDistricts)) return true;
    if (!mapEquals(_selectedDistrictLabels, _snapshotDistrictLabels)) {
      return true;
    }
    if (!_pillListsEqual(_filterPills, _snapshotFilterPills)) return true;
    return hasExtraDrawerChanges;
  }

  void commitGeographyDrawerSelections() {
    if (!_isInDrawerSession) return;
    final changed = hasPendingGeographyDrawerChanges;
    _isInDrawerSession = false;
    _clearDrawerSnapshot();
    _countryCitySearchQueries.clear();
    _treeSearchQuery = '';
    notifyListeners();
    if (changed) {
      onSearchAndLocationFiltersChanged();
    }
  }

  void cancelGeographyDrawerSelections() {
    if (!_isInDrawerSession) return;
    _selectedFullContinents
      ..clear()
      ..addAll(_snapshotFullContinents);
    _selectedFullCountryCodes
      ..clear()
      ..addAll(_snapshotFullCountryCodes);
    _selectedCities
      ..clear()
      ..addAll(_snapshotCities);
    _selectedDistricts
      ..clear()
      ..addAll(_snapshotDistricts);
    _selectedDistrictLabels
      ..clear()
      ..addAll(_snapshotDistrictLabels);
    _filterPills
      ..clear()
      ..addAll(_snapshotFilterPills);
    _isNearbyMode = _snapshotIsNearbyMode;
    restoreDrawerSessionExtraState();
    _isInDrawerSession = false;
    _clearDrawerSnapshot();
    _countryCitySearchQueries.clear();
    _treeSearchQuery = '';
    notifyListeners();
  }

  void _clearDrawerSnapshot() {
    _snapshotFullContinents.clear();
    _snapshotFullCountryCodes.clear();
    _snapshotCities.clear();
    _snapshotDistricts.clear();
    _snapshotDistrictLabels.clear();
    _snapshotFilterPills.clear();
    _snapshotIsNearbyMode = false;
  }

  static bool _pillListsEqual(
    List<RouteFeedFilterPill> a,
    List<RouteFeedFilterPill> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final pa = a[i];
      final pb = b[i];
      if (pa.id != pb.id ||
          pa.type != pb.type ||
          pa.label != pb.label ||
          pa.isEnabled != pb.isEnabled ||
          pa.continent != pb.continent ||
          pa.regionId != pb.regionId ||
          pa.countryCode != pb.countryCode ||
          pa.cityName != pb.cityName ||
          pa.districtName != pb.districtName ||
          pa.keyword != pb.keyword) {
        return false;
      }
    }
    return true;
  }

  // --- Coğrafi Ağaç Getter ve Aksiyonları ---

  String get treeSearchQuery => _treeSearchQuery;

  void updateTreeSearchQuery(String query) {
    _treeSearchQuery = query;
    notifyListeners();
  }

  void clearTreeSearchQuery() {
    if (_treeSearchQuery.isEmpty && _countryCitySearchQueries.isEmpty) return;
    _treeSearchQuery = '';
    _countryCitySearchQueries.clear();
    notifyListeners();
  }

  String getCountryCitySearchQuery(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return '';
    return _countryCitySearchQueries[code] ?? '';
  }

  void updateCountryCitySearchQuery(String countryCode, String query) {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return;
    if (query.isEmpty) {
      if (!_countryCitySearchQueries.containsKey(code)) return;
      _countryCitySearchQueries.remove(code);
    } else {
      if (_countryCitySearchQueries[code] == query) return;
      _countryCitySearchQueries[code] = query;
    }
    notifyListeners();
  }

  void clearCountryCitySearchQuery(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return;
    if (_countryCitySearchQueries.remove(code) != null) {
      notifyListeners();
    }
  }

  List<ContinentFilter> get selectableContinents => ContinentFilter.values
      .where((c) => c != ContinentFilter.global)
      .toList(growable: false);

  bool _continentMatchesTreeQuery(ContinentFilter continent, String q) {
    if (normalizeTr(continent.label).contains(q) ||
        normalizeTr(geographyDisplayNameForContinent(continent)).contains(q)) {
      return true;
    }
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      final node = store.findContinent(continent);
      if (node != null && node.matchesQuery(q, normalizeTr)) {
        return true;
      }
    }
    return false;
  }

  bool _countryMatchesTreeQuery(CountryFilterOption country, String q) {
    if (normalizeTr(country.nameTr).contains(q) ||
        normalizeTr(country.code).contains(q)) {
      return true;
    }
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      final node = store.findCountry(country.code);
      if (node != null && node.matchesQuery(q, normalizeTr)) {
        return true;
      }
    }
    return false;
  }

  String _districtKey(String city, String district) =>
      '${normalizeTr(city)}|${normalizeTr(district)}';

  String _cityExpandKey(String countryCode, String city) =>
      '${countryCode.trim().toUpperCase()}|${normalizeTr(city)}';

  void _removeDistrictsForCity(String city) {
    final prefix = '${normalizeTr(city)}|';
    _selectedDistricts.removeWhere((key) => key.startsWith(prefix));
    _selectedDistrictLabels.removeWhere((key, _) => key.startsWith(prefix));
  }

  void _collapseCity(String countryCode, String city) {
    _expandedCities.remove(_cityExpandKey(countryCode, city));
  }

  void _collapseCityByName(String city) {
    final suffix = '|${normalizeTr(city)}';
    _expandedCities.removeWhere((key) => key.endsWith(suffix));
  }

  int _countSelectedDistrictsForCity(String city) {
    final prefix = '${normalizeTr(city)}|';
    return _selectedDistricts.where((key) => key.startsWith(prefix)).length;
  }

  List<String> _selectedDistrictLabelsForCity(String city) {
    final prefix = '${normalizeTr(city)}|';
    final labels = <String>[];
    for (final key in _selectedDistricts) {
      if (!key.startsWith(prefix)) continue;
      final label = _selectedDistrictLabels[key];
      if (label != null && label.isNotEmpty) {
        labels.add(label);
      } else {
        final idx = key.indexOf('|');
        if (idx != -1 && idx + 1 < key.length) {
          labels.add(key.substring(idx + 1));
        }
      }
    }
    return labels;
  }

  bool _cityMatchesTreeQuery(String countryCode, String city, String q) {
    if (normalizeTr(city).contains(q)) return true;
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      final cityNode = store.findCity(countryCode, city);
      if (cityNode != null && cityNode.matchesQuery(q, normalizeTr)) {
        return true;
      }
    }
    return false;
  }

  bool _anyCityMatchesTreeQuery(String countryCode, String q) {
    final cities = getCitiesForCountry(countryCode);
    for (final city in cities) {
      if (normalizeTr(city).contains(q)) {
        return true;
      }
      if (getDistrictNodesForCity(countryCode, city)
          .any((district) => district.matchesQuery(q, normalizeTr))) {
        return true;
      }
    }
    final store = geographyStore;
    if (store != null && store.hasLoaded) {
      return store.getCityNodesForCountry(countryCode).any(
            (node) =>
                node.matchesQuery(q, normalizeTr) ||
                node.districts
                    .any((district) => district.matchesQuery(q, normalizeTr)),
          );
    }
    return false;
  }

  /// Ağaç içi arama metnine göre eşleşen kıtaları döndürür
  List<ContinentFilter> get filteredContinentsForTree {
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty) {
      return selectableContinents
          .where((continent) => getCountriesForContinent(continent).isNotEmpty)
          .toList(growable: false);
    }

    return selectableContinents.where((continent) {
      if (_continentMatchesTreeQuery(continent, q)) {
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
    if (q.isEmpty || _continentMatchesTreeQuery(continent, q)) {
      return allCountries;
    }

    return allCountries.where((country) {
      if (_countryMatchesTreeQuery(country, q)) {
        return true;
      }
      return _anyCityMatchesTreeQuery(country.code, q);
    }).toList(growable: false);
  }

  List<String> _filterCitiesByNormalizedQuery(
    String countryCode,
    List<String> sourceCities,
    String q,
  ) {
    final store = geographyStore;
    final matchedLocalizedCities = <String>{};
    if (store != null && store.hasLoaded) {
      for (final cityNode in store.getCityNodesForCountry(countryCode)) {
        final cityOrDistrictMatches = cityNode.matchesQuery(q, normalizeTr) ||
            cityNode.districts.any((d) => d.matchesQuery(q, normalizeTr));
        if (cityOrDistrictMatches) {
          final localized = cityNode.localizedName(store.lang);
          if (localized.isNotEmpty) {
            matchedLocalizedCities.add(normalizeTr(localized));
          }
        }
      }
    }

    return sourceCities.where((c) {
      final normC = normalizeTr(c);
      if (normC.contains(q) || matchedLocalizedCities.contains(normC)) {
        return true;
      }
      return getDistrictNodesForCity(countryCode, c)
          .any((d) => d.matchesQuery(q, normalizeTr));
    }).toList();
  }

  /// Ağaç içi arama metnine göre ülkenin altındaki eşleşen şehirleri döndürür
  List<String> getFilteredCitiesForTree(CountryFilterOption country) {
    final allCities = getCitiesForCountry(country.code);
    final q = normalizeTr(_treeSearchQuery);
    List<String> baseCities;
    if (q.isEmpty ||
        _continentMatchesTreeQuery(country.continent, q) ||
        _countryMatchesTreeQuery(country, q)) {
      baseCities = allCities;
    } else {
      final matchingCities =
          _filterCitiesByNormalizedQuery(country.code, allCities, q);
      baseCities = matchingCities.isNotEmpty ? matchingCities : allCities;
    }

    final countryQuery = normalizeTr(getCountryCitySearchQuery(country.code));
    if (countryQuery.isEmpty) {
      return baseCities;
    }
    return _filterCitiesByNormalizedQuery(
      country.code,
      baseCities,
      countryQuery,
    );
  }

  /// Ağaç içi arama metnine göre şehrin altındaki eşleşen ilçeleri döndürür
  List<GeographyDistrictNode> getFilteredDistrictsForTree(
    String countryCode,
    String city,
  ) {
    final allDistricts = getDistrictNodesForCity(countryCode, city);
    if (allDistricts.isEmpty) return const <GeographyDistrictNode>[];

    List<GeographyDistrictNode> result = allDistricts;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty && !_cityMatchesTreeQuery(countryCode, city, q)) {
      var ancestorMatched = false;
      final store = geographyStore;
      if (store != null && store.hasLoaded) {
        final countryNode = store.findCountry(countryCode);
        if (countryNode != null) {
          if (countryNode.matchesQuery(q, normalizeTr)) {
            ancestorMatched = true;
          } else {
            final continentNode =
                store.findContinent(countryNode.continentFilter);
            if ((continentNode != null &&
                    continentNode.matchesQuery(q, normalizeTr)) ||
                normalizeTr(countryNode.continentFilter.label).contains(q)) {
              ancestorMatched = true;
            }
          }
        }
      }
      if (!ancestorMatched) {
        final matchingDistricts = allDistricts
            .where((district) => district.matchesQuery(q, normalizeTr))
            .toList(growable: false);
        if (matchingDistricts.isNotEmpty) {
          result = matchingDistricts;
        }
      }
    }

    final countryQuery = normalizeTr(getCountryCitySearchQuery(countryCode));
    if (countryQuery.isNotEmpty &&
        !_cityMatchesTreeQuery(countryCode, city, countryQuery)) {
      result = result
          .where((district) => district.matchesQuery(countryQuery, normalizeTr))
          .toList(growable: false);
    }

    return result;
  }

  bool get isGlobalSelected =>
      _selectedFullContinents.isEmpty &&
      _selectedFullCountryCodes.isEmpty &&
      _selectedCities.isEmpty &&
      _selectedDistricts.isEmpty;

  Set<ContinentFilter> get selectedFullContinents =>
      Set<ContinentFilter>.unmodifiable(_selectedFullContinents);
  Set<String> get selectedFullCountryCodes =>
      Set<String>.unmodifiable(_selectedFullCountryCodes);
  Set<String> get selectedCities => Set<String>.unmodifiable(_selectedCities);
  Set<String> get selectedDistricts =>
      Set<String>.unmodifiable(_selectedDistricts);

  /// Backend `districts` parametresi için sade seçili ilçe adlarını döndürür.
  Set<String> get selectedDistrictNames {
    final names = <String>{};
    for (final key in _selectedDistricts) {
      final label = _selectedDistrictLabels[key];
      if (label != null && label.trim().isNotEmpty) {
        names.add(label.trim());
      } else {
        final idx = key.indexOf('|');
        if (idx != -1 && idx + 1 < key.length) {
          names.add(key.substring(idx + 1));
        }
      }
    }
    return Set<String>.unmodifiable(names);
  }

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
    if (q.isNotEmpty && _anyCityMatchesTreeQuery(countryCode, q)) {
      return true;
    }
    return _expandedCountryCodes.contains(countryCode);
  }

  bool isCityChecked(String city) => _selectedCities.contains(city);

  bool isCityExpanded(String countryCode, String city) {
    if (isCityChecked(city)) return false;
    final districts = getDistrictNodesForCity(countryCode, city);
    if (districts.isEmpty) return false;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty &&
        districts.any((district) => district.matchesQuery(q, normalizeTr))) {
      return true;
    }
    final countryQuery = normalizeTr(getCountryCitySearchQuery(countryCode));
    if (countryQuery.isNotEmpty &&
        districts.any(
          (district) => district.matchesQuery(countryQuery, normalizeTr),
        )) {
      return true;
    }
    return _expandedCities.contains(_cityExpandKey(countryCode, city));
  }

  void toggleCityExpanded(String countryCode, String city) {
    if (isCityChecked(city)) return;
    if (getDistrictNodesForCity(countryCode, city).isEmpty) return;
    final key = _cityExpandKey(countryCode, city);
    if (_expandedCities.contains(key)) {
      _expandedCities.remove(key);
    } else {
      _expandedCities.add(key);
    }
    notifyListeners();
  }

  bool isDistrictChecked(String city, String district) =>
      _selectedDistricts.contains(_districtKey(city, district));

  void toggleDistrictCheckbox(String city, String district) {
    _isNearbyMode = false;
    final key = _districtKey(city, district);
    if (_selectedDistricts.contains(key)) {
      _selectedDistricts.remove(key);
      _selectedDistrictLabels.remove(key);
    } else {
      _selectedDistricts.add(key);
      _selectedDistrictLabels[key] = district.trim();
    }
    notifyFilterSelectionChanged();
  }

  String? getCityPartialSelectionBadge(String countryCode, String city) {
    if (isCityChecked(city)) return null;
    final count = _countSelectedDistrictsForCity(city);
    if (count > 0) {
      return '$count ilçe seçili';
    }
    return null;
  }

  /// Kıta checkbox'ı işaretli DEĞİLKEN altındaki ülke/şehir/ilçe seçim özetini döndürür
  String? getContinentPartialSelectionBadge(ContinentFilter continent) {
    if (isContinentChecked(continent)) return null;
    final countries = getCountriesForContinent(continent);
    int checkedCountryCount = 0;
    int checkedCityCount = 0;
    int checkedDistrictCount = 0;

    for (final c in countries) {
      if (_selectedFullCountryCodes.contains(c.code)) {
        checkedCountryCount++;
      } else {
        final cities = getCitiesForCountry(c.code);
        for (final city in cities) {
          if (_selectedCities.contains(city)) {
            checkedCityCount++;
          } else {
            checkedDistrictCount += _countSelectedDistrictsForCity(city);
          }
        }
      }
    }

    if (checkedCountryCount > 0 && checkedCityCount > 0) {
      return '$checkedCountryCount ülke • $checkedCityCount şehir';
    } else if (checkedCountryCount > 0) {
      return '$checkedCountryCount ülke seçili';
    } else if (checkedCityCount > 0) {
      return '$checkedCityCount şehir seçili';
    } else if (checkedDistrictCount > 0) {
      return '$checkedDistrictCount ilçe seçili';
    }
    return null;
  }

  /// Ülke checkbox'ı işaretli DEĞİLKEN altındaki şehir/ilçe seçim özetini döndürür
  String? getCountryPartialSelectionBadge(String countryCode) {
    if (isCountryChecked(countryCode)) return null;
    final cities = getCitiesForCountry(countryCode);
    int cityCount = 0;
    int districtCount = 0;
    for (final city in cities) {
      if (_selectedCities.contains(city)) {
        cityCount++;
      } else {
        districtCount += _countSelectedDistrictsForCity(city);
      }
    }
    if (cityCount > 0 && districtCount > 0) {
      return '$cityCount şehir • $districtCount ilçe';
    }
    if (cityCount > 0) {
      return '$cityCount şehir seçili';
    }
    if (districtCount > 0) {
      return '$districtCount ilçe seçili';
    }
    return null;
  }

  /// Seçili kıta, ülke, şehir ve ilçeleri okunaklı hiyerarşik özet metni olarak döndürür.
  /// Örn: "🇪🇺 Avrupa (Tümü)" veya "🇹🇷 Türkiye: Selçuk, Bergama"
  String get geographyFilterButtonTitle {
    if (isGlobalSelected) {
      return 'Global (Tüm Dünya)';
    }
    final parts = <String>[];
    final handledCities = <String>{};
    final handledDistrictKeys = <String>{};

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
          final selectedInCountry = <String>[];
          for (final city in countryCities) {
            if (_selectedCities.contains(city)) {
              handledCities.add(city);
              selectedInCountry.add(city);
            } else {
              final districtLabels = _selectedDistrictLabelsForCity(city);
              if (districtLabels.isNotEmpty) {
                for (final label in districtLabels) {
                  handledDistrictKeys.add(_districtKey(city, label));
                }
                selectedInCountry.addAll(districtLabels);
              }
            }
          }
          if (selectedInCountry.isNotEmpty) {
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

    for (final key in _selectedDistricts) {
      if (!handledDistrictKeys.contains(key)) {
        final label = _selectedDistrictLabels[key];
        if (label != null && label.isNotEmpty) {
          parts.add('📍 $label');
        }
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
        _expandedCountryCodes.isEmpty &&
        _expandedCities.isEmpty) {
      if (hadPills) {
        notifyFilterSelectionChanged();
      }
      return;
    }
    _selectedFullContinents.clear();
    _selectedFullCountryCodes.clear();
    _selectedCities.clear();
    _selectedDistricts.clear();
    _selectedDistrictLabels.clear();
    _expandedContinents.clear();
    _expandedCountryCodes.clear();
    _expandedCities.clear();
    notifyFilterSelectionChanged();
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
          _removeDistrictsForCity(city);
          _collapseCity(country.code, city);
        }
      }
    }
    notifyFilterSelectionChanged();
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
        _removeDistrictsForCity(city);
        _collapseCity(countryCode, city);
      }
    }
    notifyFilterSelectionChanged();
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
      _removeDistrictsForCity(city);
      _collapseCityByName(city);
    }
    notifyFilterSelectionChanged();
  }
}
