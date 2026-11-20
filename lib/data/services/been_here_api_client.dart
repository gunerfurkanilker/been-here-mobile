import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Callback signature for dynamically providing the current Bearer token.
typedef AuthTokenProvider = FutureOr<String?> Function();

dynamic _decodeJsonPayload(String rawBody) => jsonDecode(rawBody);

/// Central configuration values for Been Here REST API communication.
class BeenHereApiConfig {
  BeenHereApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'BEEN_HERE_API_URL',
  );

  /// Default Bearer token used in local development (`DEV_MOCK_EXTERNAL_SERVICES=true`).
  /// Override at build time with `--dart-define=BEEN_HERE_AUTH_TOKEN=...`.
  static const String defaultAuthToken = String.fromEnvironment(
    'BEEN_HERE_AUTH_TOKEN',
    defaultValue: 'dev:user-1',
  );

  /// Default HTTP request timeout applied by [BeenHereApiClient].
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Base URL of the NestJS backend (served directly from root without `/api/v1`).
  ///
  /// Uses `--dart-define=BEEN_HERE_API_URL` if defined; otherwise on Flutter Web
  /// derives the host from `Uri.base` (falling back to `http://localhost:3000`
  /// when empty), resolves to `http://10.0.2.2:3000` on Android emulators, and
  /// defaults to `http://localhost:3000` on iOS, macOS, and other platforms.
  static String get baseUrl => resolveBaseUrl(
    configuredBaseUrl: _configuredBaseUrl,
    isWeb: kIsWeb,
    baseUri: kIsWeb ? Uri.base : null,
    targetPlatform: defaultTargetPlatform,
  );

  /// Resolves the backend base URL for the given build-time configuration,
  /// runtime environment, current [baseUri], and [targetPlatform].
  @visibleForTesting
  static String resolveBaseUrl({
    required String configuredBaseUrl,
    required bool isWeb,
    required Uri? baseUri,
    required TargetPlatform targetPlatform,
  }) {
    final trimmed = configuredBaseUrl.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.replaceFirst(RegExp(r'/+$'), '');
    }
    if (isWeb) {
      final host = baseUri?.host.trim() ?? '';
      if (host.isNotEmpty) {
        final rawScheme = baseUri?.scheme.trim() ?? '';
        final scheme = rawScheme.isNotEmpty ? rawScheme : 'http';
        final formattedHost =
            host.contains(':') && !host.startsWith('[') ? '[$host]' : host;
        return '$scheme://$formattedHost:3000';
      }
    }
    if (!isWeb && targetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}

/// Exception thrown when a Been Here API request fails or returns a non-2xx status.
///
/// Mirrors the backend `AllExceptionsFilter` payload:
/// `{ "success": false, "statusCode": number, "timestamp": string, "path": string, "message": string | string[] }`.
class BeenHereApiException implements Exception {
  const BeenHereApiException({
    this.statusCode,
    required this.message,
    this.messages = const <String>[],
    this.path,
    this.timestamp,
    this.cause,
  });

  final int? statusCode;
  final String message;
  final List<String> messages;
  final String? path;
  final String? timestamp;
  final Object? cause;

