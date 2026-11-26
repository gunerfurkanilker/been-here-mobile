import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:been_here_mobile/data/services/geography_api_service.dart';
import 'package:been_here_mobile/data/stores/geography_store.dart';
import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/main.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/widgets/been_here_search_panel.dart';
import 'package:been_here_mobile/ui/core/widgets/geography_tree_filter_bar.dart';
import 'package:been_here_mobile/ui/features/home/view_models/home_feed_view_model.dart';
import 'package:been_here_mobile/ui/features/home/views/fullscreen_swipe_route_card.dart';
import 'package:been_here_mobile/ui/features/home/views/home_feed_screen.dart';
import 'package:been_here_mobile/ui/features/home/views/published_route_card.dart';
import 'package:been_here_mobile/ui/features/home/views/showcase_route_feed_card.dart';

void main() {
  setUp(() {
    BeenHereThemeController.instance.setDark();
  });

  group('HomeFeedViewModel - Pill Tabanlı Filtreleme Unit Testleri', () {
    test('Çoklu konum hapı OR birleşimi ve kelime hapı AND kesişimi ile çalışır', () {
      final vm = HomeFeedViewModel();
      expect(vm.itemCountUnitLabel, 'Rota');
      final totalInitial = vm.feedRoutes.length;
      expect(totalInitial, 5);

      // 1. Batı Avrupa (DE, FR, BE, NL -> Berlin/Köln/Brüksel ve Kuzey İtalya/Güney Fransa)
      vm.applyFilterPills([
        const RouteFeedFilterPill(
          id: 'region:western_europe',
          type: RouteFilterPillType.region,
          label: 'Batı Avrupa',
          regionId: 'western_europe',
          continent: ContinentFilter.europe,
        ),
      ]);
      expect(vm.feedRoutes.length, 2);

      // 2. Güneydoğu Asya (TH) eklendiğinde OR birleşimi -> 2 + 1 = 3 rota
      vm.applyFilterPills([
        const RouteFeedFilterPill(
          id: 'region:western_europe',
          type: RouteFilterPillType.region,
          label: 'Batı Avrupa',
          regionId: 'western_europe',
          continent: ContinentFilter.europe,
        ),
        const RouteFeedFilterPill(
          id: 'region:southeast_asia',
          type: RouteFilterPillType.region,
          label: 'Güneydoğu Asya',
          regionId: 'southeast_asia',
          continent: ContinentFilter.asia,
        ),
      ]);
      expect(vm.feedRoutes.length, 3);

      // 3. Kelime hapı ("Bangkok") eklendiğinde AND kesişimi -> 1 rota
      vm.applyFilterPills([
        ...vm.filterPills,
        const RouteFeedFilterPill(
          id: 'keyword:bangkok',
          type: RouteFilterPillType.keyword,
          label: '"Bangkok"',
          keyword: 'Bangkok',
        ),
      ]);
      expect(vm.feedRoutes.length, 1);
      expect(vm.feedRoutes.first.id, 'route-th-03');

      // 4. Kelime hapını duraklat (isEnabled = false) -> hap kalır, 3 rota geri gelir
      vm.toggleFilterPill('keyword:bangkok');
      expect(vm.filterPills.length, 3);
      expect(vm.filterPills.last.isEnabled, isFalse);
      expect(vm.feedRoutes.length, 3);

      // 5. Tümünü temizle -> tüm 5 rota geri gelir
      vm.clearAllFilterPills();
      expect(vm.filterPills, isEmpty);
      expect(vm.feedRoutes.length, totalInitial);
    });
  });

  group('HomeFeedScreen, GeographyTreeFilterBar & BeenHereSearchPanel Widget Testleri', () {
    testWidgets(
      '1) Büyük arama çubuğu BeenHereSearchPanel açar ve panel başlıklarını gösterir',
      (WidgetTester tester) async {
        await tester.pumpWidget(const BeenHereApp());
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GeographyTreeFilterBar), findsOneWidget);

        final searchBarFinder = find.byKey(
          const ValueKey<String>('home_routes_search_bar_tap'),
        );
        expect(searchBarFinder, findsOneWidget);
        expect(
          find.text('Ülke, konum veya şehir ismi ile ara...'),
          findsOneWidget,
        );

        await tester.tap(searchBarFinder);
        await tester.pumpAndSettle();

        expect(find.byType(BeenHereSearchPanel), findsOneWidget);
        expect(find.text('Arama Sonuçları'), findsOneWidget);
        expect(find.text('Kıtalar'), findsOneWidget);
        expect(find.text('Avrupa'), findsWidgets);
        expect(find.text('Asya'), findsOneWidget);
        expect(find.text('Kuzey Amerika'), findsOneWidget);
        expect(find.text('Güney Amerika'), findsOneWidget);
        expect(find.text('Tümünü Temizle'), findsOneWidget);
        expect(find.text('Arama'), findsOneWidget);
      },
    );

    testWidgets(
      '2) Arama kutusuna yazı yazıldığında kelime, şehir/ülke ve kıta/bölge önerileri dinamik listelenir',
      (WidgetTester tester) async {
        final vm = HomeFeedViewModel();
        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: HomeFeedScreen(viewModel: vm)),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('home_routes_search_bar_tap')),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // "mar" yaz -> "mar ile arama yap", "Marmaris" ("Avrupa - Türkiye")
        await tester.enterText(textField, 'mar');
        await tester.pump();

        expect(find.text('mar ile arama yap'), findsOneWidget);
        expect(find.text('(kelime ile arama)'), findsOneWidget);
        expect(find.text('Marmaris'), findsOneWidget);
        expect(find.text('Avrupa - Türkiye'), findsOneWidget);

        // "mad" yaz -> "Madrid" ("Avrupa - İspanya")
        await tester.enterText(textField, 'mad');
        await tester.pump();
        expect(find.text('mad ile arama yap'), findsOneWidget);
        expect(find.text('Madrid'), findsOneWidget);
        expect(find.text('Avrupa - İspanya'), findsOneWidget);

        // "avrupa" yaz -> Kıta ve alt bölge önerileri
        await tester.enterText(textField, 'avrupa');
        await tester.pump();
        expect(find.text('avrupa ile arama yap'), findsOneWidget);
        expect(find.text('Batı Avrupa'), findsWidgets);
        expect(find.text('Avrupa - Bölge'), findsWidgets);
      },
    );

    testWidgets(
      '3-6) Kıta/Bölge seçimi, Arama ile hap oluşturma, hap toggle, X ile kaldırma ve Tümünü Temizle akışı',
      (WidgetTester tester) async {
        final vm = HomeFeedViewModel();
        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: HomeFeedScreen(viewModel: vm)),
          ),
        );

        expect(vm.feedRoutes.length, 5);

        // Arama panelini aç
        await tester.tap(
          find.byKey(const ValueKey<String>('home_routes_search_bar_tap')),
        );
        await tester.pumpAndSettle();

        final verticalScrollable = find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('been_here_search_panel_scroll'),
              ),
              matching: find.byType(Scrollable),
            )
            .first;

        // "Batı Avrupa" bölge kartını görünür alana kaydırıp tıkla
        await tester.scrollUntilVisible(
          find.text('Batı Avrupa').last,
          200,
          scrollable: verticalScrollable,
        );
        await tester.tap(find.text('Batı Avrupa').last);
        await tester.pump();
        expect(find.text('Arama (1)'), findsOneWidget);

        // Panel içinde "Tümünü Temizle" -> seçimleri sıfırlamalı
        await tester.tap(find.text('Tümünü Temizle'));
        await tester.pump();
        expect(find.text('Arama'), findsOneWidget);

        // Şimdi "Güneydoğu Asya" bölgesini seç (Asya kartını görünür alana kaydırıp seçelim)
        await tester.scrollUntilVisible(
          find.text('Güneydoğu Asya'),
          250,
          scrollable: verticalScrollable,
        );
        await tester.tap(find.text('Güneydoğu Asya'));
        await tester.pump();

        // Ayrıca "Batı Avrupa"yı da yukarı kaydırarak seçelim
        await tester.scrollUntilVisible(
          find.text('Batı Avrupa').last,
          -250,
          scrollable: verticalScrollable,
        );
        await tester.tap(find.text('Batı Avrupa').last);
        await tester.pump();
        expect(find.text('Arama (2)'), findsOneWidget);

        // "Arama (2)" butonuna basarak ana akışa dön
        await tester.tap(find.text('Arama (2)'));
        await tester.pumpAndSettle();

        expect(find.byType(HomeFeedScreen), findsOneWidget);

        // 3) Arama çubuğunun hemen altında filtre hapları görünmeli ve rotalar filtrelenmeli
        expect(find.text('Güneydoğu Asya'), findsOneWidget);
        expect(find.text('Batı Avrupa'), findsOneWidget);
        expect(vm.feedRoutes.length, 3);
        expect(
          find.text('Berlin, Köln ve Brüksel: Sanat, Tren & Sokak Lezzetleri'),
          findsOneWidget,
        );
        expect(vm.feedRoutes.any((r) => r.id == 'route-th-03'), isTrue);

        // 4) "Batı Avrupa" hapının gövdesine dokun -> isEnabled false olmalı, hap görünür kalmalı
        await tester.tap(find.text('Batı Avrupa'));
        await tester.pump();
        expect(find.text('Batı Avrupa'), findsOneWidget);
        expect(vm.filterPills.firstWhere((p) => p.label == 'Batı Avrupa').isEnabled, isFalse);
        // Sadece Güneydoğu Asya aktif kaldığı için 1 rota (Bangkok) görünmeli
        expect(vm.feedRoutes.length, 1);
        expect(
          find.text('Bangkok Tapınakları, Chiang Mai Ormanları & Phuket Koylari'),
          findsOneWidget,
        );

        // Tekrar "Batı Avrupa" hapına dokun -> isEnabled true olmalı, 3 rota geri gelmeli
        await tester.tap(find.text('Batı Avrupa'));
        await tester.pump();
        expect(vm.filterPills.firstWhere((p) => p.label == 'Batı Avrupa').isEnabled, isTrue);
        expect(vm.feedRoutes.length, 3);

        // 5) "Güneydoğu Asya" hapının X ikonuna bas -> hap tamamen silinmeli
        await tester.tap(
          find.byKey(const ValueKey<String>('remove_pill_region:southeast_asia')),
        );
        await tester.pump();
        expect(find.text('Güneydoğu Asya'), findsNothing);
        expect(find.text('Batı Avrupa'), findsOneWidget);
        expect(vm.feedRoutes.length, 2);

        // 6) "Tümünü Temizle" hapına bas -> tüm haplar temizlenmeli ve tüm 5 rota görünmeli
        await tester.tap(find.text('Tümünü Temizle'));
        await tester.pump();
        expect(find.text('Batı Avrupa'), findsNothing);
        expect(find.text('Tümünü Temizle'), findsNothing);
        expect(vm.feedRoutes.length, 5);
      },
    );

    testWidgets(
      'Arama panelinde geri okuna basıldığında önceki uygulanmış filtreler korunur',
      (WidgetTester tester) async {
        final vm = HomeFeedViewModel();
        vm.applyFilterPills([
          const RouteFeedFilterPill(
            id: 'continent:ASIA',
            type: RouteFilterPillType.continent,
            label: 'Asya',
            continent: ContinentFilter.asia,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: HomeFeedScreen(viewModel: vm)),
          ),
        );

        expect(find.text('Asya'), findsOneWidget);
        expect(vm.feedRoutes.length, 1);

        // Paneli aç, "Tümünü Temizle"ye bas ama "Arama" yerine geri okuna bas
        await tester.tap(
          find.byKey(const ValueKey<String>('home_routes_search_bar_tap')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tümünü Temizle'));
        await tester.pump();
        await tester.tap(find.byTooltip('Geri'));
        await tester.pumpAndSettle();

        // Önceki Asya filtresi korunmuş olmalı
        expect(find.text('Asya'), findsOneWidget);
        expect(vm.feedRoutes.length, 1);
      },
    );
  });

  group('HomeFeedViewModel - GeographyStore DB Entegrasyonu', () {
    GeographyStore buildTestGeographyStore() {
      final payload = <String, dynamic>{
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
            'routes_count': 42,
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
                'country_codes': <String>['TR', 'HR'],
                'country_names': <String>['Türkiye', 'Hırvatistan'],
                'places_count': 9,
                'routes_count': 12,
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
                'aliases': <String>['Turkiye'],
                'flag_emoji': '🇹🇷',
                'image_url': 'https://cdn.beenhere.dev/geo/tr.jpg',
                'places_count': 5,
                'routes_count': 7,
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
                    'places_count': 3,
                    'routes_count': 4,
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
                'places_count': 4,
                'routes_count': 9,
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
                    'places_count': 4,
                    'routes_count': 6,
                  },
                ],
              },
            ],
          },
        ],
      };

      final client = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{'success': true, 'data': payload}),
          ),
          200,
          headers: const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      );
      return GeographyStore(
        apiService: GeographyApiService(
          apiClient: BeenHereApiClient(
            baseUrl: 'https://api.beenhere.test',
            client: client,
          ),
        ),
      );
    }

    test('Yüklü GeographyStore üzerinden Balkanlar ve çoklu dil önerilerini kullanır', () async {
      final store = buildTestGeographyStore();
      final vm = HomeFeedViewModel(geographyStore: store);

      var notifiedCount = 0;
      vm.addListener(() => notifiedCount++);

      // Yükleme öncesi statik fallback çalışır
      expect(
        vm.searchContinentsCatalog.first.regions.any((r) => r.id == 'balkans'),
        isFalse,
      );

      await store.ensureLoaded(lang: 'tr');

      // Store güncellendiğinde ViewModel dinleyicilerini uyarmalıdır
      expect(notifiedCount, greaterThan(0));

      // DB kataloğundaki Balkanlar bölgesi gelmeli
      final europe = vm.searchContinentsCatalog.firstWhere(
        (c) => c.continent == ContinentFilter.europe,
      );
      final balkansRegion = europe.regions.firstWhere((r) => r.id == 'balkans');
      expect(balkansRegion.name, 'Balkanlar');

      // Kıta ve bölge rota sayıları DB'den (routes_count) gelmeli
      expect(vm.countItemsForContinent(ContinentFilter.europe), 42);
      expect(vm.countItemsForRegion(balkansRegion), 12);

      // Ülke ve şehir listeleri DB'den (useRoutesCount: true) gelmeli
      final countries = vm.getCountriesForContinent(ContinentFilter.europe);
      final italy = countries.firstWhere((c) => c.code == 'IT');
      expect(italy.publishedRouteCount, 9);
      expect(vm.getCitiesForCountry('IT'), ['Roma']);

      // Çoklu dil aramasında "Balkans" -> "Balkanlar", "Rome" -> "Roma" önerisi gelmeli
      final balkansSuggestions = vm.buildSearchSuggestions('Balkans');
      expect(
        balkansSuggestions.any(
          (s) => s.type == RouteSearchSuggestionType.region && s.title == 'Balkanlar',
        ),
        isTrue,
      );

      final romeSuggestions = vm.buildSearchSuggestions('Rome');
      expect(
        romeSuggestions.any(
          (s) => s.type == RouteSearchSuggestionType.city && s.title == 'Roma',
        ),
        isTrue,
      );

      vm.dispose();
      store.dispose();
    });

    testWidgets(
      'BeenHereSearchPanel kalabalık popüler önerilerde maksimum yükseklikle kaydırılır ve Kıtalar görünür kalır',
      (WidgetTester tester) async {
        final popularCities = <Map<String, dynamic>>[
          for (var i = 1; i <= 12; i++)
            <String, dynamic>{
              'id': 'pop-city-$i',
              'slug': 'it:pop-sehir-$i',
              'country_code': 'IT',
              'name': 'Popüler Şehir $i',
              'default_name': 'Popüler Şehir $i',
              'name_translations': <String, String>{
                'tr': 'Popüler Şehir $i',
                'en': 'Popular City $i',
              },
              'image_url': 'https://cdn.beenhere.dev/geo/pop-$i.jpg',
              'is_popular': true,
              'places_count': 5,
              'routes_count': 2,
            },
        ];

        final payload = <String, dynamic>{
          'lang': 'tr',
          'continents': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'cont-eu',
              'code': 'EUROPE',
              'name': 'Avrupa',
              'default_name': 'Avrupa',
              'name_translations': <String, String>{
                'tr': 'Avrupa',
                'en': 'Europe',
              },
              'image_url': 'https://cdn.beenhere.dev/geo/eu.jpg',
              'places_count': 20,
              'routes_count': 10,
              'regions': <Map<String, dynamic>>[],
              'countries': <Map<String, dynamic>>[
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
                  'aliases': <String>['Italy'],
                  'flag_emoji': '🇮🇹',
                  'image_url': 'https://cdn.beenhere.dev/geo/it.jpg',
                  'places_count': 20,
                  'routes_count': 10,
                  'cities': popularCities,
                },
              ],
            },
          ],
          'popular_suggestions': <String, dynamic>{
            'cities': popularCities,
            'regions': const <Map<String, dynamic>>[],
            'continents': const <Map<String, dynamic>>[],
          },
        };

        final client = MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{'success': true, 'data': payload}),
            ),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          ),
        );
        final store = GeographyStore(
          apiService: GeographyApiService(
            apiClient: BeenHereApiClient(
              baseUrl: 'https://api.beenhere.test',
              client: client,
            ),
          ),
        );
        await store.ensureLoaded(lang: 'tr');

        final vm = HomeFeedViewModel(geographyStore: store);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: BeenHereSearchPanel(controller: vm),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Popüler Öneriler'), findsOneWidget);
        expect(find.text('Kıtalar'), findsOneWidget);

        final suggestionsScrollFinder = find.byKey(
          const ValueKey<String>('been_here_search_suggestions_scroll'),
        );
        expect(suggestionsScrollFinder, findsOneWidget);

        // Öneriler kutusunun yüksekliği 256px sınırını aşmamalı ve Kıtalar ekran içinde görünür kalmalı
        final scrollRect = tester.getRect(suggestionsScrollFinder);
        expect(scrollRect.height, lessThanOrEqualTo(256.0));
        final continentsRect = tester.getRect(find.text('Kıtalar'));
        expect(
          continentsRect.bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height / tester.view.devicePixelRatio),
        );

        // Öneriler kutusu kendi içinde kaydırılabilmeli -> son öğe görünür hale getirilebilmeli
        final innerScrollable = find.descendant(
          of: suggestionsScrollFinder,
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Popüler Şehir 12'),
          120,
          scrollable: innerScrollable,
        );
        expect(find.text('Popüler Şehir 12'), findsOneWidget);

        vm.dispose();
        store.dispose();
      },
    );

    testWidgets(
      'BeenHereSearchPanel tekil text hapı kuralını uygular, coğrafi hapları korur ve yazarken /geography/search isteği atmaz',
      (WidgetTester tester) async {
        var geographySearchCalls = 0;
        final payload = <String, dynamic>{
          'lang': 'tr',
          'continents': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'cont-eu',
              'code': 'EUROPE',
              'name': 'Avrupa',
              'default_name': 'Avrupa',
              'name_translations': <String, String>{
                'tr': 'Avrupa',
                'en': 'Europe',
              },
              'image_url': 'https://cdn.beenhere.dev/geo/eu.jpg',
              'places_count': 10,
              'routes_count': 5,
              'regions': <Map<String, dynamic>>[],
              'countries': <Map<String, dynamic>>[
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
                  'aliases': <String>['Italy'],
                  'flag_emoji': '🇮🇹',
                  'image_url': 'https://cdn.beenhere.dev/geo/it.jpg',
                  'places_count': 10,
                  'routes_count': 5,
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
                      'places_count': 6,
                      'routes_count': 3,
                    },
                  ],
                },
              ],
            },
          ],
          'popular_suggestions': <String, dynamic>{
            'cities': const <Map<String, dynamic>>[],
            'regions': const <Map<String, dynamic>>[],
            'continents': const <Map<String, dynamic>>[],
          },
        };

        final client = MockClient((request) async {
          if (request.url.path == '/geography/search') {
            geographySearchCalls++;
            return http.Response.bytes(
              utf8.encode(
                jsonEncode(<String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'lang': 'tr',
                    'query': request.url.queryParameters['q'] ?? '',
                    'results': const <Map<String, dynamic>>[],
                  },
                }),
              ),
              200,
              headers: const <String, String>{
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{'success': true, 'data': payload}),
            ),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });
        final store = GeographyStore(
          apiService: GeographyApiService(
            apiClient: BeenHereApiClient(
              baseUrl: 'https://api.beenhere.test',
              client: client,
            ),
          ),
        );
        await store.ensureLoaded(lang: 'tr');

        final vm = HomeFeedViewModel(geographyStore: store);
        vm.applyFilterPills([
          const RouteFeedFilterPill(
            id: 'country:IT',
            type: RouteFilterPillType.country,
            label: 'İtalya',
            countryCode: 'IT',
          ),
        ]);

        // 1) Panel açılıp serbest metin "Büyük Kanyon" yazılıp Arama'ya basılır
        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BeenHereSearchPanel(controller: vm),
                        ),
                      );
                    },
                    child: const Text('Panel Aç'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Panel Aç'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Büyük Kanyon');
        await tester.pump(const Duration(milliseconds: 350));
        expect(geographySearchCalls, 0);

        final searchActionButton = find.descendant(
          of: find.byType(FilledButton),
          matching: find.textContaining('Arama'),
        );
        await tester.tap(searchActionButton);
        await tester.pumpAndSettle();

        expect(
          vm.filterPills.map((p) => '${p.type.name}:${p.label}').toList(),
          <String>['country:İtalya', 'keyword:"Büyük Kanyon"'],
        );

        // 2) Panel tekrar açılıp serbest metin "Saat Kulesi" yazılıp Arama'ya basılır -> Büyük Kanyon yerine Saat Kulesi geçer
        await tester.tap(find.text('Panel Aç'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Saat Kulesi');
        await tester.pump(const Duration(milliseconds: 350));
        expect(geographySearchCalls, 0);

        await tester.tap(searchActionButton);
        await tester.pumpAndSettle();

        expect(
          vm.filterPills.map((p) => '${p.type.name}:${p.label}').toList(),
          <String>['country:İtalya', 'keyword:"Saat Kulesi"'],
        );

        // 3) Panel tekrar açılıp "Galata" öneri satırına tıklanıp Arama'ya basılır -> Saat Kulesi yerine Galata geçer, İtalya korunur
        await tester.tap(find.text('Panel Aç'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Galata');
        await tester.pump(const Duration(milliseconds: 350));
        expect(geographySearchCalls, 0);

        await tester.tap(find.text('Galata ile arama yap'));
        await tester.pump();
        await tester.tap(searchActionButton);
        await tester.pumpAndSettle();

        expect(
          vm.filterPills.map((p) => '${p.type.name}:${p.label}').toList(),
          <String>['country:İtalya', 'keyword:"Galata"'],
        );
        expect(geographySearchCalls, 0);

        // Doğrudan triggerRemoteGeographySearch çağrısı da yüklü store varken ağ isteği atmamalı
        await vm.triggerRemoteGeographySearch('Beyoğlu');
        expect(geographySearchCalls, 0);

        vm.dispose();
        store.dispose();
      },
    );
  });

  group('ShowcaseRouteFeedCard & Korunan Kart Tasarımları Widget Testleri', () {
    testWidgets(
      'ShowcaseRouteFeedCard 375px ve 468px genişliklerde Dark & Light temada taşma olmadan çalışır ve eski kartlar korunur',
      (WidgetTester tester) async {
        final vm = HomeFeedViewModel();
        final firstRoute = vm.feedRoutes.first;
        var tappedCount = 0;

        for (final width in <double>[375.0, 468.0]) {
          tester.view.physicalSize = Size(width, 844.0);
          tester.view.devicePixelRatio = 1.0;

          for (final isDark in <bool>[true, false]) {
            if (isDark) {
              BeenHereThemeController.instance.setDark();
            } else {
              BeenHereThemeController.instance.setLight();
            }

            await tester.pumpWidget(
              MaterialApp(
                theme: isDark
                    ? BeenHereTheme.darkTheme
                    : BeenHereTheme.lightTheme,
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: width - 32,
                      height: 510,
                      child: ShowcaseRouteFeedCard(
                        route: firstRoute,
                        onTapCard: () => tappedCount++,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.text('\$680'), findsOneWidget);
            expect(find.text('5 Gün'), findsOneWidget);
            final cardShellFinder = find.byKey(
              ValueKey<String>('showcase-card-shell-${firstRoute.id}'),
            );
            expect(cardShellFinder, findsOneWidget);
            final shellContainer = tester.widget<Container>(cardShellFinder);
            final shapeDeco = shellContainer.decoration! as ShapeDecoration;
            expect(shapeDeco.color, isNull);
            expect(shapeDeco.gradient, isA<LinearGradient>());
            final bgGradient = shapeDeco.gradient! as LinearGradient;
            expect(bgGradient.begin, Alignment.topLeft);
            expect(bgGradient.end, Alignment.bottomRight);
            expect(bgGradient.colors.length, 3);

            expect(shapeDeco.shape, isA<CurvedBottomShowcaseCardBorder>());
            final cardBorder =
                shapeDeco.shape as CurvedBottomShowcaseCardBorder;
            expect(cardBorder.side.width, closeTo(1.2, 0.05));
            expect(cardBorder.borderGradient, isA<LinearGradient>());
            final borderGrad = cardBorder.borderGradient! as LinearGradient;
            expect(borderGrad.colors.length, 3);
            expect(
              shapeDeco.shadows!.first.color.a,
              closeTo(isDark ? 0.16 : 0.08, 0.01),
            );

            // Hem durak bilgisi hem de gezi başlığı ve gezgin adı aynı bombeli kartın içinde yer almalı
            expect(
              find.descendant(
                of: cardShellFinder,
                matching: find.text('Amintas Kaya Mezarları'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: cardShellFinder,
                matching: find.text('Türkiye, Fethiye'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: cardShellFinder,
                matching: find.text('Marmaris Turu'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: cardShellFinder,
                matching: find.text('Furkan Güner'),
              ),
              findsOneWidget,
            );

            // Sola ve sağa kaydırmada precisionErrorTolerance veya overflow hatası olmamalı
            final pageViewFinder = find.byKey(
              ValueKey<String>('showcase-stops-pageview-${firstRoute.id}'),
            );
            await tester.drag(pageViewFinder, const Offset(-240, 0));
            await tester.pumpAndSettle();
            expect(find.text('Yuvarlakçay'), findsOneWidget);
            expect(find.text('Türkiye, Köyceğiz'), findsOneWidget);

            await tester.drag(pageViewFinder, const Offset(240, 0));
            await tester.pumpAndSettle();
            expect(find.text('Amintas Kaya Mezarları'), findsOneWidget);
          }
        }

        // Başlığa tıklanınca onTapCard tetiklenmeli
        await tester.tap(find.text('Marmaris Turu'));
        await tester.pump();
        expect(tappedCount, greaterThan(0));

        // Eski FullscreenSwipeRouteCard ve PublishedRouteCard bileşenlerinin korunduğunu doğrula
        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 510,
                      child: FullscreenSwipeRouteCard(
                        route: firstRoute,
                        onTapCard: () {},
                      ),
                    ),
                    PublishedRouteCard(
                      route: firstRoute,
                      onTapCard: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(FullscreenSwipeRouteCard), findsOneWidget);
        expect(find.byType(PublishedRouteCard), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          BeenHereThemeController.instance.setDark();
        });
        vm.dispose();
      },
    );
  });
}
