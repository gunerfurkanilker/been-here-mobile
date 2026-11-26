import 'package:flutter/foundation.dart';

import '../../domain/models/place_discovery_models.dart';
import '../../domain/models/route_feed_models.dart';
import '../services/been_here_api_client.dart';
import '../services/places_api_service.dart';

/// Backend `places` modülünün durumunu ve tüm API mutasyonlarını yöneten
/// Vuex-tarzı reaktif Store katmanı.
class PlacesStore extends ChangeNotifier {
  PlacesStore({
    required this.apiService,
    this.feedPageSize = 10,
  });

  /// Varsayılan Konak / İzmir koordinatları (Yakınımdaki Mekanlar modu)
  static const double defaultNearbyLat = 38.4192;
  static const double defaultNearbyLng = 27.1287;

  final PlacesApiService apiService;
  final int feedPageSize;

  List<PlaceDiscoveryItem> _feedItems = const <PlaceDiscoveryItem>[];
  List<PlaceDiscoveryItem> _searchItems = const <PlaceDiscoveryItem>[];
  int _feedPage = 1;
  bool _hasMoreFeed = false;
  String? _feedSeed;
  bool _isSearchResultMode = false;
  bool _canFetchFromGoogle = false;
  String _googleFetchPrompt =
      "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara";

  List<UserFavoritePlaceList> _favoriteLists = const <UserFavoritePlaceList>[];
  PlaceListsQuota? _listsQuota;
  String _suggestedNextListTitle = 'Favori Liste 1';

  final Map<String, PlaceListDetailResponse> _listDetailsById =
      <String, PlaceListDetailResponse>{};
  final Map<String, PlaceDiscoveryItem> _placeDetailsById =
      <String, PlaceDiscoveryItem>{};
  final Map<String, PlaceRelatedRoutesResponse> _relatedRoutesByPlaceId =
      <String, PlaceRelatedRoutesResponse>{};
  final Map<String, PlaceNearbyResponse> _nearbyPlacesByPlaceId =
      <String, PlaceNearbyResponse>{};

  final Set<String> _loadingRelatedRoutesPlaceIds = <String>{};
  final Set<String> _loadingNearbyPlaceIds = <String>{};
  final Set<String> _loadingPlaceDetailIds = <String>{};
  final Set<String> _loadingListDetailIds = <String>{};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isMutating = false;
  String? _errorMessage;
  String? _mutationErrorMessage;
  bool _usingOfflineDemoFallback = false;
  bool _hasCompletedInitialLoad = false;

  // Aktif feed geo ve kategori filtrelerini infinite scroll sayfalama sırasında korur
  List<String> _activeFeedContinents = const <String>[];
  List<String> _activeFeedRegions = const <String>[];
  List<String> _activeFeedCountryCodes = const <String>[];
  List<String> _activeFeedCities = const <String>[];
  List<String> _activeFeedDistricts = const <String>[];
  String? _activeFeedUiCategory;
  String? _activeFeedVibe;
  int _feedTotalCount = 0;
  int _searchTotalCount = 0;

  int _activeFilterRequestId = 0;

  // --- Getters ---
  List<PlaceDiscoveryItem> get feedItems => _feedItems;
  List<PlaceDiscoveryItem> get searchItems => _searchItems;
  List<PlaceDiscoveryItem> get activePlaces =>
      _isSearchResultMode ? _searchItems : _feedItems;
  int get activeTotalCount =>
      _isSearchResultMode ? _searchTotalCount : _feedTotalCount;

  int get feedPage => _feedPage;
  bool get hasMoreFeed => _hasMoreFeed;
  String? get feedSeed => _feedSeed;
  bool get isSearchResultMode => _isSearchResultMode;
  bool get canFetchFromGoogle => _canFetchFromGoogle;
  String get googleFetchPrompt => _googleFetchPrompt;

  List<UserFavoritePlaceList> get favoriteLists => _favoriteLists;
  PlaceListsQuota? get listsQuota => _listsQuota;
  String get suggestedNextListTitle => _suggestedNextListTitle;

