import 'dart:convert';

import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:been_here_mobile/data/services/geography_api_service.dart';
import 'package:been_here_mobile/data/stores/geography_store.dart';
import 'package:been_here_mobile/domain/models/geography_models.dart';
import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/ui/core/filters/geography_tree_filter_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _envelopeResponse(dynamic data, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode(<String, dynamic>{
        'success': true,
        'data': data,
        'timestamp': '2026-11-14T15:00:00.000Z',
      }),
    ),
    statusCode,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Map<String, dynamic> _sampleTreePayload() {
  return <String, dynamic>{
    'lang': 'tr',
    'global_option': <String, dynamic>{
      'code': 'GLOBAL',
      'name': 'Global',
      'default_name': 'Global',
      'name_translations': <String, String>{
        'tr': 'Global',
        'en': 'Global',
      },
      'image_url': 'https://cdn.beenhere.dev/geo/global.jpg',
      'places_count': 7,
      'routes_count': 3,
    },
    'continents': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'cont-europe',
        'code': 'EUROPE',
        'name': 'Avrupa',
        'default_name': 'Avrupa',
        'name_translations': <String, String>{
          'tr': 'Avrupa',
          'en': 'Europe',
        },
        'image_url': 'https://cdn.beenhere.dev/geo/europe.jpg',
        'places_count': 5,
        'routes_count': 2,
        'regions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'balkans',
            'uuid': 'reg-balkans-uuid',
            'code': 'balkans',
            'continent_code': 'EUROPE',
            'name': 'Balkanlar',
            'default_name': 'Balkanlar',
            'name_translations': <String, String>{
              'tr': 'Balkanlar',
              'en': 'Balkans',
            },
            'image_url': 'https://cdn.beenhere.dev/geo/balkans.jpg',
            'country_codes': <String>['TR', 'GR', 'HR'],
            'country_names': <String>['Türkiye', 'Yunanistan', 'Hırvatistan'],
            'places_count': 5,
            'routes_count': 2,
          },
          <String, dynamic>{
            'id': 'western_europe',
            'uuid': 'reg-west-eu-uuid',
            'code': 'western_europe',
            'continent_code': 'EUROPE',
            'name': 'Batı Avrupa',
            'default_name': 'Batı Avrupa',
            'name_translations': <String, String>{
              'tr': 'Batı Avrupa',
              'en': 'Western Europe',
            },
            'image_url': 'https://cdn.beenhere.dev/geo/west-eu.jpg',
            'country_codes': <String>['DE', 'FR'],
            'country_names': <String>['Almanya', 'Fransa'],
            'places_count': 3,
            'routes_count': 1,
          },
        ],
        'countries': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'country-tr',
            'code': 'TR',
            'continent_code': 'EUROPE',
            'name': 'Türkiye',
            'default_name': 'Türkiye',
            'name_translations': <String, String>{
              'tr': 'Türkiye',
              'en': 'Turkey',
            },
            'aliases': <String>['Turkiye', 'Türkiye Cumhuriyeti'],
            'flag_emoji': '🇹🇷',
            'image_url': 'https://cdn.beenhere.dev/geo/tr.jpg',
            'places_count': 3,
            'routes_count': 1,
            'cities': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'city-izmir',
                'slug': 'tr:izmir',
                'country_code': 'TR',
                'name': 'İzmir',
                'default_name': 'İzmir',
                'name_translations': <String, String>{
                  'tr': 'İzmir',
                  'en': 'Izmir',
                },
                'image_url': 'https://cdn.beenhere.dev/geo/izmir.jpg',
                'is_popular': true,
                'places_count': 2,
                'routes_count': 1,
                'districts': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'dist-selcuk',
                    'slug': 'tr:izmir:selcuk',
                    'city_slug': 'tr:izmir',
                    'country_code': 'TR',
                    'name': 'Selçuk',
                    'default_name': 'Selçuk',
                    'name_translations': <String, String>{
                      'tr': 'Selçuk',
                      'en': 'Ephesus',
                    },
                    'places_count': 2,
                  },
                  <String, dynamic>{
                    'id': 'dist-bergama',
                    'slug': 'tr:izmir:bergama',
                    'city_slug': 'tr:izmir',
                    'country_code': 'TR',
                    'name': 'Bergama',
                    'default_name': 'Bergama',
                    'name_translations': <String, String>{
                      'tr': 'Bergama',
                      'en': 'Pergamon',
                    },
                    'places_count': 1,
                  },
                ],
              },
            ],
          },
          <String, dynamic>{
            'id': 'country-it',
            'code': 'IT',
            'continent_code': 'EUROPE',
            'name': 'İtalya',
            'default_name': 'İtalya',
            'name_translations': <String, String>{
              'tr': 'İtalya',
              'en': 'Italy',
            },
            'aliases': <String>['Italia'],
            'flag_emoji': '🇮🇹',
            'image_url': 'https://cdn.beenhere.dev/geo/it.jpg',
            'places_count': 2,
            'routes_count': 1,
            'cities': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'city-rome',
                'slug': 'it:roma',
                'country_code': 'IT',
                'name': 'Roma',
                'default_name': 'Roma',
                'name_translations': <String, String>{
                  'tr': 'Roma',
                  'en': 'Rome',
                },
                'image_url': 'https://cdn.beenhere.dev/geo/rome.jpg',
                'is_popular': true,
                'places_count': 2,
                'routes_count': 1,
                'districts': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'dist-selcuk',
                    'slug': 'tr:izmir:selcuk',
                    'city_slug': 'tr:izmir',
                    'country_code': 'TR',
                    'name': 'Selçuk',
                    'default_name': 'Selçuk',
                    'name_translations': <String, String>{
                      'tr': 'Selçuk',
                      'en': 'Ephesus',
                    },
                    'places_count': 2,
                  },
                  <String, dynamic>{
                    'id': 'dist-bergama',
                    'slug': 'tr:izmir:bergama',
                    'city_slug': 'tr:izmir',
                    'country_code': 'TR',
                    'name': 'Bergama',
                    'default_name': 'Bergama',
                    'name_translations': <String, String>{
                      'tr': 'Bergama',
                      'en': 'Pergamon',
                    },
                    'places_count': 1,
                  },
                ],
              },
            ],
          },
          <String, dynamic>{
            'id': 'country-de',
            'code': 'DE',
            'continent_code': 'EUROPE',
            'name': 'Almanya',
            'default_name': 'Almanya',
            'name_translations': <String, String>{
              'tr': 'Almanya',
              'en': 'Germany',
            },
            'aliases': <String>['Deutschland'],
            'flag_emoji': '🇩🇪',
            'image_url': 'https://cdn.beenhere.dev/geo/de.jpg',
            'places_count': 1,
            'routes_count': 0,
            'cities': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'city-berlin',
                'slug': 'de:berlin',
                'country_code': 'DE',
                'name': 'Berlin',
                'default_name': 'Berlin',
                'name_translations': <String, String>{
                  'tr': 'Berlin',
                  'en': 'Berlin',
                },
                'image_url': 'https://cdn.beenhere.dev/geo/berlin.jpg',
                'is_popular': false,
                'places_count': 1,
                'routes_count': 0,
              },
            ],
          },
        ],
      },
    ],
    'popular_suggestions': <String, dynamic>{
      'cities': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'city-izmir',
          'slug': 'tr:izmir',
          'country_code': 'TR',
          'name': 'İzmir',
          'default_name': 'İzmir',
          'name_translations': <String, String>{
            'tr': 'İzmir',
            'en': 'Izmir',
          },
          'image_url': 'https://cdn.beenhere.dev/geo/izmir.jpg',
          'is_popular': true,
          'places_count': 2,
          'routes_count': 1,
        },
      ],
      'regions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'balkans',
          'uuid': 'reg-balkans-uuid',
          'code': 'balkans',
          'continent_code': 'EUROPE',
          'name': 'Balkanlar',
          'default_name': 'Balkanlar',
          'name_translations': <String, String>{
            'tr': 'Balkanlar',
            'en': 'Balkans',
          },
          'image_url': 'https://cdn.beenhere.dev/geo/balkans.jpg',
          'country_codes': <String>['TR', 'GR', 'HR'],
          'country_names': <String>['Türkiye', 'Yunanistan', 'Hırvatistan'],
          'places_count': 5,
          'routes_count': 2,
        },
      ],
      'continents': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'cont-europe',
          'code': 'EUROPE',
          'name': 'Avrupa',
          'default_name': 'Avrupa',
          'name_translations': <String, String>{
            'tr': 'Avrupa',
            'en': 'Europe',
          },
          'image_url': 'https://cdn.beenhere.dev/geo/europe.jpg',
          'places_count': 5,
          'routes_count': 2,
        },
      ],
    },
  };
}

