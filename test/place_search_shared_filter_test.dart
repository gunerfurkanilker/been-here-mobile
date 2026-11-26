import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:been_here_mobile/data/services/geography_api_service.dart';
import 'package:been_here_mobile/data/stores/geography_store.dart';
import 'package:been_here_mobile/domain/models/place_discovery_models.dart';
import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/widgets/been_here_search_panel.dart';
import 'package:been_here_mobile/ui/features/home/view_models/home_feed_view_model.dart';
import 'package:been_here_mobile/ui/features/search/view_models/place_search_view_model.dart';
import 'package:been_here_mobile/ui/features/search/views/place_search_screen.dart';

void main() {
  setUp(() {
    BeenHereThemeController.instance.setDark();
  });

  group('PlaceSearchViewModel - BeenHereSearchFilterController Testleri', () {
    test('Kıta/bölge sayımları Mekan birimini kullanır ve pill filtreleme OR/AND çalışır', () {
      final vm = PlaceSearchViewModel();

      expect(vm.itemCountUnitLabel, 'Mekan');
      expect(vm.countItemsForContinent(ContinentFilter.europe), 5);
      expect(vm.countItemsForContinent(ContinentFilter.asia), 1);
      expect(vm.displayedPlaces.length, 6);

      // Bölge + kıta konum hapları OR birleşimi uygular
      vm.applyFilterPills([
        const RouteFeedFilterPill(
          id: 'region:southeast_asia',
          type: RouteFilterPillType.region,
          label: 'Güneydoğu Asya',
          regionId: 'southeast_asia',
          continent: ContinentFilter.asia,
        ),
        const RouteFeedFilterPill(
          id: 'city:como',
          type: RouteFilterPillType.city,
          label: 'Como',
          cityName: 'Como',
          countryCode: 'IT',
        ),
      ]);
      expect(vm.displayedPlaces.length, 2);

      // Kelime hapı AND kesişimi uygular ve Google fallback kartını etkinleştirir
      vm.applyFilterPills([
        ...vm.filterPills,
        const RouteFeedFilterPill(
          id: 'keyword:bellagio',
          type: RouteFilterPillType.keyword,
          label: '"Bellagio"',
          keyword: 'Bellagio',
        ),
      ]);
      expect(vm.searchMode, PlaceSearchMode.globalSearch);
      expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
      expect(vm.displayedPlaces.length, 1);
      expect(vm.displayedPlaces.first.id, 'place-it-bellagio');

      // Kelime hapını duraklat -> hap kalır, 2 konum eşleşmesi geri gelir
      vm.toggleFilterPill('keyword:bellagio');
      expect(vm.filterPills.length, 3);
      expect(vm.displayedPlaces.length, 2);

      // Tekil hap kaldır -> sadece Como kalır
      vm.removeFilterPill('region:southeast_asia');
      expect(vm.filterPills.length, 2);
      expect(vm.displayedPlaces.length, 1);

      // Tümünü temizle -> 6 mekan geri gelir
      vm.clearAllFilterPills();
      expect(vm.filterPills, isEmpty);
      expect(vm.displayedPlaces.length, 6);
    });

    test('GeographyStore yuklendiginde Balkanlar, ulke listeleri ve places_count DB verisinden gelir', () async {
      final mockClient = MockClient((http.Request request) async {
        if (request.url.path == '/geography/tree') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'lang': 'tr',
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
                      'places_count': 18,
                      'routes_count': 6,
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
                          'image_url':
                              'https://cdn.beenhere.dev/geo/balkans.jpg',
                          'country_codes': <String>['TR', 'HR'],
                          'country_names': <String>['Türkiye', 'Hırvatistan'],
                          'places_count': 14,
                          'routes_count': 4,
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
                          'flag_emoji': '🇹🇷',
                          'image_url': 'https://cdn.beenhere.dev/geo/tr.jpg',
                          'places_count': 10,
                          'routes_count': 3,
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
                              'image_url':
                                  'https://cdn.beenhere.dev/geo/izmir.jpg',
                              'is_popular': true,
                              'places_count': 6,
                              'routes_count': 2,
                            },
                          ],
                        },
                        <String, dynamic>{
                          'id': 'country-hr',
                          'code': 'HR',
                          'continent_code': 'EUROPE',
                          'name': 'Hırvatistan',
                          'default_name': 'Hırvatistan',
                          'name_translations': <String, String>{
                            'tr': 'Hırvatistan',
                            'en': 'Croatia',
                          },
                          'flag_emoji': '🇭🇷',
                          'image_url': 'https://cdn.beenhere.dev/geo/hr.jpg',
                          'places_count': 4,
                          'routes_count': 1,
                          'cities': <Map<String, dynamic>>[
                            <String, dynamic>{
                              'id': 'city-dubrovnik',
                              'slug': 'hr:dubrovnik',
                              'country_code': 'HR',
                              'name': 'Dubrovnik',
                              'default_name': 'Dubrovnik',
                              'name_translations': <String, String>{
                                'tr': 'Dubrovnik',
                                'en': 'Dubrovnik',
                              },
                              'image_url':
                                  'https://cdn.beenhere.dev/geo/dubrovnik.jpg',
                              'is_popular': false,
                              'places_count': 4,
                              'routes_count': 1,
                            },
                          ],
                        },
                      ],
                    },
                  ],
                  'popular_suggestions': <String, dynamic>{
                    'cities': <Map<String, dynamic>>[],
                    'regions': <Map<String, dynamic>>[],
                    'continents': <Map<String, dynamic>>[],
                  },
                },
              }),
            ),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );
      final geoService = GeographyApiService(apiClient: apiClient);
      final geoStore = GeographyStore(apiService: geoService);
      final vm = PlaceSearchViewModel(geographyStore: geoStore);

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      // Henüz yüklenmeden önce statik fallback kullanılır
      expect(vm.countItemsForContinent(ContinentFilter.europe), 5);

      await geoStore.ensureLoaded(lang: 'tr');

      expect(notifyCount, greaterThan(0));
      expect(vm.countItemsForContinent(ContinentFilter.europe), 18);

      final europeCatalog = vm.searchContinentsCatalog.singleWhere(
        (c) => c.continent == ContinentFilter.europe,
      );
      final balkansRegion = europeCatalog.regions.singleWhere(
        (r) => r.id == 'balkans',
      );
      expect(balkansRegion.name, 'Balkanlar');
      expect(vm.countItemsForRegion(balkansRegion), 14);

      final countries = vm.getCountriesForContinent(ContinentFilter.europe);
      expect(countries.map((c) => c.code), <String>['TR', 'HR']);
      expect(countries.first.publishedRouteCount, 10);
      expect(countries.last.nameTr, 'Hırvatistan');
      expect(countries.last.publishedRouteCount, 4);

      expect(vm.getCitiesForCountry('TR'), <String>['İzmir']);
      expect(vm.getCitiesForCountry('HR'), <String>['Dubrovnik']);

      final balkanSuggestions = vm.buildSearchSuggestions('Balkans');
      expect(
        balkanSuggestions.any(
          (s) =>
              s.type == RouteSearchSuggestionType.region &&
              s.title == 'Balkanlar' &&
              s.pill.regionId == 'balkans',
        ),
        isTrue,
      );

      vm.dispose();
      geoStore.dispose();
      apiClient.close();
    });
  });

  group('PlaceSearchScreen - Ortak Arama Paneli & Filtre Hapları Widget Testi', () {
    testWidgets(
      'Büyük arama çubuğu BeenHereSearchPanel açar, Mekan sayaçlarını gösterir ve hapları uygular',
      (WidgetTester tester) async {
        final placeVm = PlaceSearchViewModel();
        final homeVm = HomeFeedViewModel();

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(
              body: PlaceSearchScreen(
                viewModel: placeVm,
                homeFeedViewModel: homeVm,
              ),
            ),
          ),
        );

        expect(
          find.text('Ülke, konum veya şehir ismi ile ara...'),
          findsOneWidget,
        );

        // Büyük arama çubuğuna tıkla -> BeenHereSearchPanel açılmalı
        await tester.tap(
          find.text('Ülke, konum veya şehir ismi ile ara...'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BeenHereSearchPanel), findsOneWidget);
        expect(find.text('Arama Sonuçları'), findsOneWidget);
        expect(find.text('Kıtalar'), findsOneWidget);
        expect(find.text('5 Mekan'), findsOneWidget);

        // Popüler önerilerden "Batı Avrupa"yı seç
        await tester.tap(find.text('Batı Avrupa').first);
        await tester.pump();
        expect(find.text('Arama (1)'), findsOneWidget);

        await tester.tap(find.text('Arama (1)'));
        await tester.pumpAndSettle();

        expect(find.byType(BeenHereSearchPanel), findsNothing);
        expect(find.text('Batı Avrupa'), findsOneWidget);
        expect(placeVm.displayedPlaces.length, 1);
        expect(
          find.text('Brandenburg Kapısı & Pariser Platz'),
          findsOneWidget,
        );

        // Hap gövdesine dokun -> pasif olur, mekanlar geri gelir
        await tester.tap(find.text('Batı Avrupa'));
        await tester.pump();
        expect(placeVm.filterPills.first.isEnabled, isFalse);
        expect(placeVm.displayedPlaces.length, 6);

        // X ikonu ile hapı kaldır
        await tester.tap(
          find.byKey(const ValueKey<String>('remove_pill_region:western_europe')),
        );
        await tester.pump();
        expect(find.text('Batı Avrupa'), findsNothing);
        expect(placeVm.filterPills, isEmpty);
      },
    );
  });
}