  /// Parses an HTTP error response from the Been Here backend into [BeenHereApiException].
  factory BeenHereApiException.fromResponse(
    http.Response response, {
    String? requestPath,
  }) {
    final rawText = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    int effectiveStatusCode = response.statusCode;
    String? path = requestPath;
    String? timestamp;
    List<String> extractedMessages = const <String>[];
    String? combinedMessage;

    if (rawText.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawText);
        if (decoded is Map<String, dynamic>) {
          if (decoded['statusCode'] is int) {
            effectiveStatusCode = decoded['statusCode'] as int;
          }
          if (decoded['path'] is String &&
              (decoded['path'] as String).trim().isNotEmpty) {
            path = (decoded['path'] as String).trim();
          }
          if (decoded['timestamp'] is String &&
              (decoded['timestamp'] as String).trim().isNotEmpty) {
            timestamp = (decoded['timestamp'] as String).trim();
          }

          final rawMessage = decoded['message'];
          if (rawMessage is String) {
            final trimmed = rawMessage.trim();
            if (trimmed.isNotEmpty) {
              extractedMessages = List<String>.unmodifiable(<String>[trimmed]);
              combinedMessage = trimmed;
            }
          } else if (rawMessage is Iterable) {
            final normalizedList = rawMessage
                .where((item) => item != null)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false);
            if (normalizedList.isNotEmpty) {
              extractedMessages = List<String>.unmodifiable(normalizedList);
              combinedMessage = normalizedList.join(' • ');
            }
          }

          if (combinedMessage == null && decoded['error'] is String) {
            final errorText = (decoded['error'] as String).trim();
            if (errorText.isNotEmpty) {
              extractedMessages = List<String>.unmodifiable(<String>[errorText]);
              combinedMessage = errorText;
            }
          }
        }
      } on FormatException {
        // Non-JSON error body; fall through to plain-text / status fallback.
        if (!rawText.startsWith('<')) {
          extractedMessages = List<String>.unmodifiable(<String>[rawText]);
          combinedMessage = rawText;
        }
      }
    }

    combinedMessage ??= _defaultMessageForStatus(effectiveStatusCode);

    return BeenHereApiException(
      statusCode: effectiveStatusCode,
      message: combinedMessage,
      messages: extractedMessages,
      path: path,
      timestamp: timestamp,
    );
  }

  static String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek parametreleri gönderildi.';
      case 401:
        return 'Oturum doğrulaması başarısız. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case 404:
        return 'İstenen kayıt bulunamadı.';
      case 409:
        return 'İşlem mevcut kayıtlarla çakışıyor.';
      case 422:
        return 'Gönderilen veriler doğrulanamadı.';
      case 429:
        return 'Çok fazla istek gönderildi. Lütfen kısa süre sonra tekrar deneyin.';
      default:
        if (statusCode >= 500) {
          return 'Sunucu hatası oluştu (HTTP $statusCode). Lütfen tekrar deneyin.';
        }
        return 'Sunucu isteği başarısız oldu (HTTP $statusCode).';
    }
  }

  @override
  String toString() {
    final statusPart = statusCode != null ? '($statusCode)' : '';
    final pathPart = (path != null && path!.isNotEmpty) ? ' [$path]' : '';
    return 'BeenHereApiException$statusPart$pathPart: $message';
  }
}

/// Core HTTP client aligned with Been Here NestJS backend contracts.
///
/// Automatically attaches Bearer authorization when enabled, unwraps
/// `TransformInterceptor` (`{ success: true, data: ... }`) envelopes, and maps
/// non-2xx responses or transport errors to [BeenHereApiException].
class BeenHereApiClient {
  BeenHereApiClient({
    String? baseUrl,
    http.Client? client,
    this.timeout = BeenHereApiConfig.defaultTimeout,
    this.authToken,
    this.authTokenProvider,
    this.defaultHeaders = const <String, String>{},
  }) : baseUrl = _normalizeBaseUrl(baseUrl ?? BeenHereApiConfig.baseUrl),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const int _backgroundDecodeThresholdBytes = 16 * 1024;
  static final RegExp _trailingSlashPattern = RegExp(r'/+$');
  static final RegExp _bearerPrefixPattern = RegExp(
    r'^bearer\s+',
    caseSensitive: false,
  );

  final String baseUrl;
  final Duration timeout;
  final String? authToken;
  final AuthTokenProvider? authTokenProvider;
  final Map<String, String> defaultHeaders;
  final http.Client _client;
  final bool _ownsClient;

