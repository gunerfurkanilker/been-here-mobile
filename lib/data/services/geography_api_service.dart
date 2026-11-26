import '../../domain/models/geography_models.dart';
import 'been_here_api_client.dart';

/// Backend `GeographyController` (`/geography/*`) ile iletişim kuran HTTP servis katmanı.
class GeographyApiService {
  const GeographyApiService({required this.apiClient});

  final BeenHereApiClient apiClient;

  /// `GET /geography/tree`
  ///
  /// Kıta, alt bölge, ülke ve şehir hiyerarşisini (`name_translations` dahil)
  /// ve popüler önerileri döndürür.
  Future<GeographyTreeResponse> fetchGeographyTree({
    String lang = 'tr',
    String? query,
    String scope = 'all',
  }) async {
    final trimmedLang = lang.trim();
    final trimmedQuery = query?.trim();
    final trimmedScope = scope.trim();

    final queryParameters = <String, dynamic>{
      if (trimmedLang.isNotEmpty) 'lang': trimmedLang,
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) 'q': trimmedQuery,
      if (trimmedScope.isNotEmpty) 'scope': trimmedScope,
    };

    final payload = await apiClient.get(
      '/geography/tree',
      queryParameters: queryParameters,
    );
    return GeographyTreeResponse.fromJson(
      _requireMap(payload, '/geography/tree'),
    );
  }

  /// `GET /geography/search`
  ///
  /// Çoklu dil destekli coğrafya araması yapar (kıta, bölge, ülke, şehir).
  Future<List<GeographySearchResultItem>> searchGeography({
    required String query,
    String lang = 'tr',
    int limit = 30,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const <GeographySearchResultItem>[];
    }

    final trimmedLang = lang.trim();
    final queryParameters = <String, dynamic>{
      'q': trimmedQuery,
      if (trimmedLang.isNotEmpty) 'lang': trimmedLang,
      'limit': limit.clamp(1, 100),
    };

    final payload = await apiClient.get(
      '/geography/search',
      queryParameters: queryParameters,
    );

    final List<dynamic> rawResults;
    if (payload is List) {
      rawResults = payload;
    } else {
      final map = _requireMap(payload, '/geography/search');
      final results = map['results'];
      rawResults = results is List ? results : const <dynamic>[];
    }

    return rawResults
        .whereType<Map>()
        .map(
          (item) => GeographySearchResultItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  /// `GET /geography/exchange-rates`
  ///
  /// DB'deki güncel USD bazlı döviz kurlarını döndürür.
  Future<List<GeographyExchangeRate>> fetchExchangeRates() async {
    final payload = await apiClient.get('/geography/exchange-rates');

    final List<dynamic> rawRates;
    if (payload is List) {
      rawRates = payload;
    } else {
      final map = _requireMap(payload, '/geography/exchange-rates');
      final rates = map['rates'];
      rawRates = rates is List ? rates : const <dynamic>[];
    }

    return rawRates
        .whereType<Map>()
        .map(
          (item) => GeographyExchangeRate.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((rate) => rate.code.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> _requireMap(dynamic payload, String path) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw BeenHereApiException(
      statusCode: 500,
      message: 'Sunucudan beklenmeyen veri formatı alındı.',
      path: path,
    );
  }
}