  Map<String, PlaceListDetailResponse> get listDetailsById =>
      Map<String, PlaceListDetailResponse>.unmodifiable(_listDetailsById);
  Map<String, PlaceDiscoveryItem> get placeDetailsById =>
      Map<String, PlaceDiscoveryItem>.unmodifiable(_placeDetailsById);
  Map<String, PlaceRelatedRoutesResponse> get relatedRoutesByPlaceId =>
      Map<String, PlaceRelatedRoutesResponse>.unmodifiable(
        _relatedRoutesByPlaceId,
      );
  Map<String, PlaceNearbyResponse> get nearbyPlacesByPlaceId =>
      Map<String, PlaceNearbyResponse>.unmodifiable(_nearbyPlacesByPlaceId);

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  String? get mutationErrorMessage => _mutationErrorMessage;
  bool get usingOfflineDemoFallback => _usingOfflineDemoFallback;
  bool get hasCompletedInitialLoad => _hasCompletedInitialLoad;

  bool isRelatedRoutesLoading(String placeId) =>
      _loadingRelatedRoutesPlaceIds.contains(placeId);
  bool isNearbyLoading(String placeId) =>
      _loadingNearbyPlaceIds.contains(placeId);
  bool isPlaceDetailLoading(String placeId) =>
      _loadingPlaceDetailIds.contains(placeId);
  bool isListDetailLoading(String listId) =>
      _loadingListDetailIds.contains(listId);

  // --- Actions ---