  static String _normalizeBaseUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return BeenHereApiConfig.baseUrl;
    }
    return trimmed.replaceFirst(_trailingSlashPattern, '');
  }

  /// Builds a request [Uri] relative to [baseUrl], cleaning empty values and
  /// joining [Iterable] parameters with commas.
  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final rawUri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return rawUri;
    }

    final cleanedQuery = <String, String>{
      if (rawUri.hasQuery) ...rawUri.queryParameters,
    };

    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }

      if (value is Iterable) {
        final joined = value
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join(',');
        if (joined.isNotEmpty) {
          cleanedQuery[entry.key] = joined;
        }
        continue;
      }

      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        cleanedQuery[entry.key] = normalized;
      }
    }

    if (cleanedQuery.isEmpty) {
      return rawUri;
    }
    return rawUri.replace(queryParameters: cleanedQuery);
  }

  /// Executes an HTTP `GET` request and returns the unwrapped response payload.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _request(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
      includeAuth: includeAuth,
    );
  }

  /// Executes an HTTP `POST` request and returns the unwrapped response payload.
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      includeAuth: includeAuth,
    );
  }

  /// Executes an HTTP `PATCH` request and returns the unwrapped response payload.
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      includeAuth: includeAuth,
    );
  }

  /// Executes an HTTP `DELETE` request and returns the unwrapped response payload.
  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _request(
      'DELETE',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      includeAuth: includeAuth,
    );
  }

  /// Decodes a raw JSON object string, unwrapping `TransformInterceptor` if present.
  Map<String, dynamic> decodeJsonMap(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        if (decoded['success'] == true &&
            decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded;
      }
    } on FormatException {
      debugPrint('Invalid JSON format from BeenHere API');
      return <String, dynamic>{};
    }
    debugPrint('Unexpected JSON format from BeenHere API');
    return <String, dynamic>{};
  }

  /// Releases the underlying HTTP client if it was created by this instance.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required bool includeAuth,
  }) async {
    final uri = buildUri(path, queryParameters);
    final encodedBody = _encodeBody(body);
    final resolvedHeaders = await _buildHeaders(
      headers: headers,
      includeAuth: includeAuth,
      hasBody: encodedBody != null,
    );

    final response = await _sendWithTimeout(
      method,
      uri,
      resolvedHeaders,
      encodedBody,
    );

    return _handleResponse(response, uri);
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
    required bool includeAuth,
    required bool hasBody,
  }) async {
    final merged = <String, String>{
      'Accept': 'application/json',
      ...defaultHeaders,
      ...?headers,
    };

    if (hasBody && !_hasHeader(merged, 'content-type')) {
      merged['Content-Type'] = 'application/json; charset=UTF-8';
    }

    if (includeAuth && !_hasHeader(merged, 'authorization')) {
      final token = await _resolveAuthToken();
      if (token != null && token.isNotEmpty) {
        merged['Authorization'] = _formatBearerToken(token);
      }
    }

    return merged;
  }

  bool _hasHeader(Map<String, String> headers, String lowerCaseName) {
    return headers.keys.any((key) => key.toLowerCase() == lowerCaseName);
  }

  Future<String?> _resolveAuthToken() async {
    if (authTokenProvider != null) {
      final provided = (await authTokenProvider!())?.trim();
      if (provided != null && provided.isNotEmpty) {
        return provided;
      }
      final fallback = authToken?.trim();
      return (fallback != null && fallback.isNotEmpty) ? fallback : null;
    }

    final explicitOrDefault =
        (authToken ?? BeenHereApiConfig.defaultAuthToken).trim();
    return explicitOrDefault.isNotEmpty ? explicitOrDefault : null;
  }

  String _formatBearerToken(String token) {
    if (_bearerPrefixPattern.hasMatch(token)) {
      return token;
    }
    return 'Bearer $token';
  }

  Future<http.Response> _sendWithTimeout(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? encodedBody,
  ) async {
    try {
      final Future<http.Response> pendingRequest;
      switch (method) {
        case 'GET':
          pendingRequest = _client.get(uri, headers: headers);
          break;
        case 'POST':
          pendingRequest = _client.post(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;
        case 'PATCH':
          pendingRequest = _client.patch(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;
        case 'DELETE':
          pendingRequest = _client.delete(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;
        default:
          throw ArgumentError.value(method, 'method', 'Unsupported HTTP method');
      }

      return await pendingRequest.timeout(timeout);
    } on TimeoutException catch (error) {
      throw BeenHereApiException(
        message:
            'Sunucu yanıt vermedi (${timeout.inSeconds} sn zaman aşımı).',
        path: uri.path,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw BeenHereApiException(
        message: 'Sunucuya bağlanılamadı: ${error.message}',
        path: uri.path,
        cause: error,
      );
    } on Exception catch (error) {
      if (error is BeenHereApiException) {
        rethrow;
      }
      throw BeenHereApiException(
        message: 'Ağ isteği sırasında beklenmeyen bir hata oluştu.',
        path: uri.path,
        cause: error,
      );
    }
  }

  Future<dynamic> _handleResponse(http.Response response, Uri uri) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BeenHereApiException.fromResponse(
        response,
        requestPath: uri.path,
      );
    }

    if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
      return null;
    }

    final rawText = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (rawText.trim().isEmpty) {
      return null;
    }

    final dynamic decoded;
    try {
      if (response.bodyBytes.lengthInBytes > _backgroundDecodeThresholdBytes) {
        decoded = await compute<String, dynamic>(_decodeJsonPayload, rawText);
      } else {
        decoded = jsonDecode(rawText);
      }
    } on FormatException catch (error) {
      throw BeenHereApiException(
        statusCode: response.statusCode,
        message: 'Sunucudan gelen yanıt ayrıştırılamadı.',
        path: uri.path,
        cause: error,
      );
    }

    if (decoded is Map<String, dynamic> &&
        decoded['success'] == true &&
        decoded.containsKey('data')) {
      return decoded['data'];
    }

    return decoded;
  }
}
