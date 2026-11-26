import '../../domain/models/place_discovery_models.dart';
import 'been_here_api_client.dart';

/// Backend `PlacesController` (`/places/*`) ile iletişim kuran HTTP servis katmanı.
///
/// Backend tarafında `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })`
/// aktif olduğu için tüm sorgu ve gövde nesnelerinde yalnızca DTO'larda izin verilen
/// alanlar gönderilir.
class PlacesApiService {
  const PlacesApiService({required this.apiClient});

  final BeenHereApiClient apiClient;

  /// 1) `GET /places/feed`
  Future<PlaceFeedResponse> fetchPlacesFeed({
    int page = 1,
    int limit = 10,
    String? seed,
    String? continent,
    List<String>? continents,
    List<String>? regions,
    String? countryCode,
    List<String>? countryCodes,
    String? city,
    List<String>? cities,
    String? district,
    List<String>? districts,
    String? uiCategory,
    String? vibe,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'limit': limit.clamp(1, 50),
      if (seed != null && seed.trim().isNotEmpty) 'seed': seed.trim(),
      if (continent != null && continent.trim().isNotEmpty)
        'continent': continent.trim(),
      if (continents != null && continents.isNotEmpty) 'continents': continents,
      if (regions != null && regions.isNotEmpty) 'regions': regions,
      if (countryCode != null && countryCode.trim().isNotEmpty)
        'country_code': countryCode.trim(),
      if (countryCodes != null && countryCodes.isNotEmpty)
        'country_codes': countryCodes,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (cities != null && cities.isNotEmpty) 'cities': cities,
      if (district != null && district.trim().isNotEmpty)
        'district': district.trim(),
      if (districts != null && districts.isNotEmpty) 'districts': districts,
      if (uiCategory != null && uiCategory.trim().isNotEmpty)
        'ui_category': uiCategory.trim(),
      if (vibe != null && vibe.trim().isNotEmpty) 'vibe': vibe.trim(),
    };

    final payload = await apiClient.get(
      '/places/feed',
      queryParameters: queryParameters,
    );
    return PlaceFeedResponse.fromJson(_requireMap(payload, '/places/feed'));
  }

  /// 2) `GET /places/search`
  Future<PlaceSearchResponse> searchPlaces({
    String? query,
    String searchMode = 'GLOBAL',
    String lang = 'tr',
    double? lat,
    double? lng,
    int? radius,
    String? continent,
    List<String>? continents,
    List<String>? regions,
    String? city,
    List<String>? cities,
    String? district,
    List<String>? districts,
    String? countryCode,
    List<String>? countryCodes,
    String? uiCategory,
    String? googleType,
    String? vibe,
    int limit = 20,
  }) async {
    final normalizedMode = searchMode == 'NEARBY' ? 'NEARBY' : 'GLOBAL';
    final queryParameters = <String, dynamic>{
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'search_mode': normalizedMode,
      if (lang.trim().isNotEmpty) 'lang': lang.trim(),
      'lat': ?lat,
      'lng': ?lng,
      if (radius != null) 'radius': radius.clamp(100, 100000),
      if (continent != null && continent.trim().isNotEmpty)
        'continent': continent.trim(),
      if (continents != null && continents.isNotEmpty) 'continents': continents,
      if (regions != null && regions.isNotEmpty) 'regions': regions,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (cities != null && cities.isNotEmpty) 'cities': cities,
      if (district != null && district.trim().isNotEmpty)
        'district': district.trim(),
      if (districts != null && districts.isNotEmpty) 'districts': districts,
      if (countryCode != null && countryCode.trim().isNotEmpty)
        'country_code': countryCode.trim(),
      if (countryCodes != null && countryCodes.isNotEmpty)
        'country_codes': countryCodes,
      if (uiCategory != null && uiCategory.trim().isNotEmpty)
        'ui_category': uiCategory.trim(),
      if (googleType != null && googleType.trim().isNotEmpty)
        'google_type': googleType.trim(),
      if (vibe != null && vibe.trim().isNotEmpty) 'vibe': vibe.trim(),
      'limit': limit.clamp(1, 50),
    };

    final payload = await apiClient.get(
      '/places/search',
      queryParameters: queryParameters,
    );
    return PlaceSearchResponse.fromJson(_requireMap(payload, '/places/search'));
  }

  /// 3) `GET /places/:id`
  Future<PlaceDiscoveryItem> fetchPlaceById(String placeId) async {
    final encodedId = Uri.encodeComponent(placeId);
    final payload = await apiClient.get('/places/$encodedId');
    return PlaceDiscoveryItem.fromJson(
      _requireMap(payload, '/places/$encodedId'),
    );
  }

  /// 4) `GET /places/:id/routes`
  Future<PlaceRelatedRoutesResponse> fetchPlaceRelatedRoutes(
    String placeId, {
    int page = 1,
    int limit = 10,
  }) async {
    final encodedId = Uri.encodeComponent(placeId);
    final payload = await apiClient.get(
      '/places/$encodedId/routes',
      queryParameters: <String, dynamic>{
        'page': page < 1 ? 1 : page,
        'limit': limit.clamp(1, 50),
      },
    );
    return PlaceRelatedRoutesResponse.fromJson(
      _requireMap(payload, '/places/$encodedId/routes'),
    );
  }

  /// 5) `GET /places/:id/nearby`
  Future<PlaceNearbyResponse> fetchNearbyPlaces(
    String placeId, {
    int radius = 3000,
    String lang = 'tr',
    int limit = 15,
  }) async {
    final encodedId = Uri.encodeComponent(placeId);
    final payload = await apiClient.get(
      '/places/$encodedId/nearby',
      queryParameters: <String, dynamic>{
        'radius': radius.clamp(500, 50000),
        if (lang.trim().isNotEmpty) 'lang': lang.trim(),
        'limit': limit.clamp(1, 50),
      },
    );
    return PlaceNearbyResponse.fromJson(
      _requireMap(payload, '/places/$encodedId/nearby'),
    );
  }

