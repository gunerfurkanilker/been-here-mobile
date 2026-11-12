import 'package:flutter/foundation.dart';
import '../../../../data/repositories/static_place_discovery_repository.dart';
import '../../../../domain/models/place_discovery_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/filters/geography_tree_filter_mixin.dart';

class PlaceSearchViewModel extends ChangeNotifier
    with GeographyTreeFilterMixin {
  PlaceSearchViewModel({StaticPlaceDiscoveryRepository? repository})
      : _repository = repository ?? StaticPlaceDiscoveryRepository();

  final StaticPlaceDiscoveryRepository _repository;

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

  @override
  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent,
  ) {
    return _repository.getCountriesForContinent(continent);
  }

  @override
  List<String> getCitiesForCountry(String countryCode) {
    return _repository.getCitiesForCountry(countryCode);
  }

  @override
  int countItemsForContinent(ContinentFilter continent) =>
      _repository.countPlacesForContinent(continent);

  @override
  int countItemsForRegion(RouteRegionCatalogItem region) =>
      _repository.countPlacesForRegion(region);

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

  /// "Aradığınız mekanı bulamadınız mı?" kartı hem Yakınımdaki Mekanlar
  /// hem de Konum Bağımsız Genel Arama modlarında listenin sonunda görünür.
  bool get shouldShowNotFoundBannerAtEnd =>
      searchMode == PlaceSearchMode.nearby ||
      searchMode == PlaceSearchMode.globalSearch ||
      placeSearchQuery.trim().isNotEmpty;

  List<UserFavoritePlaceList> get favoriteLists =>
      List<UserFavoritePlaceList>.unmodifiable(_favoriteLists);

  List<PlaceDiscoveryItem> get displayedPlaces {
    if (hasFilterPills) {
      return _repository.getFilteredPlacesByPills(
        activePills: filterPills,
        isNearbyPriority: isNearbyMode,
      );
    }
    return _repository.getFilteredPlaces(
      selectedFullContinents: selectedFullContinents,
      selectedFullCountries: selectedFullCountryCodes,
      selectedCities: selectedCities,
      searchMode: searchMode,
      searchQuery: committedSearchQuery,
    );
  }

  /// Çekmece içindeki "Uygula (X Mekan)" butonunda Anlık Konum açık olsa bile
  /// seçilen ülke/şehir ağacına ait mekan sayısını göstermek için kullanılır.
  int get geographyFilteredPlacesCount {
    if (hasFilterPills) {
      return _repository
          .getFilteredPlacesByPills(
            activePills: filterPills,
            isNearbyPriority: false,
          )
          .length;
    }
    return _repository
        .getFilteredPlaces(
          selectedFullContinents: selectedFullContinents,
          selectedFullCountries: selectedFullCountryCodes,
          selectedCities: selectedCities,
          searchMode: PlaceSearchMode.showcase,
          searchQuery: committedSearchQuery,
        )
        .length;
  }

  List<PublishedRouteFeedItem> getRelatedRoutesForPlace(
    PlaceDiscoveryItem place,
  ) {
    return _repository.getRelatedRoutesForPlace(place);
  }

  List<PlaceDiscoveryItem> getSimilarPlacesForPlace(
    PlaceDiscoveryItem place,
  ) {
    return _repository.getSimilarPlacesForPlace(place);
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

  /// Google Haritalar fallback tetikleyicisi (Min. 3 karakter kuralı)
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
    return _favoriteLists.any((list) => list.containsPlace(placeId));
  }

  List<UserFavoritePlaceList> getListsContainingPlace(String placeId) {
    return _favoriteLists
        .where((list) => list.containsPlace(placeId))
        .toList(growable: false);
  }

  void togglePlaceInList({
    required String listId,
    required String placeId,
  }) {
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

  UserFavoritePlaceList? createNewFavoriteListAndAddPlace({
    required String listTitle,
    required String placeId,
    String iconEmoji = '🚩',
  }) {
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

  @override
  void dispose() {
    disposeSearchDebounce();
    super.dispose();
  }
}
