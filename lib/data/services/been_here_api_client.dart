import 'dart:convert';
import 'package:flutter/foundation.dart';

class BeenHereApiConfig {
  BeenHereApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BEEN_HERE_API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
}

class BeenHereApiClient {
  const BeenHereApiClient({this.baseUrl = BeenHereApiConfig.baseUrl});

  final String baseUrl;

  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final rawUri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return rawUri;
    }

    final cleanedQuery = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value != null && value.toString().trim().isNotEmpty) {
        cleanedQuery[entry.key] = value.toString();
      }
    }
    return rawUri.replace(queryParameters: cleanedQuery);
  }

  Map<String, dynamic> decodeJsonMap(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    debugPrint('Unexpected JSON format from BeenHere API');
    return <String, dynamic>{};
  }
}
