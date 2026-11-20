import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/static_place_discovery_repository.dart';
import '../../../../data/stores/geography_store.dart';
import '../../../../data/stores/places_store.dart';
import '../../../../domain/models/place_discovery_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/filters/geography_tree_filter_mixin.dart';

class PlaceSearchViewModel extends ChangeNotifier
    with GeographyTreeFilterMixin {
  PlaceSearchViewModel({
    StaticPlaceDiscoveryRepository? repository,
    PlacesStore? placesStore,
    this._geographyStore,
    bool enableRemoteBackend = false,
  })  : _repository = repository ?? StaticPlaceDiscoveryRepository(),
        _placesStore = placesStore,
        _enableRemoteBackend = enableRemoteBackend && placesStore != null {
    if (_enableRemoteBackend) {
      _placesStore!.addListener(_handleStoreChanged);
    }
    _geographyStore?.addListener(_handleGeographyStoreChanged);
  }

  final StaticPlaceDiscoveryRepository _repository;
  final PlacesStore? _placesStore;
  final GeographyStore? _geographyStore;
  final bool _enableRemoteBackend;

  final List<UserFavoritePlaceList> _favoriteLists = [
    const UserFavoritePlaceList(
      id: 'list-ege-koylari',
      title: 'Ege & Akdeniz Koyları',
      iconEmoji: '🌊',
      placeIds: ['place-tr-amintas'],
    ),
    const UserFavoritePlaceList(
      id: 'list-gurme',
      title: 'Gurme Lezzet Durakları',
      iconEmoji: '🍽️',
      placeIds: ['place-tr-od-urla'],
    ),
    const UserFavoritePlaceList(
      id: 'list-kultur',
      title: 'Kültür & Şehir İkonları',
      iconEmoji: '🏛️',
      placeIds: [],
    ),
  ];

  final List<UserEditableRouteOption> _userEditableRoutes = [
    const UserEditableRouteOption(
      id: 'draft-ege-plan',
      title: 'Sonbahar Ege & Akdeniz Planım',
      routeTypeLabel: 'Taslak Rota',
      isDraft: true,
      placeIds: [],
    ),
    const UserEditableRouteOption(
      id: 'draft-avrupa-tren',
      title: 'Avrupa Kültür & Tren Turu',
      routeTypeLabel: 'Taslak Rota',
      isDraft: true,
      placeIds: [],
    ),
    const UserEditableRouteOption(
      id: 'memory-likya-gunluk',
      title: 'Geçen Yaz Likya & Koylar Günlüğüm',
      routeTypeLabel: 'Anı Rotası',
      isDraft: false,
      placeIds: ['place-tr-amintas'],
    ),
  ];

  bool get _hasLoadedGeography =>
      _geographyStore != null &&
      _geographyStore.hasLoaded &&
      !isUsingOfflineDemoFallback;

  @override
  GeographyStore? get geographyStore =>
      isUsingOfflineDemoFallback ? null : _geographyStore;

  @override
  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent,
  ) {
    if (_hasLoadedGeography) {
      return _geographyStore!.getCountriesForContinent(continent);
    }
    return _repository.getCountriesForContinent(continent);
  }

  @override
  List<String> getCitiesForCountry(String countryCode) {
    if (_hasLoadedGeography) {
      final dbCities = _geographyStore!.getCitiesForCountry(countryCode);
      if (dbCities.isNotEmpty) {
        return dbCities;
      }
    }
    return _repository.getCitiesForCountry(countryCode);
  }

  @override
  int countItemsForContinent(ContinentFilter continent) {
    if (_hasLoadedGeography) {
      return _geographyStore!.countPlacesForContinent(continent);
    }
    return _repository.countPlacesForContinent(continent);
  }

  @override
  int countItemsForRegion(RouteRegionCatalogItem region) {
    if (_hasLoadedGeography) {
      return _geographyStore!.countPlacesForRegion(region.id);
    }
    return _repository.countPlacesForRegion(region);
  }

  @override
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    if (_hasLoadedGeography) {
      final dbSuggestions = _geographyStore!.buildSearchSuggestions(
        query,
        lang: _geographyStore.lang,
      );
      if (dbSuggestions.isNotEmpty) {
        return dbSuggestions;
      }
    }
    return super.buildSearchSuggestions(query);
  }

  @override
  String get itemCountUnitLabel => 'Mekan';

  PlaceSearchMode get searchMode {
    if (isNearbyMode) return PlaceSearchMode.nearby;
    final hasEnabledKeywordPill = filterPills.any(
      (p) => p.isEnabled && p.type == RouteFilterPillType.keyword,
    );
    if (committedSearchQuery.trim().isNotEmpty || hasEnabledKeywordPill) {
      return PlaceSearchMode.globalSearch;
    }
    return PlaceSearchMode.showcase;
  }

  String get placeSearchQuery {
    if (committedSearchQuery.trim().isNotEmpty) {
      return committedSearchQuery;
    }
    final enabledKeywords = filterPills
        .where((p) => p.isEnabled && p.type == RouteFilterPillType.keyword)
        .map((p) => (p.keyword ?? p.label).trim())
        .where((k) => k.isNotEmpty);
    return enabledKeywords.join(' ');
  }

  /// Canlı backend modunun yapılandırılıp yapılandırılmadığı
  bool get isLiveBackendConfigured => _enableRemoteBackend;

  /// Sunucu erişilemediğinde kullanıcının örnek verilerle devam edip etmediği
  bool get isUsingOfflineDemoFallback =>
      _enableRemoteBackend && (_placesStore?.usingOfflineDemoFallback ?? false);

  /// Ekranın şu anda canlı backend verisiyle beslenip beslenmediği
  bool get isUsingRemoteData =>
      _enableRemoteBackend && !isUsingOfflineDemoFallback;

  PlacesStore? get placesStore => _placesStore;
  String? _selectedUiCategory;
  String? _snapshotUiCategory;
  String? get selectedUiCategory => _selectedUiCategory;

  @override
  void captureDrawerSessionExtraState() {
    _snapshotUiCategory = _selectedUiCategory;
  }

  @override
  void restoreDrawerSessionExtraState() {
    _selectedUiCategory = _snapshotUiCategory;
  }

  @override
  bool get hasExtraDrawerChanges =>
      _selectedUiCategory != _snapshotUiCategory;

  /// UI kategori filtresini günceller; aktif olan kategori tekrar seçilirse
  /// 'Tümü' (`null`) moduna döner.
  Future<void> setUiCategory(String? category) async {
    final trimmed = category?.trim();
    final normalized =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed.toUpperCase();
    final nextCategory =
        normalized != null && _selectedUiCategory == normalized
            ? null
            : normalized;
    if (nextCategory == _selectedUiCategory) return;

    _selectedUiCategory = nextCategory;
    notifyListeners();
    if (_enableRemoteBackend && _placesStore != null) {
      await _applyFiltersToStore();
    }
  }

  @override
  void resetToGlobal() {
    final hadUiCategory = _selectedUiCategory != null;
    _selectedUiCategory = null;
    var triggeredReload = false;
    void trackNotify() {
      triggeredReload = true;
    }

    addListener(trackNotify);
    try {
      super.resetToGlobal();
    } finally {
      removeListener(trackNotify);
    }

    if (hadUiCategory && !triggeredReload) {
      notifyFilterSelectionChanged();
    }
  }

  bool get isLoading => isUsingRemoteData ? (_placesStore?.isLoading ?? false) : false;
  bool get isLoadingMore =>
      isUsingRemoteData ? (_placesStore?.isLoadingMore ?? false) : false;
  bool get isMutating =>
      isUsingRemoteData ? (_placesStore?.isMutating ?? false) : false;
  bool get hasMoreFeed =>
      isUsingRemoteData ? (_placesStore?.hasMoreFeed ?? false) : false;
  String? get errorMessage =>
      isUsingRemoteData ? _placesStore?.errorMessage : null;
  String? get mutationErrorMessage =>
      isUsingRemoteData ? _placesStore?.mutationErrorMessage : null;
  PlaceListsQuota? get listsQuota =>
      isUsingRemoteData ? _placesStore?.listsQuota : null;
  String get suggestedNextListTitle => isUsingRemoteData
      ? (_placesStore?.suggestedNextListTitle ?? 'Favori Liste 1')
      : 'Favori Liste ${_favoriteLists.length + 1}';
  bool get canFetchFromGoogle => isUsingRemoteData
      ? (_placesStore?.canFetchFromGoogle ?? false)
      : placeSearchQuery.trim().length >= 3;
  String get googleFetchPrompt => isUsingRemoteData
      ? (_placesStore?.googleFetchPrompt ??
          "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara")
      : "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara";

  /// Google Haritalar fallback araması için aktif metin veya konum filtresi
  /// üzerinden türetilen efektif arama sorgusu.
  String get effectiveGoogleFallbackQuery {
    final draft = draftSearchInput.trim();
    if (draft.isNotEmpty) {
      return draft;
    }

    final committed = placeSearchQuery.trim();
    if (committed.isNotEmpty) {
      return committed;
    }

    final hasEnabledPills = filterPills.any((p) => p.isEnabled);
    if (hasEnabledPills ||
        selectedDistrictNames.isNotEmpty ||
        selectedCities.isNotEmpty ||
        selectedFullCountryCodes.isNotEmpty) {
      final enabledLocationLabels = <String>[];
      if (hasEnabledPills) {
        for (final pill in filterPills) {
          if (!pill.isEnabled) continue;
          final label = pill.label.trim();
          if (label.isNotEmpty) {
            enabledLocationLabels.add(label);
          }
        }
      } else {
        for (final district in selectedDistrictNames) {
          final trimmed = district.trim();
          if (trimmed.isNotEmpty) {
            enabledLocationLabels.add(trimmed);
          }
        }
        for (final city in selectedCities) {
          final trimmed = city.trim();
          if (trimmed.isNotEmpty) {
            enabledLocationLabels.add(trimmed);
          }
        }
        for (final code in selectedFullCountryCodes) {
          final resolved = _resolveCountryDisplayName(code);
          if (resolved.isNotEmpty) {
            enabledLocationLabels.add(resolved);
          }
        }
        for (final continent in selectedFullContinents) {
          if (continent != ContinentFilter.global) {
            enabledLocationLabels.add(_continentDisplayName(continent));
          }
        }
      }

      if (enabledLocationLabels.isNotEmpty) {
        return '${enabledLocationLabels.join(' ')} gezilecek yerler';
      }
    }

    if (isUsingRemoteData && displayedPlaces.isEmpty) {
      return 'Popüler Turistik Mekanlar';
    }

    return '';
  }

  String _resolveCountryDisplayName(String countryCode) {
    final normalized = countryCode.trim().toUpperCase();
    if (normalized.isEmpty) return '';
    for (final continent in selectableContinents) {
      for (final country in getCountriesForContinent(continent)) {
        if (country.code.toUpperCase() == normalized) {
          return country.nameTr;
        }
      }
    }
    return normalized;
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

  /// "Aradığınız mekanı bulamadınız mı?" kartı hem Yakınımdaki Mekanlar,
  /// hem Konum Bağımsız Genel Arama modlarında, hem de canlı backend modunda
  /// aktif filtre/boş sonuç durumlarında listenin sonunda görünür.
  bool get shouldShowNotFoundBannerAtEnd =>
      searchMode == PlaceSearchMode.nearby ||
      searchMode == PlaceSearchMode.globalSearch ||
      placeSearchQuery.trim().isNotEmpty ||
      (isUsingRemoteData &&
          ((_placesStore?.canFetchFromGoogle ?? false) ||
              hasFilterPills ||
              selectedDistrictNames.isNotEmpty ||
              selectedCities.isNotEmpty ||
              selectedFullCountryCodes.isNotEmpty ||
              displayedPlaces.isEmpty));

  List<UserFavoritePlaceList> get favoriteLists => isUsingRemoteData
      ? _placesStore!.favoriteLists
      : List<UserFavoritePlaceList>.unmodifiable(_favoriteLists);

  List<PlaceDiscoveryItem> get displayedPlaces {
    if (isUsingRemoteData) {
      return _placesStore!.activePlaces;
    }
    final basePlaces = hasFilterPills
        ? _repository.getFilteredPlacesByPills(
            activePills: filterPills,
            isNearbyPriority: isNearbyMode,
          )
        : _repository.getFilteredPlaces(
            selectedFullContinents: selectedFullContinents,
            selectedFullCountries: selectedFullCountryCodes,
            selectedCities: selectedCities,
            searchMode: searchMode,
            searchQuery: committedSearchQuery,
          );
    if (_selectedUiCategory == null) {
      return basePlaces;
    }
    return basePlaces
        .where((p) => _matchesUiCategory(p.uiCategory, _selectedUiCategory!))
        .toList(growable: false);
  }

  /// Çekmece içindeki "Uygula (X Mekan)" butonunda Anlık Konum açık olsa bile
  /// seçilen ülke/şehir ağacına ait mekan sayısını göstermek için kullanılır.
  int get geographyFilteredPlacesCount {
    if (isUsingRemoteData && (_placesStore?.hasCompletedInitialLoad ?? false)) {
      if (hasActiveGeographyDrawerSession &&
          hasPendingGeographyDrawerChanges &&
          _hasLoadedGeography &&
          _selectedUiCategory == null &&
          committedSearchQuery.trim().isEmpty &&
          filterPills.every((p) => !p.isEnabled)) {
        return _estimateDraftPlacesCountFromGeographyStore();
      }
      return _placesStore!.activeTotalCount;
    }
    final basePlaces = hasFilterPills
        ? _repository.getFilteredPlacesByPills(
            activePills: filterPills,
            isNearbyPriority: false,
          )
        : _repository.getFilteredPlaces(
            selectedFullContinents: selectedFullContinents,
            selectedFullCountries: selectedFullCountryCodes,
            selectedCities: selectedCities,
            searchMode: PlaceSearchMode.showcase,
            searchQuery: committedSearchQuery,
          );
    if (_selectedUiCategory == null) {
      return basePlaces.length;
    }
    return basePlaces
        .where((p) => _matchesUiCategory(p.uiCategory, _selectedUiCategory!))
        .length;
  }

  int _estimateDraftPlacesCountFromGeographyStore() {
    final store = _geographyStore;
    if (store == null) {
      return _placesStore?.activeTotalCount ?? 0;
    }
    if (isGlobalSelected) {
      return store.tree?.globalOption?.placesCount ??
          _placesStore?.activeTotalCount ??
          0;
    }

    var total = 0;
    for (final continent in selectedFullContinents) {
      if (continent == ContinentFilter.global) continue;
      total += store.findContinent(continent)?.placesCount ?? 0;
    }
    for (final code in selectedFullCountryCodes) {
      total += store.findCountry(code)?.placesCount ?? 0;
    }
    for (final city in selectedCities) {
      total += store.findCity('', city)?.placesCount ?? 0;
    }
    for (final key in selectedDistricts) {
      total += _placesCountForDistrictKey(store, key);
    }
    return total;
  }

  static int _placesCountForDistrictKey(GeographyStore store, String key) {
    final idx = key.indexOf('|');
    if (idx <= 0 || idx + 1 >= key.length) return 0;
    final cityKey = key.substring(0, idx);
    final districtKey = key.substring(idx + 1);
    final cityNode = store.findCity('', cityKey);
    if (cityNode == null) return 0;
    for (final district in cityNode.districts) {
      if (GeographyStore.normalizeTr(district.name) == districtKey ||
          GeographyStore.normalizeTr(district.defaultName) == districtKey ||
          GeographyStore.normalizeTr(district.slug) == districtKey ||
          district.nameTranslations.values.any(
            (val) => GeographyStore.normalizeTr(val) == districtKey,
          )) {
        return district.placesCount;
      }
    }
    return 0;
  }

  static bool _matchesUiCategory(String itemCategory, String selectedCategory) {
    final a = itemCategory.trim().toUpperCase();
    final b = selectedCategory.trim().toUpperCase();
    if (a == b) return true;
    const stayAliases = <String>{'STAY', 'ACCOMMODATION'};
    return stayAliases.contains(a) && stayAliases.contains(b);
  }

  List<PublishedRouteFeedItem> getRelatedRoutesForPlace(
    PlaceDiscoveryItem place,
  ) {
    if (isUsingRemoteData) {
      return _placesStore!.relatedRoutesByPlaceId[place.id]?.items ??
          const <PublishedRouteFeedItem>[];
    }
    return _repository.getRelatedRoutesForPlace(place);
  }

  bool isRelatedRoutesLoading(String placeId) =>
      isUsingRemoteData && (_placesStore?.isRelatedRoutesLoading(placeId) ?? false);

  bool hasLoadedRelatedRoutes(String placeId) => isUsingRemoteData
      ? (_placesStore?.relatedRoutesByPlaceId.containsKey(placeId) ?? false)
      : true;

  List<PlaceDiscoveryItem> getSimilarPlacesForPlace(
    PlaceDiscoveryItem place,
  ) {
    if (isUsingRemoteData) {
      return _placesStore!.nearbyPlacesByPlaceId[place.id]?.items ??
          const <PlaceDiscoveryItem>[];
    }
    return _repository.getSimilarPlacesForPlace(place);
  }

  bool isNearbyPlacesLoading(String placeId) =>
      isUsingRemoteData && (_placesStore?.isNearbyLoading(placeId) ?? false);

  bool hasLoadedNearbyPlaces(String placeId) => isUsingRemoteData
      ? (_placesStore?.nearbyPlacesByPlaceId.containsKey(placeId) ?? false)
      : true;

  PlaceDiscoveryItem? getPlaceDetails(String placeId) =>
      isUsingRemoteData ? _placesStore?.placeDetailsById[placeId] : null;

  bool isPlaceDetailLoading(String placeId) =>
      isUsingRemoteData && (_placesStore?.isPlaceDetailLoading(placeId) ?? false);

  PlaceListDetailResponse? getListDetails(String listId) =>
      isUsingRemoteData ? _placesStore?.listDetailsById[listId] : null;

  bool isListDetailLoading(String listId) =>
      isUsingRemoteData && (_placesStore?.isListDetailLoading(listId) ?? false);

  @override
  void onSearchAndLocationFiltersChanged() {
    if (!isUsingRemoteData) return;
    unawaited(_applyFiltersToStore());
  }

  /// İlk açılışta vitrini ve favori listelerini uzak sunucudan yükler.
  Future<void> initializePlaces() async {
    if (!_enableRemoteBackend || _placesStore == null) return;
    await _placesStore.loadInitial();
  }

  /// Aktif görünümü (filtre/arama varsa arama sonuçlarını, yoksa vitrini) yeniler.
  Future<void> refreshPlaces() async {
    if (!_enableRemoteBackend || _placesStore == null) return;
    final hasAnyActiveQueryOrFilter = isNearbyMode ||
        placeSearchQuery.trim().isNotEmpty ||
        hasFilterPills ||
        selectedFullContinents.isNotEmpty ||
        selectedFullCountryCodes.isNotEmpty ||
        selectedCities.isNotEmpty ||
        selectedDistrictNames.isNotEmpty ||
        (_selectedUiCategory?.isNotEmpty ?? false);

    if (hasAnyActiveQueryOrFilter) {
      await Future.wait<void>(<Future<void>>[
        _applyFiltersToStore(),
        _placesStore.loadMyPlaceLists(),
      ]);
      return;
    }
    await _placesStore.loadInitial();
  }

  Future<void> loadMoreFeed() async {
    if (!isUsingRemoteData) return;
    await _placesStore!.loadNextFeedPage();
  }

  void enableOfflineDemoFallback() {
    _placesStore?.enableOfflineDemoFallback();
  }

  Future<PlaceDiscoveryItem?> loadPlaceDetails(String placeId) async {
    if (!isUsingRemoteData) {
      for (final p in displayedPlaces) {
        if (p.id == placeId) return p;
      }
      return null;
    }
    return _placesStore!.loadPlaceDetails(placeId);
  }

  Future<void> loadRelatedRoutes(String placeId, {int page = 1}) async {
    if (!isUsingRemoteData) return;
    await _placesStore!.loadRelatedRoutes(placeId, page: page);
  }

  Future<void> loadNearbyPlaces(String placeId) async {
    if (!isUsingRemoteData) return;
    await _placesStore!.loadNearbyPlaces(placeId);
  }

  Future<PlaceDiscoveryItem?> voteVibes(
    String placeId,
    List<String> vibes,
  ) async {
    if (!isUsingRemoteData) return null;
    return _placesStore!.voteVibes(placeId, vibes);
  }

  Future<PlaceDiscoveryItem?> reportWarnings(
    String placeId,
    List<String> warnings,
  ) async {
    if (!isUsingRemoteData) return null;
    return _placesStore!.reportWarnings(placeId, warnings);
  }

  Future<void> loadMyPlaceLists() async {
    if (!isUsingRemoteData) return;
    await _placesStore!.loadMyPlaceLists();
  }

  Future<PlaceListDetailResponse?> loadPlaceListDetails(String listId) async {
    if (!isUsingRemoteData) return null;
    return _placesStore!.loadPlaceListDetails(listId);
  }

  Future<void> _applyFiltersToStore() {
    return _placesStore!.applyDiscoveryFilters(
      selectedFullContinents: selectedFullContinents,
      selectedFullCountryCodes: selectedFullCountryCodes,
      selectedCities: selectedCities,
      selectedDistricts: selectedDistrictNames,
      filterPills: filterPills,
      isNearbyMode: isNearbyMode,
      committedQuery: committedSearchQuery,
      uiCategory: _selectedUiCategory,
      lang: geographyLang,
    );
  }

  void _handleStoreChanged() {
    notifyListeners();
  }

  void _handleGeographyStoreChanged() {
    notifyListeners();
  }

  List<UserEditableRouteOption> get userEditableRoutes =>
      List<UserEditableRouteOption>.unmodifiable(_userEditableRoutes);

  List<UserEditableRouteOption> getUserRoutesContainingPlace(String placeId) {
    return _userEditableRoutes
        .where((r) => r.containsPlace(placeId))
        .toList(growable: false);
  }

  void togglePlaceInUserRoute({
    required String routeId,
    required String placeId,
  }) {
    final index = _userEditableRoutes.indexWhere((r) => r.id == routeId);
    if (index == -1) return;

    final currentRoute = _userEditableRoutes[index];
    final updatedPlaceIds = List<String>.from(currentRoute.placeIds);
    if (updatedPlaceIds.contains(placeId)) {
      updatedPlaceIds.remove(placeId);
    } else {
      updatedPlaceIds.add(placeId);
    }

    _userEditableRoutes[index] =
        currentRoute.copyWith(placeIds: updatedPlaceIds);
    notifyListeners();
  }

  /// Google Haritalar fallback tetikleyicisi (Min. 3 karakter kuralı - Asenkron Canlı Mod)
  Future<List<PlaceDiscoveryItem>> fetchFromGoogleMapsFallbackAsync({
    String? customQuery,
  }) async {
    final overrideQuery = customQuery?.trim() ?? '';
    final candidate = overrideQuery.isNotEmpty
        ? overrideQuery
        : effectiveGoogleFallbackQuery;

    if (isUsingRemoteData) {
      final fetched = await _placesStore!.fetchFromGoogleFallback(
        query: candidate,
        searchMode: isNearbyMode ? 'NEARBY' : 'GLOBAL',
      );
      if (fetched.isNotEmpty && _geographyStore != null) {
        unawaited(_geographyStore.refresh(lang: _geographyStore.lang));
      }
      return fetched;
    }

    final created = fetchFromGoogleMapsFallback();
    return created != null ? <PlaceDiscoveryItem>[created] : const <PlaceDiscoveryItem>[];
  }

  /// Google Haritalar fallback tetikleyicisi (Min. 3 karakter kuralı - Statik Senkron)
  PlaceDiscoveryItem? fetchFromGoogleMapsFallback() {
    final candidate = placeSearchQuery.trim().isNotEmpty
        ? placeSearchQuery.trim()
        : draftSearchInput.trim();
    final effectiveQuery =
        candidate.length >= 3 ? candidate : 'Gizli Kanyon Seyir Terası';
    final pillContinent = filterPills
        .where((p) => p.isEnabled && p.continent != null)
        .map((p) => p.continent!)
        .firstOrNull;
    final activeContinent = selectedFullContinents.isNotEmpty
        ? selectedFullContinents.first
        : (pillContinent ?? ContinentFilter.europe);
    final created = _repository.createPlaceFromGoogleFallback(
      query: effectiveQuery,
      activeContinent: activeContinent,
    );
    notifyListeners();
    return created;
  }

  // --- Sahibinden.com Tarzı Özel Liste (Flag) Yönetimi ---

  bool isPlaceFlaggedInAnyList(String placeId) {
    return favoriteLists.any((list) => list.containsPlace(placeId));
  }

  List<UserFavoritePlaceList> getListsContainingPlace(String placeId) {
    return favoriteLists
        .where((list) => list.containsPlace(placeId))
        .toList(growable: false);
  }

  Future<bool> togglePlaceInListAsync({
    required String listId,
    required String placeId,
    String? note,
  }) async {
    if (isUsingRemoteData) {
      return _placesStore!.togglePlaceInList(
        listId: listId,
        placeId: placeId,
        note: note,
      );
    }
    togglePlaceInList(listId: listId, placeId: placeId);
    return true;
  }

  void togglePlaceInList({
    required String listId,
    required String placeId,
  }) {
    if (isUsingRemoteData) {
      unawaited(
        _placesStore!.togglePlaceInList(listId: listId, placeId: placeId),
      );
      return;
    }

    final index = _favoriteLists.indexWhere((l) => l.id == listId);
    if (index == -1) return;

    final currentList = _favoriteLists[index];
    final updatedPlaceIds = List<String>.from(currentList.placeIds);
    if (updatedPlaceIds.contains(placeId)) {
      updatedPlaceIds.remove(placeId);
    } else {
      updatedPlaceIds.add(placeId);
    }

    _favoriteLists[index] = currentList.copyWith(placeIds: updatedPlaceIds);
    notifyListeners();
  }

  Future<UserFavoritePlaceList?> createNewFavoriteListAndAddPlaceAsync({
    String? listTitle,
    required String placeId,
    String iconEmoji = '🚩',
    String? note,
  }) async {
    if (isUsingRemoteData) {
      return _placesStore!.createFavoriteListAndAddPlace(
        title: listTitle,
        iconEmoji: iconEmoji,
        initialPlaceId: placeId,
        note: note,
      );
    }
    return createNewFavoriteListAndAddPlace(
      listTitle: (listTitle?.trim().isNotEmpty ?? false)
          ? listTitle!.trim()
          : suggestedNextListTitle,
      placeId: placeId,
      iconEmoji: iconEmoji,
    );
  }

  UserFavoritePlaceList? createNewFavoriteListAndAddPlace({
    required String listTitle,
    required String placeId,
    String iconEmoji = '🚩',
  }) {
    if (isUsingRemoteData) {
      unawaited(
        _placesStore!.createFavoriteListAndAddPlace(
          title: listTitle,
          iconEmoji: iconEmoji,
          initialPlaceId: placeId,
        ),
      );
      return null;
    }

    final cleanTitle = listTitle.trim();
    if (cleanTitle.isEmpty) return null;

    final newList = UserFavoritePlaceList(
      id: 'list-${DateTime.now().millisecondsSinceEpoch}',
      title: cleanTitle,
      iconEmoji: iconEmoji,
      placeIds: [placeId],
    );
    _favoriteLists.insert(0, newList);
    notifyListeners();
    return newList;
  }

  Future<bool> deleteFavoriteListAsync(String listId) async {
    if (isUsingRemoteData) {
      return _placesStore!.deleteFavoriteList(listId);
    }
    final before = _favoriteLists.length;
    _favoriteLists.removeWhere((list) => list.id == listId);
    if (_favoriteLists.length != before) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (_enableRemoteBackend) {
      _placesStore?.removeListener(_handleStoreChanged);
    }
    _geographyStore?.removeListener(_handleGeographyStoreChanged);
    disposeSearchDebounce();
    super.dispose();
  }
}