class _TestGeographyFilterController extends ChangeNotifier
    with GeographyTreeFilterMixin {
  _TestGeographyFilterController(this._store);

  final GeographyStore _store;
  int filterRefreshCount = 0;

  @override
  GeographyStore? get geographyStore => _store;

  @override
  void onSearchAndLocationFiltersChanged() {
    filterRefreshCount++;
  }

  @override
  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent,
  ) {
    return _store.getCountriesForContinent(continent);
  }

  @override
  List<String> getCitiesForCountry(String countryCode) {
    return _store.getCitiesForCountry(countryCode);
  }
}

void main() {
  group('GeographyStore & GeographyApiService', () {
    test(
      'GET /geography/tree yanıtını parse eder, Balkanlar ve name_translations eşleştirmelerini doğru çalıştırır',
      () async {
        int treeRequestCount = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path == '/geography/tree') {
            treeRequestCount++;
            expect(request.url.queryParameters['lang'], 'tr');
            return _envelopeResponse(_sampleTreePayload());
          }
          if (request.url.path == '/geography/search') {
            return _envelopeResponse(<String, dynamic>{
              'lang': 'tr',
              'query': request.url.queryParameters['q'],
              'results': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'region',
                  'id': 'reg-balkans-uuid',
                  'code': 'balkans',
                  'name': 'Balkanlar',
                  'default_name': 'Balkanlar',
                  'name_translations': <String, String>{
                    'tr': 'Balkanlar',
                    'en': 'Balkans',
                  },
                  'subtitle': 'Avrupa - Bölge',
                  'continent_code': 'EUROPE',
                  'country_code': null,
                  'region_code': 'balkans',
                  'city_name': null,
                  'flag_emoji': null,
                  'image_url': 'https://cdn.beenhere.dev/geo/balkans.jpg',
                },
              ],
            });
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final apiService = GeographyApiService(apiClient: apiClient);
        final store = GeographyStore(apiService: apiService);

        // Eşzamanlı ensureLoaded tek HTTP isteği atmalı
        await Future.wait(<Future<void>>[
          store.ensureLoaded(lang: 'tr'),
          store.ensureLoaded(lang: 'tr'),
        ]);
        expect(treeRequestCount, 1);
        expect(store.hasLoaded, isTrue);
        expect(store.isLoading, isFalse);
        expect(store.errorMessage, isNull);

        // Katalog & sayaç kontrolleri
        expect(store.continentsCatalog.length, 1);
        expect(store.continentsCatalog.first.name, 'Avrupa');
        expect(
          store.continentsCatalog.first.regions.map((r) => r.name),
          containsAll(<String>['Balkanlar', 'Batı Avrupa']),
        );
        expect(store.countPlacesForContinent(ContinentFilter.global), 7);
        expect(store.countRoutesForContinent(ContinentFilter.global), 3);
        expect(store.countPlacesForContinent(ContinentFilter.europe), 5);
        expect(store.countRoutesForContinent(ContinentFilter.europe), 2);
        expect(store.countPlacesForRegion('balkans'), 5);
        expect(store.countRoutesForRegion('balkans'), 2);
        expect(store.getCitiesForCountry('TR'), <String>['İzmir']);
        expect(store.findCountry('IT')?.name, 'İtalya');
        expect(store.findRegion('balkans')?.localizedName('en'), 'Balkans');

        // Boş sorgu -> DB popüler önerileri (İzmir, Balkanlar, Avrupa)
        final popular = store.buildSearchSuggestions('');
        expect(
          popular.map((s) => s.title),
          <String>['İzmir', 'Balkanlar', 'Avrupa'],
        );

        // "Balkans" -> name_translations['en'] üzerinden "Balkanlar" önerisi
        final balkansSuggestions = store.buildSearchSuggestions('Balkans');
        expect(
          balkansSuggestions.any(
            (s) =>
                s.type == RouteSearchSuggestionType.region &&
                s.title == 'Balkanlar' &&
                s.pill.regionId == 'balkans',
          ),
          isTrue,
        );

        // "Rome" -> name_translations['en'] üzerinden "Roma" önerisi
        final romeSuggestions = store.buildSearchSuggestions('Rome');
        expect(
          romeSuggestions.any(
            (s) =>
                s.type == RouteSearchSuggestionType.city &&
                s.title == 'Roma' &&
                s.subtitle == 'Avrupa - İtalya' &&
                s.pill.countryCode == 'IT',
          ),
          isTrue,
        );

        // "Europe" -> name_translations['en'] üzerinden "Avrupa" önerisi
        final europeSuggestions = store.buildSearchSuggestions('Europe');
        expect(
          europeSuggestions.any(
            (s) =>
                s.type == RouteSearchSuggestionType.continent &&
                s.title == 'Avrupa' &&
                s.pill.continent == ContinentFilter.europe,
          ),
          isTrue,
        );

        // "Turkiye" -> aliases üzerinden "Türkiye" önerisi
        final turkeySuggestions = store.buildSearchSuggestions('Turkiye');
        expect(
          turkeySuggestions.any(
            (s) =>
                s.type == RouteSearchSuggestionType.country &&
                s.title == 'Türkiye' &&
                s.pill.countryCode == 'TR',
          ),
          isTrue,
        );

        // GET /geography/search servis doğrulaması
        final searchResults = await apiService.searchGeography(
          query: 'Balkans',
          lang: 'tr',
        );
        expect(searchResults.length, 1);
        expect(searchResults.first.type, 'region');
        expect(searchResults.first.localizedName('tr'), 'Balkanlar');
        expect(searchResults.first.localizedName('en'), 'Balkans');
        expect(searchResults.first.continentFilter, ContinentFilter.europe);

        apiClient.close();
      },
    );

    test(
      'GeographyTreeFilterMixin ağaç aramasında name_translations (Germany, Rome) eşleştirir',
      () async {
        final mockClient = MockClient((request) async {
          return _envelopeResponse(_sampleTreePayload());
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        final controller = _TestGeographyFilterController(store);
        expect(
          controller.searchContinentsCatalog.first.regions.first.name,
          'Balkanlar',
        );

        // Ağaç aramasında "Germany" yazınca "Almanya" eşleşmeli
        controller.updateTreeSearchQuery('Germany');
        final germanyMatch = controller.getFilteredCountriesForTree(
          ContinentFilter.europe,
        );
        expect(germanyMatch.map((c) => c.code), <String>['DE']);

        // Ağaç aramasında "Rome" yazınca İtalya açılmalı ve "Roma" gelmeli
        controller.updateTreeSearchQuery('Rome');
        final romeCountryMatch = controller.getFilteredCountriesForTree(
          ContinentFilter.europe,
        );
        expect(romeCountryMatch.map((c) => c.code), <String>['IT']);
        expect(controller.isCountryExpanded('IT'), isTrue);
        expect(
          controller.getFilteredCitiesForTree(romeCountryMatch.first),
          <String>['Roma'],
        );

        controller.dispose();
        apiClient.close();
      },
    );

    test('API hatasında errorMessage set edilir ve hasLoaded false kalır', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'success': false,
              'statusCode': 500,
              'message': 'Coğrafya servisi geçici olarak kullanılamıyor.',
            }),
          ),
          500,
          headers: const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });
      final apiClient = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );
      final store = GeographyStore(
        apiService: GeographyApiService(apiClient: apiClient),
      );

      await store.ensureLoaded(lang: 'tr');

      expect(store.hasLoaded, isFalse);
      expect(store.isLoading, isFalse);
      expect(
        store.errorMessage,
        'Coğrafya servisi geçici olarak kullanılamıyor.',
      );

      apiClient.close();
    });

    test(
      'GeographyCityNode districts alanını ayrıştırır, getDistrictsForCity ve buildSearchSuggestions ilçe önerilerini üretir',
      () async {
        final mockClient = MockClient((request) async {
          return _envelopeResponse(_sampleTreePayload());
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        final izmirNode = store
            .getCityNodesForCountry('TR')
            .firstWhere((c) => c.slug == 'tr:izmir');
        expect(izmirNode.districts.length, 2);
        expect(izmirNode.districts.first.localizedName('tr'), 'Selçuk');
        expect(izmirNode.districts.first.localizedName('en'), 'Ephesus');
        expect(izmirNode.districts.first.citySlug, 'tr:izmir');
        expect(izmirNode.districts.first.placesCount, 2);

        expect(
          store.getDistrictsForCity('TR', 'İzmir'),
          <String>['Selçuk', 'Bergama'],
        );
        expect(
          store.getDistrictNodesForCity('TR', 'tr:izmir').map((d) => d.slug),
          <String>['tr:izmir:selcuk', 'tr:izmir:bergama'],
        );

        final selcukSuggestions = store.buildSearchSuggestions('Selçuk');
        final selcukMatch = selcukSuggestions.firstWhere(
          (s) => s.id == 'district:tr:izmir:selcuk',
        );
        expect(selcukMatch.type, RouteSearchSuggestionType.district);
        expect(selcukMatch.title, 'Selçuk, İzmir');
        expect(selcukMatch.subtitle, 'Avrupa - Türkiye (İzmir İlçesi)');
        expect(selcukMatch.pill.type, RouteFilterPillType.district);
        expect(selcukMatch.pill.id, 'district:tr:izmir:selcuk');
        expect(selcukMatch.pill.label, 'Selçuk (İzmir)');
        expect(selcukMatch.pill.districtName, 'Selçuk');
        expect(selcukMatch.pill.cityName, 'İzmir');
        expect(selcukMatch.pill.countryCode, 'TR');

        final ephesusSuggestions = store.buildSearchSuggestions('Ephesus');
        expect(
          ephesusSuggestions.any(
            (s) =>
                s.id == 'district:tr:izmir:selcuk' &&
                s.type == RouteSearchSuggestionType.district &&
                s.title == 'Selçuk, İzmir' &&
                s.pill.type == RouteFilterPillType.district &&
                s.pill.districtName == 'Selçuk',
          ),
          isTrue,
        );

        apiClient.close();
      },
    );

    test(
      'searchRemote canlı /geography/search sonuçlarını önbelleğe alır, tekilleştirir ve buildSearchSuggestions içine birleştirir',
      () async {
        int searchRequests = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path == '/geography/tree') {
            return _envelopeResponse(_sampleTreePayload());
          }
          if (request.url.path == '/geography/search') {
            searchRequests++;
            return _envelopeResponse(<String, dynamic>{
              'lang': 'tr',
              'query': request.url.queryParameters['q'],
              'results': <Map<String, dynamic>>[
                // Yerel ağaçta zaten bulunan ilçe (tekilleştirilmeli)
                <String, dynamic>{
                  'type': 'district',
                  'id': 'dist-selcuk',
                  'slug': 'tr:izmir:selcuk',
                  'city_slug': 'tr:izmir',
                  'city_name': 'İzmir',
                  'country_code': 'TR',
                  'country_name': 'Türkiye',
                  'continent_code': 'EUROPE',
                  'name': 'Selçuk',
                  'default_name': 'Selçuk',
                  'name_translations': <String, String>{
                    'tr': 'Selçuk',
                    'en': 'Ephesus',
                  },
                  'places_count': 2,
                },
                // Yerel ağaçta bulunmayan yeni ilçe (eklenmeli)
                <String, dynamic>{
                  'type': 'district',
                  'id': 'dist-beyoglu',
                  'slug': 'tr:istanbul:beyoglu',
                  'city_slug': 'tr:istanbul',
                  'city_name': 'İstanbul',
                  'country_code': 'TR',
                  'country_name': 'Türkiye',
                  'continent_code': 'EUROPE',
                  'name': 'Beyoğlu',
                  'default_name': 'Beyoğlu',
                  'name_translations': <String, String>{
                    'tr': 'Beyoğlu',
                    'en': 'Beyoglu',
                  },
                  'places_count': 9,
                },
                // Yerel ağaçta bulunmayan yeni şehir
                <String, dynamic>{
                  'type': 'city',
                  'id': 'city-bursa',
                  'slug': 'tr:bursa',
                  'country_code': 'TR',
                  'country_name': 'Türkiye',
                  'continent_code': 'EUROPE',
                  'name': 'Bursa',
                  'default_name': 'Bursa',
                  'name_translations': <String, String>{
                    'tr': 'Bursa',
                    'en': 'Bursa',
                  },
                  'places_count': 4,
                },
              ],
            });
          }
          return http.Response('Not found', 404);
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        // 2 karakterden kısa sorgu remote istek atmamalı
        await store.searchRemote('B');
        expect(searchRequests, 0);

        await store.searchRemote('Bey');
        expect(searchRequests, 1);

        // Tekrar aynı sorguda cache'ten dönmeli, ikinci HTTP çağrısı yapılmamalı
        await store.searchRemote('Bey');
        expect(searchRequests, 1);

        final suggestions = store.buildSearchSuggestions('Bey');
        final beyoglu = suggestions.firstWhere(
          (s) => s.id == 'district:tr:istanbul:beyoglu',
        );
        expect(beyoglu.type, RouteSearchSuggestionType.district);
        expect(beyoglu.title, 'Beyoğlu, İstanbul');
        expect(beyoglu.pill.type, RouteFilterPillType.district);
        expect(beyoglu.pill.districtName, 'Beyoğlu');
        expect(beyoglu.pill.cityName, 'İstanbul');
        expect(beyoglu.pill.countryCode, 'TR');

        // Selçuk yerel ağaçtan geldiği için remote duplicate olmamalı
        final selcukCount = suggestions
            .where((s) => s.id == 'district:tr:izmir:selcuk')
            .length;
        expect(selcukCount, lessThanOrEqualTo(1));

        apiClient.close();
      },
    );

    test(
      'GeographyTreeFilterMixin 4. seviye ilçe seçimlerini, şehir açılımını ve kademeli temizlemeyi yönetir',
      () async {
        final mockClient = MockClient((request) async {
          return _envelopeResponse(_sampleTreePayload());
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        final controller = _TestGeographyFilterController(store);
        expect(controller.isCityExpanded('TR', 'İzmir'), isFalse);

        controller.toggleCityExpanded('TR', 'İzmir');
        expect(controller.isCityExpanded('TR', 'İzmir'), isTrue);

        controller.toggleDistrictCheckbox('İzmir', 'Selçuk');
        expect(controller.isDistrictChecked('İzmir', 'Selçuk'), isTrue);
        expect(controller.selectedDistrictNames, <String>['Selçuk']);
        expect(controller.isGlobalSelected, isFalse);
        expect(controller.geographyFilterButtonTitle, '🇹🇷 Türkiye: Selçuk');
        expect(
          controller.getCityPartialSelectionBadge('TR', 'İzmir'),
          '1 ilçe seçili',
        );

        // Şehir seçilince altındaki kısmi ilçe seçimleri temizlenmeli
        controller.toggleCityCheckbox('İzmir');
        expect(controller.isCityChecked('İzmir'), isTrue);
        expect(controller.selectedDistrictNames, isEmpty);
        expect(controller.geographyFilterButtonTitle, '🇹🇷 Türkiye: İzmir');

        // Şehir seçimi kaldırıldığında ağaç araması "Selçuk" -> İzmir şehri otomatik açılmalı
        controller.toggleCityCheckbox('İzmir');
        expect(controller.isCityChecked('İzmir'), isFalse);
        controller.updateTreeSearchQuery('Selçuk');
        expect(controller.isCountryExpanded('TR'), isTrue);
        expect(controller.isCityExpanded('TR', 'İzmir'), isTrue);
        expect(
          controller
              .getFilteredDistrictsForTree('TR', 'İzmir')
              .map((d) => d.localizedName('tr')),
          <String>['Selçuk'],
        );

        controller.dispose();
        apiClient.close();
      },
    );

    test(
      'Drawer session: çoklu taslak seçiminde istek atmaz, iptalde snapshot geri yükler, commit yalnızca değişiklik varsa tetikler',
      () async {
        final mockClient = MockClient((request) async {
          return _envelopeResponse(_sampleTreePayload());
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        final controller = _TestGeographyFilterController(store);

        // Başlangıçta TR -> İzmir seçili olsun (çekmece dışında anında 1 tetikleme)
        controller.toggleCityCheckbox('İzmir');
        expect(controller.filterRefreshCount, 1);
        expect(controller.selectedCities, <String>{'İzmir'});

        // 1. Oturum: Değişiklik yapıp cancelGeographyDrawerSelections() -> 0 yeni çağrı & snapshot geri yüklenir
        controller.beginGeographyDrawerSession();
        expect(controller.hasActiveGeographyDrawerSession, isTrue);
        expect(controller.hasPendingGeographyDrawerChanges, isFalse);

        controller.toggleCityCheckbox('İzmir');
        controller.toggleCountryCheckbox('IT');
        controller.toggleDistrictCheckbox('İzmir', 'Selçuk');
        expect(controller.hasPendingGeographyDrawerChanges, isTrue);
        expect(controller.filterRefreshCount, 1);

        controller.cancelGeographyDrawerSelections();
        expect(controller.hasActiveGeographyDrawerSession, isFalse);
        expect(controller.filterRefreshCount, 1);
        expect(controller.selectedCities, <String>{'İzmir'});
        expect(controller.selectedFullCountryCodes, isEmpty);
        expect(controller.selectedDistrictNames, isEmpty);

        // 2. Oturum: Değişiklik yapmadan commitGeographyDrawerSelections() -> 0 yeni çağrı
        controller.beginGeographyDrawerSession();
        expect(controller.hasPendingGeographyDrawerChanges, isFalse);
        controller.commitGeographyDrawerSelections();
        expect(controller.hasActiveGeographyDrawerSession, isFalse);
        expect(controller.filterRefreshCount, 1);

        // 3. Oturum: Taslakta resetToGlobal + başka seçim yapıp commit -> tek seferde 1 yeni çağrı
        controller.beginGeographyDrawerSession();
        controller.resetToGlobal();
        controller.toggleCountryCheckbox('DE');
        expect(controller.hasPendingGeographyDrawerChanges, isTrue);
        expect(controller.filterRefreshCount, 1);

        controller.commitGeographyDrawerSelections();
        expect(controller.hasActiveGeographyDrawerSession, isFalse);
        expect(controller.filterRefreshCount, 2);
        expect(controller.selectedFullCountryCodes, <String>{'DE'});
        expect(controller.selectedCities, isEmpty);

        controller.dispose();
        apiClient.close();
      },
    );

    test(
      'updateCountryCitySearchQuery 29 şehirli ülkede lokal şehir/ilçe filtreler ve eşleşme yoksa boş liste döner',
      () async {
        final payload = _sampleTreePayload();
        final continents =
            (payload['continents'] as List).cast<Map<String, dynamic>>();
        final europeCountries =
            (continents.first['countries'] as List).cast<Map<String, dynamic>>();
        final turkeyJson =
            europeCountries.firstWhere((c) => c['code'] == 'TR');
        final existingCities =
            (turkeyJson['cities'] as List).cast<Map<String, dynamic>>();
        final twentyNineCities = <Map<String, dynamic>>[
          ...existingCities,
          for (var i = existingCities.length + 1; i <= 29; i++)
            <String, dynamic>{
              'id': 'city-tr-$i',
              'slug': 'tr:sehir-$i',
              'country_code': 'TR',
              'name': 'Şehir $i',
              'default_name': 'Şehir $i',
              'name_translations': <String, String>{
                'tr': 'Şehir $i',
                'en': 'City $i',
              },
              'image_url': 'https://cdn.beenhere.dev/geo/city-$i.jpg',
              'is_popular': false,
              'places_count': 1,
              'routes_count': 0,
              'districts': const <Map<String, dynamic>>[],
            },
        ];
        turkeyJson['cities'] = twentyNineCities;

        final mockClient = MockClient((request) async {
          return _envelopeResponse(payload);
        });
        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final store = GeographyStore(
          apiService: GeographyApiService(apiClient: apiClient),
        );
        await store.ensureLoaded(lang: 'tr');

        final controller = _TestGeographyFilterController(store);
        final turkeyOption = controller
            .getCountriesForContinent(ContinentFilter.europe)
            .firstWhere((c) => c.code == 'TR');
        expect(controller.getCitiesForCountry('TR').length, 29);

        // Şehir adı eşleşmesi (Şehir 27)
        controller.updateCountryCitySearchQuery('TR', 'Şehir 27');
        expect(
          controller.getFilteredCitiesForTree(turkeyOption),
          <String>['Şehir 27'],
        );
        expect(controller.filterRefreshCount, 0);

        // Alt ilçe eşleşmesi ("Ephesus" -> İzmir açılır, Selçuk kalır)
        controller.updateCountryCitySearchQuery('TR', 'Ephesus');
        expect(
          controller.getFilteredCitiesForTree(turkeyOption),
          <String>['İzmir'],
        );
        expect(controller.isCityExpanded('TR', 'İzmir'), isTrue);
        expect(
          controller
              .getFilteredDistrictsForTree('TR', 'İzmir')
              .map((d) => d.localizedName('tr')),
          <String>['Selçuk'],
        );

        // Eşleşme yoksa tüm şehirleri geri döndürmek yerine boş liste döner
        controller.updateCountryCitySearchQuery('TR', 'OlmayanYerXYZ');
        expect(controller.getFilteredCitiesForTree(turkeyOption), isEmpty);

        // Temizleyince 29 şehir geri gelir
        controller.clearCountryCitySearchQuery('TR');
        expect(
          controller.getFilteredCitiesForTree(turkeyOption).length,
          29,
        );

        controller.dispose();
        apiClient.close();
      },
    );

    test(
      'GeographyCountryNode.hemisphere API değerini ve fallback çıkarımını doğru çözer',
      () {
        // 1. Açık API değeri önceliklidir
        final explicitSouthern = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-ec',
          'code': 'EC',
          'continent_code': 'SOUTH_AMERICA',
          'name': 'Ekvador',
          'hemisphere': 'SOUTHERN',
        });
        expect(explicitSouthern.hemisphere, GeographyHemisphere.southern);

        final explicitNorthernOverride = GeographyCountryNode.fromJson(
          <String, dynamic>{
            'id': 'c-id',
            'code': 'ID',
            'continent_code': 'ASIA',
            'name': 'Endonezya',
            'hemisphere': 'northern',
          },
        );
        expect(
          explicitNorthernOverride.hemisphere,
          GeographyHemisphere.northern,
        );

        // 2. Fallback: Güney yarım küre ülke kodları (ID, BR, AR, CL, PE, ZA, AU, NZ)
        for (final code in const ['ID', 'BR', 'AR', 'CL', 'PE', 'ZA', 'AU', 'NZ']) {
          final node = GeographyCountryNode.fromJson(<String, dynamic>{
            'id': 'c-$code',
            'code': code,
            'continent_code': 'OTHER',
            'name': code,
          });
          expect(
            node.hemisphere,
            GeographyHemisphere.southern,
            reason: '$code için southern bekleniyordu',
          );
        }

        // 3. Fallback: OCEANIA ve CO hariç SOUTH_AMERICA
        final oceaniaNode = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-fj',
          'code': 'FJ',
          'continent_code': 'OCEANIA',
          'name': 'Fiji',
        });
        expect(oceaniaNode.hemisphere, GeographyHemisphere.southern);

        final colombiaNode = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-co',
          'code': 'CO',
          'continent_code': 'SOUTH_AMERICA',
          'name': 'Kolombiya',
        });
        expect(colombiaNode.hemisphere, GeographyHemisphere.northern);

        final uruguayNode = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-uy',
          'code': 'UY',
          'continent_code': 'SOUTH_AMERICA',
          'name': 'Uruguay',
        });
        expect(uruguayNode.hemisphere, GeographyHemisphere.southern);

        // 4. Fallback: Kuzey yarım küre varsayılanı ve constructor default'u
        final turkeyNode = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-tr',
          'code': 'TR',
          'continent_code': 'EUROPE',
          'name': 'Türkiye',
        });
        expect(turkeyNode.hemisphere, GeographyHemisphere.northern);

        const defaultCtorNode = GeographyCountryNode(
          id: 'c-gr',
          code: 'GR',
          continentCode: 'EUROPE',
          name: 'Yunanistan',
          defaultName: 'Yunanistan',
          nameTranslations: <String, String>{},
          aliases: <String>[],
          flagEmoji: '🇬🇷',
          imageUrl: '',
          placesCount: 0,
          routesCount: 0,
          cities: <GeographyCityNode>[],
        );
        expect(defaultCtorNode.hemisphere, GeographyHemisphere.northern);
        expect(defaultCtorNode.currencyCode, 'USD');
      },
    );

    test(
      'GeographyCountryNode para birimi alanlarını API üzerinden ayrıştırır ve eksiklerde ISO 4217 fallback uygular',
      () {
        // 1. Açık backend alanları korunur
        final explicitThailand = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-th',
          'code': 'TH',
          'continent_code': 'ASIA',
          'name': 'Tayland',
          'currency_code': 'thb',
          'currency_symbol': '฿',
          'currency_name_tr': 'Tayland Bahtı',
        });
        expect(explicitThailand.currencyCode, 'THB');
        expect(explicitThailand.currencySymbol, '฿');
        expect(explicitThailand.currencyNameTr, 'Tayland Bahtı');

        // 2. Eski cache / eksik alanlarda ülke kodu üzerinden güvenli ISO 4217 fallback
        final fallbackTurkey = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-tr',
          'code': 'tr',
          'continent_code': 'EUROPE',
          'name': 'Türkiye',
        });
        expect(fallbackTurkey.currencyCode, 'TRY');
        expect(fallbackTurkey.currencySymbol, '₺');
        expect(fallbackTurkey.currencyNameTr, 'Türk Lirası');

        final fallbackJapan = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-jp',
          'code': 'JP',
          'continent_code': 'ASIA',
          'name': 'Japonya',
        });
        expect(fallbackJapan.currencyCode, 'JPY');
        expect(fallbackJapan.currencySymbol, '¥');
        expect(fallbackJapan.currencyNameTr, 'Japon Yeni');

        final fallbackUk = GeographyCountryNode.fromJson(<String, dynamic>{
          'id': 'c-gb',
          'code': 'GB',
          'continent_code': 'EUROPE',
          'name': 'Birleşik Krallık',
        });
        expect(fallbackUk.currencyCode, 'GBP');
        expect(fallbackUk.currencySymbol, '£');
        expect(fallbackUk.currencyNameTr, 'İngiliz Sterlini');

        // 3. Bilinmeyen ülke kodu -> USD varsayılan fallback
        final unknownCountry = resolveCountryCurrencyFallback('ZZ');
        expect(unknownCountry.code, 'USD');
        expect(unknownCountry.symbol, r'$');
        expect(unknownCountry.nameTr, 'ABD Doları');
      },
    );

    test(
      '/geography/tree exchange_rates alanını ayrıştırır, fetchExchangeRates ve refreshExchangeRates çalışır, convertAmount doğru çevirir',
      () async {
        final treePayload = _sampleTreePayload();
        treePayload['exchange_rates'] = <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'USD',
            'symbol': r'$',
            'name_tr': 'ABD Doları',
            'rate_per_usd': 1,
            'fetched_at': '2026-11-17T10:00:00.000Z',
          },
          <String, dynamic>{
            'code': 'TRY',
            'symbol': '₺',
            'name_tr': 'Türk Lirası',
            'rate_per_usd': '35.0',
            'fetched_at': '2026-11-17T10:00:00.000Z',
          },
          <String, dynamic>{
            'code': 'EUR',
            'symbol': '€',
            'name_tr': 'Euro',
            'rate_per_usd': 0.9,
            'fetched_at': '2026-11-17T10:00:00.000Z',
          },
          <String, dynamic>{
            'code': 'THB',
            'symbol': '฿',
            'name_tr': 'Tayland Bahtı',
            'rate_per_usd': '35.0',
            'fetched_at': '2026-11-17T10:00:00.000Z',
          },
        ];

        int exchangeRatesCalls = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path == '/geography/tree') {
            return _envelopeResponse(treePayload);
          }
          if (request.url.path == '/geography/exchange-rates') {
            exchangeRatesCalls++;
            return _envelopeResponse(<String, dynamic>{
              'base': 'USD',
              'source': 'open.er-api',
              'fetched_at': '2026-11-17T12:00:00.000Z',
              'rates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'code': 'USD',
                  'symbol': r'$',
                  'name_tr': 'ABD Doları',
                  'rate_per_usd': 1,
                  'fetched_at': '2026-11-17T12:00:00.000Z',
                },
                <String, dynamic>{
                  'code': 'TRY',
                  'symbol': '₺',
                  'name_tr': 'Türk Lirası',
                  'rate_per_usd': '36.0',
                  'fetched_at': '2026-11-17T12:00:00.000Z',
                },
                <String, dynamic>{
                  'code': 'EUR',
                  'symbol': '€',
                  'name_tr': 'Euro',
                  'rate_per_usd': 0.9,
                  'fetched_at': '2026-11-17T12:00:00.000Z',
                },
              ],
            });
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = BeenHereApiClient(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        );
        final apiService = GeographyApiService(apiClient: apiClient);
        final store = GeographyStore(apiService: apiService);

        // Tree yüklenmeden önce de baseline fallback kurları hazır olmalı
        expect(store.rateFor('TRY')?.ratePerUsd, 34.5);
        expect(store.rateFor('JPY')?.ratePerUsd, 154.0);
        expect(store.rateFor('GBP')?.ratePerUsd, 0.79);
        expect(store.rateFor('UNKNOWN'), isNull);

        await store.ensureLoaded(lang: 'tr');

        // /geography/tree içindeki exchange_rates otomatik yüklenmeli
        expect(store.tree?.exchangeRates.length, 4);
        expect(store.exchangeRates.keys, containsAll(<String>['USD', 'TRY', 'EUR', 'THB']));
        expect(store.rateFor('TRY')?.ratePerUsd, 35.0);
        expect(store.rateFor('TRY')?.symbol, '₺');
        expect(store.rateFor('TRY')?.nameTr, 'Türk Lirası');
        expect(
          store.rateFor('TRY')?.fetchedAt,
          DateTime.utc(2026, 11, 17, 10, 0, 0),
        );
        expect(store.rateFor('THB')?.ratePerUsd, 35.0);

        // DB'de olmayan ama baseline'da olan kur fallback dönmeli
        expect(store.rateFor('JPY')?.ratePerUsd, 154.0);

        // Aynı para birimi dönüşümü tutarı değiştirmemeli
        expect(store.convertAmount(125.5, fromCode: 'TRY', toCode: 'try'), 125.5);

        // Çapraz kur dönüşümü: 90 EUR -> 100 USD -> 3500 TRY
        expect(
          store.convertAmount(90, fromCode: 'EUR', toCode: 'TRY'),
          closeTo(3500.0, 0.0001),
        );
        // 700 THB -> 20 USD -> 18 EUR
        expect(
          store.convertAmount(700, fromCode: 'THB', toCode: 'EUR'),
          closeTo(18.0, 0.0001),
        );

        // Bilinmeyen kur için güvenli fallback (tutarı korur)
        expect(
          store.convertAmount(50, fromCode: 'UNKNOWN', toCode: 'TRY'),
          50.0,
        );

        // fetchExchangeRates doğrudan servis testi
        final directRates = await apiService.fetchExchangeRates();
        expect(exchangeRatesCalls, 1);
        expect(directRates.length, 3);
        expect(directRates.firstWhere((r) => r.code == 'TRY').ratePerUsd, 36.0);

        // refreshExchangeRates listener tetiklemeli ve store kurlarını güncellemeli
        int notifications = 0;
        store.addListener(() => notifications++);
        await store.refreshExchangeRates();
        expect(exchangeRatesCalls, 2);
        expect(notifications, 1);
        expect(store.rateFor('TRY')?.ratePerUsd, 36.0);
        expect(
          store.convertAmount(90, fromCode: 'EUR', toCode: 'TRY'),
          closeTo(3600.0, 0.0001),
        );

        apiClient.close();
      },
    );
  });
}