  /// 6) `POST /places/fetch-google`
  Future<List<PlaceDiscoveryItem>> fetchFromGoogle({
    required String query,
    String searchMode = 'GLOBAL',
    String lang = 'tr',
    double? lat,
    double? lng,
    int? radius,
    String? googleType,
  }) async {
    final normalizedMode = searchMode == 'NEARBY' ? 'NEARBY' : 'GLOBAL';
    final body = <String, dynamic>{
      'query': query.trim(),
      'search_mode': normalizedMode,
      if (lang.trim().isNotEmpty) 'lang': lang.trim(),
      'lat': ?lat,
      'lng': ?lng,
      if (radius != null) 'radius': radius.clamp(100, 50000),
      if (googleType != null && googleType.trim().isNotEmpty)
        'google_type': googleType.trim(),
    };

    final payload = await apiClient.post('/places/fetch-google', body: body);
    if (payload is! List) {
      throw const BeenHereApiException(
        statusCode: 500,
        message: 'Google Haritalar yanıtı beklenen liste formatında değil.',
        path: '/places/fetch-google',
      );
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(PlaceDiscoveryItem.fromJson)
        .toList(growable: false);
  }

  /// 7) `POST /places/:id/vibes`
  Future<Map<String, dynamic>> addCommunityVibes(
    String placeId,
    List<String> vibes,
  ) async {
    final encodedId = Uri.encodeComponent(placeId);
    final cleanedVibes = vibes
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    final payload = await apiClient.post(
      '/places/$encodedId/vibes',
      body: <String, dynamic>{'vibes': cleanedVibes},
    );
    return _requireMap(payload, '/places/$encodedId/vibes');
  }

  /// 8) `POST /places/:id/warnings`
  Future<Map<String, dynamic>> addCommunityWarnings(
    String placeId,
    List<String> warnings,
  ) async {
    final encodedId = Uri.encodeComponent(placeId);
    final cleanedWarnings = warnings
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);

    final payload = await apiClient.post(
      '/places/$encodedId/warnings',
      body: <String, dynamic>{'warnings': cleanedWarnings},
    );
    return _requireMap(payload, '/places/$encodedId/warnings');
  }

  /// 9) `GET /places/lists/me`
  Future<PlaceListsResponse> fetchMyPlaceLists() async {
    final payload = await apiClient.get('/places/lists/me');
    return PlaceListsResponse.fromJson(
      _requireMap(payload, '/places/lists/me'),
    );
  }

  /// 10) `POST /places/lists`
  Future<UserFavoritePlaceList> createPlaceList({
    String? title,
    String? icon,
  }) async {
    final trimmedTitle = title?.trim();
    final trimmedIcon = icon?.trim();
    final body = <String, dynamic>{
      if (trimmedTitle != null && trimmedTitle.isNotEmpty)
        'title': trimmedTitle,
      if (trimmedIcon != null && trimmedIcon.isNotEmpty) 'icon': trimmedIcon,
    };

    final payload = await apiClient.post('/places/lists', body: body);
    return UserFavoritePlaceList.fromJson(
      _requireMap(payload, '/places/lists'),
    );
  }

  /// 11) `GET /places/lists/:listId`
  Future<PlaceListDetailResponse> fetchPlaceListDetails(String listId) async {
    final encodedId = Uri.encodeComponent(listId);
    final payload = await apiClient.get('/places/lists/$encodedId');
    return PlaceListDetailResponse.fromJson(
      _requireMap(payload, '/places/lists/$encodedId'),
    );
  }

  /// 12) `POST /places/lists/:listId/items`
  Future<PlaceListDetailItem> addPlaceToList({
    required String listId,
    required String placeId,
    String? note,
  }) async {
    final encodedListId = Uri.encodeComponent(listId);
    final trimmedNote = note?.trim();
    final body = <String, dynamic>{
      'place_id': placeId,
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
    };

    final payload = await apiClient.post(
      '/places/lists/$encodedListId/items',
      body: body,
    );
    return PlaceListDetailItem.fromJson(
      _requireMap(payload, '/places/lists/$encodedListId/items'),
    );
  }

  /// 13) `DELETE /places/lists/:listId/items/:placeId`
  Future<bool> removePlaceFromList({
    required String listId,
    required String placeId,
  }) async {
    final encodedListId = Uri.encodeComponent(listId);
    final encodedPlaceId = Uri.encodeComponent(placeId);
    final payload = await apiClient.delete(
      '/places/lists/$encodedListId/items/$encodedPlaceId',
    );
    if (payload == null) return true;
    if (payload is Map<String, dynamic> && payload.containsKey('removed')) {
      return payload['removed'] == true;
    }
    return true;
  }

  /// 14) `DELETE /places/lists/:listId`
  Future<bool> deletePlaceList(String listId) async {
    final encodedListId = Uri.encodeComponent(listId);
    final payload = await apiClient.delete('/places/lists/$encodedListId');
    if (payload == null) return true;
    if (payload is Map<String, dynamic> && payload.containsKey('deleted')) {
      return payload['deleted'] == true;
    }
    return true;
  }

  Map<String, dynamic> _requireMap(dynamic payload, String path) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw BeenHereApiException(
      statusCode: 500,
      message: 'Sunucudan beklenmeyen veri formatı alındı.',
      path: path,
    );
  }
}
