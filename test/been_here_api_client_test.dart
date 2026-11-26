import 'dart:convert';

import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('BeenHereApiConfig', () {
    test('varsayilan token dev:user-1 ve baseUrl /api/v1 icermiyor', () {
      expect(BeenHereApiConfig.defaultAuthToken, 'dev:user-1');

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(BeenHereApiConfig.baseUrl, 'http://10.0.2.2:3000');
      expect(BeenHereApiConfig.baseUrl.contains('/api/v1'), isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(BeenHereApiConfig.baseUrl, 'http://localhost:3000');

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(BeenHereApiConfig.baseUrl, 'http://localhost:3000');
    });

    test('Web ortaminda Uri.base hostundan 3000 portlu backend URL uretir', () {
      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: Uri.parse('http://192.168.1.176:8080/'),
          targetPlatform: TargetPlatform.macOS,
        ),
        'http://192.168.1.176:3000',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: Uri.parse('http://192.168.1.176:8080/'),
          targetPlatform: TargetPlatform.android,
        ),
        'http://192.168.1.176:3000',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: Uri.parse('https://app.beenhere.dev:8443/explore'),
          targetPlatform: TargetPlatform.iOS,
        ),
        'https://app.beenhere.dev:3000',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: Uri(host: '192.168.1.176', port: 8080),
          targetPlatform: TargetPlatform.macOS,
        ),
        'http://192.168.1.176:3000',
      );
    });

    test('Web ortaminda host bos ise localhost:3000, BEEN_HERE_API_URL varsa override kullanir', () {
      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: Uri.parse('file:///index.html'),
          targetPlatform: TargetPlatform.android,
        ),
        'http://localhost:3000',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: true,
          baseUri: null,
          targetPlatform: TargetPlatform.macOS,
        ),
        'http://localhost:3000',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '  https://api.beenhere.dev///  ',
          isWeb: true,
          baseUri: Uri.parse('http://192.168.1.176:8080/'),
          targetPlatform: TargetPlatform.android,
        ),
        'https://api.beenhere.dev',
      );

      expect(
        BeenHereApiConfig.resolveBaseUrl(
          configuredBaseUrl: '',
          isWeb: false,
          baseUri: Uri.parse('http://192.168.1.176:8080/'),
          targetPlatform: TargetPlatform.android,
        ),
        'http://10.0.2.2:3000',
      );
    });
  });

  group('BeenHereApiClient.buildUri', () {
    test('Iterable parametreleri virgul ile birlestirir ve bosluklari temizler', () {
      final client = BeenHereApiClient(baseUrl: 'http://localhost:3000/');

      final uri = client.buildUri('places/search', <String, dynamic>{
        'q': '  kapadokya  ',
        'continents': <String?>['europe', ' asia ', '', null],
        'emptyList': <String>[],
        'blank': '   ',
        'nil': null,
        'limit': 20,
      });

      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 3000);
      expect(uri.path, '/places/search');
      expect(uri.queryParameters, <String, String>{
        'q': 'kapadokya',
        'continents': 'europe,asia',
        'limit': '20',
      });
    });

    test('tum query parametreleri bos ise gereksiz soru isareti eklemez', () {
      final client = BeenHereApiClient(baseUrl: 'http://localhost:3000');

      final uri = client.buildUri('/places/feed', <String, dynamic>{
        'q': '   ',
        'regions': <String>[],
        'city': null,
      });

      expect(uri.toString(), 'http://localhost:3000/places/feed');
    });
  });

  group('BeenHereApiClient HTTP islemleri ve TransformInterceptor', () {
    test('GET isteginde Bearer dev:user-1 headeri gonderir ve Map zarfini acar', () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((http.Request request) async {
        capturedRequest = request;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'place-1',
                    'name': 'Çırağan & Boğaz Hattı',
                  },
                ],
                'total': 1,
              },
              'timestamp': '2026-11-13T14:00:00.000Z',
            }),
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );

      final result = await client.get(
        '/places/feed',
        queryParameters: <String, dynamic>{
          'cities': <String>['İstanbul', ' İzmir '],
          'limit': 10,
        },
      );

      expect(capturedRequest.method, 'GET');
      expect(
        capturedRequest.url.toString(),
        'http://localhost:3000/places/feed?cities=%C4%B0stanbul%2C%C4%B0zmir&limit=10',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer dev:user-1');
      expect(capturedRequest.headers['Accept'], 'application/json');

      expect(result, isA<Map<String, dynamic>>());
      final payload = result as Map<String, dynamic>;
      expect(payload['total'], 1);
      final items = payload['items'] as List<dynamic>;
      expect((items.first as Map<String, dynamic>)['name'], 'Çırağan & Boğaz Hattı');
    });

    test('POST /places/fetch-google gibi List donen TransformInterceptor zarfini acar', () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((http.Request request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'gp-1', 'name': 'Galata Kulesi'},
              <String, dynamic>{'id': 'gp-2', 'name': 'Karaköy Lokantası'},
            ],
            'timestamp': '2026-11-13T14:01:00.000Z',
          }),
          201,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
        authToken: 'dev:premium:user-2',
      );

      final result = await client.post(
        '/places/fetch-google',
        body: <String, dynamic>{'query': 'Galata', 'lang': 'tr'},
      );

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.headers['Authorization'],
        'Bearer dev:premium:user-2',
      );
      expect(
        capturedRequest.headers['Content-Type'],
        'application/json; charset=UTF-8',
      );
      expect(
        jsonDecode(capturedRequest.body),
        <String, dynamic>{'query': 'Galata', 'lang': 'tr'},
      );

      expect(result, isA<List<dynamic>>());
      final places = result as List<dynamic>;
      expect(places, hasLength(2));
      expect((places.first as Map<String, dynamic>)['name'], 'Galata Kulesi');
    });

    test('PATCH, DELETE, includeAuth: false ve dinamik authTokenProvider desteklenir', () async {
      final recordedRequests = <http.Request>[];
      String? currentToken = 'dev:user-1';

      final mockClient = MockClient((http.Request request) async {
        recordedRequests.add(request);
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(
          jsonEncode(<String, dynamic>{'updated': true}),
          200,
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
        authTokenProvider: () => currentToken,
      );

      final patchResult = await client.patch(
        '/routes/r-1',
        body: <String, dynamic>{'title': 'Güncel Rota'},
      );
      expect(patchResult, <String, dynamic>{'updated': true});
      expect(recordedRequests[0].method, 'PATCH');
      expect(recordedRequests[0].headers['Authorization'], 'Bearer dev:user-1');

      currentToken = 'dev:premium:user-99';
      await client.get('/routes/discovery-deck', includeAuth: false);
      expect(
        recordedRequests[1].headers.containsKey('Authorization'),
        isFalse,
      );

      final deleteResult = await client.delete(
        '/places/lists/l-1/items/p-1',
      );
      expect(deleteResult, isNull);
      expect(recordedRequests[2].method, 'DELETE');
      expect(
        recordedRequests[2].headers['Authorization'],
        'Bearer dev:premium:user-99',
      );
    });

    test('buyuk JSON yanitlari isolate uzerinden basariyla ayristirir', () async {
      final largeList = List<Map<String, dynamic>>.generate(
        400,
        (int index) => <String, dynamic>{
          'id': 'place-$index',
          'name': 'Mekan $index - Uzun Açıklama Metni ile Kapasite Testi',
        },
      );

      final mockClient = MockClient((http.Request request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': largeList,
              'timestamp': '2026-11-13T14:05:00.000Z',
            }),
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );

      final result = await client.get('/places/feed');
      expect(result, isA<List<dynamic>>());
      expect((result as List<dynamic>), hasLength(400));
    });
  });

  group('BeenHereApiException ve AllExceptionsFilter hata donusumu', () {
    test('String message iceren 401 hatasini BeenHereApiException olarak firlatir', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'success': false,
              'statusCode': 401,
              'timestamp': '2026-11-13T14:10:00.000Z',
              'path': '/routes/me',
              'message':
                  'Bu işlem için giriş yapmanız gerekmektedir (Bearer token eksik).',
            }),
          ),
          401,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );

      expect(
        () => client.get('/routes/me', includeAuth: false),
        throwsA(
          isA<BeenHereApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.path, 'path', '/routes/me')
              .having(
                (e) => e.message,
                'message',
                'Bu işlem için giriş yapmanız gerekmektedir (Bearer token eksik).',
              )
              .having((e) => e.messages, 'messages', <String>[
                'Bu işlem için giriş yapmanız gerekmektedir (Bearer token eksik).',
              ])
              .having(
                (e) => e.toString(),
                'toString',
                contains('BeenHereApiException(401) [/routes/me]:'),
              ),
        ),
      );
    });

    test('List<String> validation hatalarini okunabilir tek mesaja birlestirir', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': false,
            'statusCode': 400,
            'timestamp': '2026-11-13T14:12:00.000Z',
            'path': '/routes',
            'message': <String>[
              'title should not be empty',
              'continent must be a string',
            ],
          }),
          400,
        );
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );

      await expectLater(
        () => client.post('/routes', body: <String, dynamic>{}),
        throwsA(
          isA<BeenHereApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.path, 'path', '/routes')
              .having(
                (e) => e.message,
                'message',
                'title should not be empty • continent must be a string',
              )
              .having((e) => e.messages, 'messages', <String>[
                'title should not be empty',
                'continent must be a string',
              ]),
        ),
      );
    });

    test('zaman asimi durumunda BeenHereApiException firlatir', () async {
      final mockClient = MockClient((http.Request request) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response('{}', 200);
      });

      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        () => client.get('/places/feed'),
        throwsA(
          isA<BeenHereApiException>()
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having((e) => e.path, 'path', '/places/feed')
              .having((e) => e.message, 'message', contains('zaman aşımı')),
        ),
      );
    });
  });
}