  /// İlk açılışta veya yenilemede vitrin akışı (`GET /places/feed`) ile
  /// kullanıcı favori listelerini (`GET /places/lists/me`) paralel yükler.
  Future<void> loadInitial() async {
    _usingOfflineDemoFallback = false;
    _errorMessage = null;
    _mutationErrorMessage = null;
    _isLoading = true;
    _isSearchResultMode = false;
    _canFetchFromGoogle = false;
    _activeFeedContinents = const <String>[];
    _activeFeedRegions = const <String>[];
    _activeFeedCountryCodes = const <String>[];
    _activeFeedCities = const <String>[];
    _activeFeedDistricts = const <String>[];
    _activeFeedUiCategory = null;
    _activeFeedVibe = null;
    _activeFilterRequestId++;
    final requestId = _activeFilterRequestId;
    notifyListeners();

    try {
      final feedFuture = apiService.fetchPlacesFeed(
        page: 1,
        limit: feedPageSize,
        seed: _feedSeed,
      );

      final listsFuture = _fetchMyListsSilentlyOnUnauthorized();

      final results = await Future.wait<Object?>(<Future<Object?>>[
        feedFuture,
        listsFuture,
      ]);

      if (requestId != _activeFilterRequestId) return;

      final feedResponse = results[0]! as PlaceFeedResponse;
      _feedPage = feedResponse.page;
      _hasMoreFeed = feedResponse.hasMore;
      if (feedResponse.seed.isNotEmpty) {
        _feedSeed = feedResponse.seed;
      }
      _feedItems = _applyFavoriteListMembership(feedResponse.items);
      _feedTotalCount = feedResponse.totalCount;
      _cachePlaces(_feedItems);
      _hasCompletedInitialLoad = true;
    } catch (error) {
      if (requestId != _activeFilterRequestId) return;
      _errorMessage = _formatErrorMessage(error);
    } finally {
      if (requestId == _activeFilterRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Vitrin (Feed) modunda liste sonuna gelindiğinde sonraki sayfayı yükler.
  Future<void> loadNextFeedPage() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMoreFeed ||
        _isSearchResultMode ||
        _usingOfflineDemoFallback) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _feedPage + 1;
      final feedResponse = await apiService.fetchPlacesFeed(
        page: nextPage,
        limit: feedPageSize,
        seed: _feedSeed,
        continent: _activeFeedContinents.length == 1
            ? _activeFeedContinents.first
            : null,
        continents:
            _activeFeedContinents.isNotEmpty ? _activeFeedContinents : null,
        regions: _activeFeedRegions.isNotEmpty ? _activeFeedRegions : null,
        countryCode: _activeFeedCountryCodes.length == 1
            ? _activeFeedCountryCodes.first
            : null,
        countryCodes: _activeFeedCountryCodes.isNotEmpty
            ? _activeFeedCountryCodes
            : null,
        city: _activeFeedCities.length == 1 ? _activeFeedCities.first : null,
        cities: _activeFeedCities.isNotEmpty ? _activeFeedCities : null,
        district: _activeFeedDistricts.length == 1
            ? _activeFeedDistricts.first
            : null,
        districts:
            _activeFeedDistricts.isNotEmpty ? _activeFeedDistricts : null,
        uiCategory: _activeFeedUiCategory,
        vibe: _activeFeedVibe,
      );

      final incoming = _applyFavoriteListMembership(feedResponse.items);
      _cachePlaces(incoming);

      final merged = List<PlaceDiscoveryItem>.from(_feedItems);
      final existingIds = merged.map((p) => p.id).toSet();
      for (final item in incoming) {
        if (existingIds.add(item.id)) {
          merged.add(item);
        }
      }

      _feedItems = List<PlaceDiscoveryItem>.unmodifiable(merged);
      _feedPage = feedResponse.page;
      _hasMoreFeed = feedResponse.hasMore;
      _feedTotalCount = feedResponse.totalCount;
      if (feedResponse.seed.isNotEmpty) {
        _feedSeed = feedResponse.seed;
      }
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Coğrafya ağaç seçimleri, `RouteFeedFilterPill` listesi, `isNearbyMode` ve
  /// arama metnine göre `GET /places/search` veya `GET /places/feed` çalıştırır.
  Future<void> applyDiscoveryFilters({
    Set<ContinentFilter> selectedFullContinents = const <ContinentFilter>{},
    Set<String> selectedFullCountryCodes = const <String>{},
    Set<String> selectedCities = const <String>{},
    Set<String> selectedDistricts = const <String>{},
    List<RouteFeedFilterPill> filterPills = const <RouteFeedFilterPill>[],
    bool isNearbyMode = false,
    String committedQuery = '',
    double? lat,
    double? lng,
    int radius = 5000,
    String? uiCategory,
    String? vibe,
    String lang = 'tr',
  }) async {
    _usingOfflineDemoFallback = false;
    _errorMessage = null;
    _mutationErrorMessage = null;
    _isLoading = true;
    final requestId = ++_activeFilterRequestId;
    notifyListeners();

    final continentSet = <String>{
      for (final continent in selectedFullContinents)
        if (continent != ContinentFilter.global) continent.code,
    };
    final regionSet = <String>{};
    final countrySet = <String>{
      for (final code in selectedFullCountryCodes)
        if (code.trim().isNotEmpty) code.trim().toUpperCase(),
    };
    final citySet = <String>{
      for (final city in selectedCities)
        if (city.trim().isNotEmpty) city.trim(),
    };
    final districtSet = <String>{
      for (final district in selectedDistricts)
        if (district.trim().isNotEmpty) district.trim(),
    };
    final keywordTokens = <String>[];

    for (final pill in filterPills) {
      if (!pill.isEnabled) continue;
      switch (pill.type) {
        case RouteFilterPillType.continent:
          final code = pill.continent?.code;
          if (code != null &&
              code.isNotEmpty &&
              code != ContinentFilter.global.code) {
            continentSet.add(code);
          }
          break;
        case RouteFilterPillType.region:
          final regionId = pill.regionId?.trim();
          if (regionId != null && regionId.isNotEmpty) {
            regionSet.add(regionId);
          }
          break;
        case RouteFilterPillType.country:
          final code = pill.countryCode?.trim().toUpperCase();
          if (code != null && code.isNotEmpty) {
            countrySet.add(code);
          }
          break;
        case RouteFilterPillType.city:
          final cityName = pill.cityName?.trim();
          if (cityName != null && cityName.isNotEmpty) {
            citySet.add(cityName);
          }
          break;
        case RouteFilterPillType.district:
          final districtName = pill.districtName?.trim();
          if (districtName != null && districtName.isNotEmpty) {
            districtSet.add(districtName);
          }
          final cityName = pill.cityName?.trim();
          if (cityName != null && cityName.isNotEmpty) {
            citySet.add(cityName);
          }
          break;
        case RouteFilterPillType.keyword:
          final keyword = (pill.keyword ?? pill.label).trim();
          if (keyword.isNotEmpty) {
            keywordTokens.add(keyword);
          }
          break;
      }
    }

    final trimmedQuery = committedQuery.trim();
    final effectiveQuery = trimmedQuery.isNotEmpty
        ? trimmedQuery
        : keywordTokens.join(' ').trim();

    final normalizedUiCategory = uiCategory?.trim();
    final effectiveUiCategory =
        (normalizedUiCategory != null && normalizedUiCategory.isNotEmpty)
            ? normalizedUiCategory
            : null;
    final normalizedVibe = vibe?.trim();
    final effectiveVibe =
        (normalizedVibe != null && normalizedVibe.isNotEmpty)
            ? normalizedVibe
            : null;

    final continents = continentSet.toList(growable: false);
    final regions = regionSet.toList(growable: false);
    final countryCodes = countrySet.toList(growable: false);
    final cities = citySet.toList(growable: false);
    final districts = districtSet.toList(growable: false);

    final shouldUseSearchEndpoint = isNearbyMode || effectiveQuery.isNotEmpty;

    try {
      if (shouldUseSearchEndpoint) {
        final effectiveLat = isNearbyMode ? (lat ?? defaultNearbyLat) : lat;
        final effectiveLng = isNearbyMode ? (lng ?? defaultNearbyLng) : lng;

        final searchResponse = await apiService.searchPlaces(
          query: effectiveQuery.isNotEmpty ? effectiveQuery : null,
          searchMode: isNearbyMode ? 'NEARBY' : 'GLOBAL',
          lang: lang,
          lat: effectiveLat,
          lng: effectiveLng,
          radius: isNearbyMode ? radius : null,
          continent: continents.length == 1 ? continents.first : null,
          continents: continents.isNotEmpty ? continents : null,
          regions: regions.isNotEmpty ? regions : null,
          countryCode: countryCodes.length == 1 ? countryCodes.first : null,
          countryCodes: countryCodes.isNotEmpty ? countryCodes : null,
          city: cities.length == 1 ? cities.first : null,
          cities: cities.isNotEmpty ? cities : null,
          district: districts.length == 1 ? districts.first : null,
          districts: districts.isNotEmpty ? districts : null,
          uiCategory: effectiveUiCategory,
          vibe: effectiveVibe,
          limit: 20,
        );

        if (requestId != _activeFilterRequestId) return;

        _isSearchResultMode = true;
        _searchItems = _applyFavoriteListMembership(searchResponse.items);
        _searchTotalCount = searchResponse.totalCount;
        _canFetchFromGoogle = searchResponse.canFetchFromGoogle;
        _googleFetchPrompt = searchResponse.googleFetchPrompt;
        _hasMoreFeed = false;
        _cachePlaces(_searchItems);
        _hasCompletedInitialLoad = true;
      } else {
        _activeFeedContinents = continents;
        _activeFeedRegions = regions;
        _activeFeedCountryCodes = countryCodes;
        _activeFeedCities = cities;
        _activeFeedDistricts = districts;
        _activeFeedUiCategory = effectiveUiCategory;
        _activeFeedVibe = effectiveVibe;

        final feedResponse = await apiService.fetchPlacesFeed(
          page: 1,
          limit: feedPageSize,
          seed: _feedSeed,
          continent: continents.length == 1 ? continents.first : null,
          continents: continents.isNotEmpty ? continents : null,
          regions: regions.isNotEmpty ? regions : null,
          countryCode: countryCodes.length == 1 ? countryCodes.first : null,
          countryCodes: countryCodes.isNotEmpty ? countryCodes : null,
          city: cities.length == 1 ? cities.first : null,
          cities: cities.isNotEmpty ? cities : null,
          district: districts.length == 1 ? districts.first : null,
          districts: districts.isNotEmpty ? districts : null,
          uiCategory: effectiveUiCategory,
          vibe: effectiveVibe,
        );

        if (requestId != _activeFilterRequestId) return;

        _isSearchResultMode = false;
        _canFetchFromGoogle = false;
        _feedPage = feedResponse.page;
        _hasMoreFeed = feedResponse.hasMore;
        _feedTotalCount = feedResponse.totalCount;
        if (feedResponse.seed.isNotEmpty) {
          _feedSeed = feedResponse.seed;
        }
        _feedItems = _applyFavoriteListMembership(feedResponse.items);
        _cachePlaces(_feedItems);
        _hasCompletedInitialLoad = true;
      }
    } catch (error) {
      if (requestId != _activeFilterRequestId) return;
      _errorMessage = _formatErrorMessage(error);
    } finally {
      if (requestId == _activeFilterRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// `GET /places/:id` ile mekan detayını ve topluluk uyarılarını yükler.
  Future<PlaceDiscoveryItem?> loadPlaceDetails(String placeId) async {
    _loadingPlaceDetailIds.add(placeId);
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await apiService.fetchPlaceById(placeId);
      final existing = _findCachedPlace(placeId);
      final synced = _syncSinglePlaceFlags(
        fetched.distanceKmFromUser <= 0 &&
                existing != null &&
                existing.distanceKmFromUser > 0
            ? fetched.copyWith(distanceKmFromUser: existing.distanceKmFromUser)
            : fetched,
      );
      _upsertPlaceAcrossState(synced);
      return synced;
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
      return null;
    } finally {
      _loadingPlaceDetailIds.remove(placeId);
      notifyListeners();
    }
  }

  /// `GET /places/:id/routes` ile bu mekanın geçtiği yayınlanmış rotaları yükler.
  Future<PlaceRelatedRoutesResponse?> loadRelatedRoutes(
    String placeId, {
    int page = 1,
    int limit = 10,
  }) async {
    _loadingRelatedRoutesPlaceIds.add(placeId);
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.fetchPlaceRelatedRoutes(
        placeId,
        page: page,
        limit: limit,
      );

      final existing = _relatedRoutesByPlaceId[placeId];
      if (page > 1 && existing != null) {
        final mergedItems = List<PublishedRouteFeedItem>.from(existing.items);
        final seenIds = mergedItems.map((r) => r.id).toSet();
        for (final route in response.items) {
          if (seenIds.add(route.id)) {
            mergedItems.add(route);
          }
        }
        _relatedRoutesByPlaceId[placeId] = PlaceRelatedRoutesResponse(
          placeId: response.placeId,
          page: response.page,
          limit: response.limit,
          hasMore: response.hasMore,
          items: List<PublishedRouteFeedItem>.unmodifiable(mergedItems),
          count: mergedItems.length,
        );
      } else {
        _relatedRoutesByPlaceId[placeId] = response;
      }
      return _relatedRoutesByPlaceId[placeId];
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
      return null;
    } finally {
      _loadingRelatedRoutesPlaceIds.remove(placeId);
      notifyListeners();
    }
  }

  /// `GET /places/:id/nearby` ile benzer kategorideki yakın mekanları yükler.
  Future<PlaceNearbyResponse?> loadNearbyPlaces(
    String placeId, {
    int radius = 3000,
    String lang = 'tr',
    int limit = 15,
  }) async {
    _loadingNearbyPlaceIds.add(placeId);
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.fetchNearbyPlaces(
        placeId,
        radius: radius,
        lang: lang,
        limit: limit,
      );
      final flaggedItems = _applyFavoriteListMembership(response.items);
      _cachePlaces(flaggedItems);

      final normalizedResponse = PlaceNearbyResponse(
        basePlaceId: response.basePlaceId,
        uiCategory: response.uiCategory,
        radiusMeters: response.radiusMeters,
        items: flaggedItems,
        count: flaggedItems.length,
        canFetchFromGoogle: response.canFetchFromGoogle,
      );
      _nearbyPlacesByPlaceId[placeId] = normalizedResponse;
      return normalizedResponse;
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
      return null;
    } finally {
      _loadingNearbyPlaceIds.remove(placeId);
      notifyListeners();
    }
  }

  /// `POST /places/fetch-google` ile Google Haritalar üzerinden yeni mekan(lar) çeker.
  Future<List<PlaceDiscoveryItem>> fetchFromGoogleFallback({
    required String query,
    String searchMode = 'GLOBAL',
    String lang = 'tr',
    double? lat,
    double? lng,
    int? radius,
    String? googleType,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      _mutationErrorMessage =
          'Google Haritalar araması için lütfen en az 3 karakterli bir mekan adı girin.';
      _errorMessage = _mutationErrorMessage;
      notifyListeners();
      return const <PlaceDiscoveryItem>[];
    }

    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedMode = searchMode == 'NEARBY' ? 'NEARBY' : 'GLOBAL';
      final effectiveLat =
          normalizedMode == 'NEARBY' ? (lat ?? defaultNearbyLat) : lat;
      final effectiveLng =
          normalizedMode == 'NEARBY' ? (lng ?? defaultNearbyLng) : lng;

      final fetched = await apiService.fetchFromGoogle(
        query: trimmed,
        searchMode: normalizedMode,
        lang: lang,
        lat: effectiveLat,
        lng: effectiveLng,
        radius: radius,
        googleType: googleType,
      );

      final marked = _applyFavoriteListMembership(
        fetched
            .map((p) => p.copyWith(isFromGoogleFallback: true))
            .toList(growable: false),
      );
      _cachePlaces(marked);

      if (marked.isNotEmpty) {
        _searchItems = _prependUnique(_searchItems, marked);
        _feedItems = _prependUnique(_feedItems, marked);
      }
      return marked;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return const <PlaceDiscoveryItem>[];
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// `POST /places/:id/vibes` ile mekan vibe etiketlerine oy verir.
  Future<PlaceDiscoveryItem?> voteVibes(
    String placeId,
    List<String> vibes,
  ) async {
    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawPlaceJson = await apiService.addCommunityVibes(placeId, vibes);
      final existing = _findCachedPlace(placeId);
      final updated = existing != null
          ? existing.mergeRawPlaceJson(rawPlaceJson)
          : PlaceDiscoveryItem.fromJson(rawPlaceJson);
      final synced = _syncSinglePlaceFlags(updated);
      _upsertPlaceAcrossState(synced);
      return synced;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// `POST /places/:id/warnings` ile mekana topluluk saha uyarısı bildirir.
  Future<PlaceDiscoveryItem?> reportWarnings(
    String placeId,
    List<String> warnings,
  ) async {
    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawPlaceJson =
          await apiService.addCommunityWarnings(placeId, warnings);
      final existing = _findCachedPlace(placeId);
      final updated = existing != null
          ? existing.mergeRawPlaceJson(rawPlaceJson)
          : PlaceDiscoveryItem.fromJson(rawPlaceJson);
      final synced = _syncSinglePlaceFlags(updated);
      _upsertPlaceAcrossState(synced);
      return synced;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// `GET /places/lists/me` ile kullanıcının favori mekan listelerini yükler.
  Future<void> loadMyPlaceLists() async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.fetchMyPlaceLists();
      _favoriteLists = response.items;
      _listsQuota = response.quota;
      _suggestedNextListTitle = response.suggestedNextTitle;
      _resyncAllPlacesFlagMembership();
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
    } finally {
      notifyListeners();
    }
  }

  /// `GET /places/lists/:listId` ile seçili listenin içindeki mekanları yükler.
  Future<PlaceListDetailResponse?> loadPlaceListDetails(String listId) async {
    _loadingListDetailIds.add(listId);
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await apiService.fetchPlaceListDetails(listId);
      _listDetailsById[listId] = detail;
      final places = detail.items
          .map((item) => item.place)
          .whereType<PlaceDiscoveryItem>()
          .toList(growable: false);
      if (places.isNotEmpty) {
        _cachePlaces(_applyFavoriteListMembership(places));
      }
      return detail;
    } catch (error) {
      _errorMessage = _formatErrorMessage(error);
      return null;
    } finally {
      _loadingListDetailIds.remove(listId);
      notifyListeners();
    }
  }

  /// `POST /places/lists` ile yeni favori listesi oluşturur ve istenirse
  /// ilk mekanı `POST /places/lists/:listId/items` ile içine ekler.
  Future<UserFavoritePlaceList?> createFavoriteListAndAddPlace({
    String? title,
    String iconEmoji = '🚩',
    String? initialPlaceId,
    String? note,
  }) async {
    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await apiService.createPlaceList(
        title: title,
        icon: iconEmoji,
      );

      var finalCreated = created;
      if (initialPlaceId != null && initialPlaceId.trim().isNotEmpty) {
        try {
          await apiService.addPlaceToList(
            listId: created.id,
            placeId: initialPlaceId,
            note: note,
          );
          final updatedIds = List<String>.unmodifiable(<String>[
            ...created.placeIds.where((id) => id != initialPlaceId),
            initialPlaceId,
          ]);
          finalCreated = created.copyWith(
            placeIds: updatedIds,
            itemCount: updatedIds.length,
          );
        } catch (addError) {
          final msg = _formatErrorMessage(addError);
          _mutationErrorMessage = msg;
          _errorMessage = msg;
        }
      }

      _favoriteLists = List<UserFavoritePlaceList>.unmodifiable(
        <UserFavoritePlaceList>[..._favoriteLists, finalCreated],
      );
      _suggestedNextListTitle = 'Favori Liste ${_favoriteLists.length + 1}';
      _resyncAllPlacesFlagMembership();
      return finalCreated;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Mekanın seçili favori listedeki üyeliğini değiştirir (ekle / çıkar).
  Future<bool> togglePlaceInList({
    required String listId,
    required String placeId,
    String? note,
  }) async {
    final listIndex = _favoriteLists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) return false;

    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetList = _favoriteLists[listIndex];
      final alreadyInList = targetList.containsPlace(placeId);

      if (alreadyInList) {
        await apiService.removePlaceFromList(
          listId: listId,
          placeId: placeId,
        );
        final updatedPlaceIds = targetList.placeIds
            .where((id) => id != placeId)
            .toList(growable: false);
        final updatedList = targetList.copyWith(
          placeIds: updatedPlaceIds,
          itemCount: updatedPlaceIds.length,
        );
        final nextLists = List<UserFavoritePlaceList>.from(_favoriteLists);
        nextLists[listIndex] = updatedList;
        _favoriteLists = List<UserFavoritePlaceList>.unmodifiable(nextLists);
      } else {
        await apiService.addPlaceToList(
          listId: listId,
          placeId: placeId,
          note: note,
        );
        final updatedPlaceIds = List<String>.unmodifiable(
          <String>[...targetList.placeIds, placeId],
        );
        final updatedList = targetList.copyWith(
          placeIds: updatedPlaceIds,
          itemCount: updatedPlaceIds.length,
        );
        final nextLists = List<UserFavoritePlaceList>.from(_favoriteLists);
        nextLists[listIndex] = updatedList;
        _favoriteLists = List<UserFavoritePlaceList>.unmodifiable(nextLists);
      }

      _listDetailsById.remove(listId);
      _resyncAllPlacesFlagMembership();
      return true;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// `DELETE /places/lists/:listId` ile favori listesini siler.
  Future<bool> deleteFavoriteList(String listId) async {
    _isMutating = true;
    _mutationErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiService.deletePlaceList(listId);
      _favoriteLists = _favoriteLists
          .where((list) => list.id != listId)
          .toList(growable: false);
      _listDetailsById.remove(listId);
      _suggestedNextListTitle = 'Favori Liste ${_favoriteLists.length + 1}';
      _resyncAllPlacesFlagMembership();
      return true;
    } catch (error) {
      final msg = _formatErrorMessage(error);
      _mutationErrorMessage = msg;
      _errorMessage = msg;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Sunucuya ulaşılamadığında kullanıcının örnek verilerle devam edebilmesi için
  /// çevrimdışı demo modunu etkinleştirir.
  void enableOfflineDemoFallback() {
    _usingOfflineDemoFallback = true;
    _errorMessage = null;
    _mutationErrorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _mutationErrorMessage = null;
    notifyListeners();
  }

  // --- Private Helpers ---

  Future<void> _fetchMyListsSilentlyOnUnauthorized() async {
    try {
      final response = await apiService.fetchMyPlaceLists();
      _favoriteLists = response.items;
      _listsQuota = response.quota;
      _suggestedNextListTitle = response.suggestedNextTitle;
    } on BeenHereApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return;
      }
      rethrow;
    }
  }

  List<PlaceDiscoveryItem> _applyFavoriteListMembership(
    List<PlaceDiscoveryItem> items,
  ) {
    if (items.isEmpty) return items;
    return items.map(_syncSinglePlaceFlags).toList(growable: false);
  }

  PlaceDiscoveryItem _syncSinglePlaceFlags(PlaceDiscoveryItem place) {
    if (_favoriteLists.isEmpty) {
      return place;
    }
    final listIds = _favoriteLists
        .where((list) => list.containsPlace(place.id))
        .map((list) => list.id)
        .toList(growable: false);
    final hasAnyList = listIds.isNotEmpty;
    if (place.isFlagged == hasAnyList &&
        _listsEqual(place.flaggedInListIds, listIds)) {
      return place;
    }
    return place.copyWith(
      isFlagged: hasAnyList,
      flaggedInListIds: listIds,
    );
  }

  void _resyncAllPlacesFlagMembership() {
    if (_feedItems.isNotEmpty) {
      _feedItems = _feedItems.map(_syncFromFavoriteListsStrict).toList(
            growable: false,
          );
    }
    if (_searchItems.isNotEmpty) {
      _searchItems = _searchItems.map(_syncFromFavoriteListsStrict).toList(
            growable: false,
          );
    }
    for (final key in _placeDetailsById.keys.toList(growable: false)) {
      _placeDetailsById[key] = _syncFromFavoriteListsStrict(
        _placeDetailsById[key]!,
      );
    }
    for (final entry in _nearbyPlacesByPlaceId.entries.toList(growable: false)) {
      final updatedItems = entry.value.items
          .map(_syncFromFavoriteListsStrict)
          .toList(growable: false);
      _nearbyPlacesByPlaceId[entry.key] = PlaceNearbyResponse(
        basePlaceId: entry.value.basePlaceId,
        uiCategory: entry.value.uiCategory,
        radiusMeters: entry.value.radiusMeters,
        items: updatedItems,
        count: updatedItems.length,
        canFetchFromGoogle: entry.value.canFetchFromGoogle,
      );
    }
  }

  PlaceDiscoveryItem _syncFromFavoriteListsStrict(PlaceDiscoveryItem place) {
    final listIds = _favoriteLists
        .where((list) => list.containsPlace(place.id))
        .map((list) => list.id)
        .toList(growable: false);
    return place.copyWith(
      isFlagged: listIds.isNotEmpty,
      flaggedInListIds: listIds,
    );
  }

  void _cachePlaces(List<PlaceDiscoveryItem> places) {
    for (final place in places) {
      if (place.id.isNotEmpty) {
        _placeDetailsById[place.id] = place;
      }
    }
  }

  PlaceDiscoveryItem? _findCachedPlace(String placeId) {
    final fromMap = _placeDetailsById[placeId];
    if (fromMap != null) return fromMap;
    for (final item in _searchItems) {
      if (item.id == placeId) return item;
    }
    for (final item in _feedItems) {
      if (item.id == placeId) return item;
    }
    return null;
  }

  void _upsertPlaceAcrossState(PlaceDiscoveryItem updated) {
    _placeDetailsById[updated.id] = updated;

    if (_feedItems.isNotEmpty) {
      _feedItems = _feedItems
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    }
    if (_searchItems.isNotEmpty) {
      _searchItems = _searchItems
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    }
    for (final entry in _nearbyPlacesByPlaceId.entries.toList(growable: false)) {
      var changed = false;
      final updatedNearby = entry.value.items.map((item) {
        if (item.id == updated.id) {
          changed = true;
          return updated;
        }
        return item;
      }).toList(growable: false);
      if (changed) {
        _nearbyPlacesByPlaceId[entry.key] = PlaceNearbyResponse(
          basePlaceId: entry.value.basePlaceId,
          uiCategory: entry.value.uiCategory,
          radiusMeters: entry.value.radiusMeters,
          items: updatedNearby,
          count: updatedNearby.length,
          canFetchFromGoogle: entry.value.canFetchFromGoogle,
        );
      }
    }
  }

  List<PlaceDiscoveryItem> _prependUnique(
    List<PlaceDiscoveryItem> existing,
    List<PlaceDiscoveryItem> incoming,
  ) {
    final incomingIds = incoming.map((p) => p.id).toSet();
    final remaining =
        existing.where((item) => !incomingIds.contains(item.id));
    return List<PlaceDiscoveryItem>.unmodifiable(
      <PlaceDiscoveryItem>[...incoming, ...remaining],
    );
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _formatErrorMessage(Object error) {
    if (error is BeenHereApiException) {
      return error.message;
    }
    return 'Mekan verileri yüklenirken beklenmeyen bir hata oluştu.';
  }
}
