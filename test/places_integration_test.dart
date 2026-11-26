import 'dart:convert';

import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:been_here_mobile/data/services/geography_api_service.dart';
import 'package:been_here_mobile/data/services/places_api_service.dart';
import 'package:been_here_mobile/data/stores/geography_store.dart';
import 'package:been_here_mobile/data/stores/places_store.dart';
import 'package:been_here_mobile/domain/models/place_discovery_models.dart';
import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/widgets/been_here_search_panel.dart';
import 'package:been_here_mobile/ui/features/home/view_models/home_feed_view_model.dart';
import 'package:been_here_mobile/ui/features/search/view_models/place_search_view_model.dart';
import 'package:been_here_mobile/ui/features/search/views/place_discovery_card.dart';
import 'package:been_here_mobile/ui/features/search/views/place_discovery_compact_card.dart';
import 'package:been_here_mobile/ui/features/search/views/place_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

http.Response _envelopeResponse(dynamic data, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode(<String, dynamic>{
        'success': true,
        'data': data,
        'timestamp': '2026-11-13T15:00:00.000Z',
      }),
    ),
    statusCode,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

http.Response _errorEnvelopeResponse({
  required int statusCode,
  required String path,
  required Object message,
}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode(<String, dynamic>{
        'success': false,
        'statusCode': statusCode,
        'timestamp': '2026-11-13T15:00:00.000Z',
        'path': path,
        'message': message,
      }),
    ),
    statusCode,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Map<String, dynamic> _buildPlaceJson({
  required String id,
  String? name,
  Map<String, String>? nameTranslations,
  String shortSummary = 'Antik taş yapılar ve panoramik gün batımı manzarası.',
  String? continent = 'EUROPE',
  String countryCode = 'TR',
  String? countryName = 'Türkiye',
  String city = 'İzmir',
  String uiCategory = 'DESTINATION',
  String? categoryLabel = 'Gezilecek Yer',
  Object averageRating = '4.85',
  int verifiedVisitCount = 42,
  double? distanceKm = 1.8,
  List<String> photoUrls = const <String>[],
  List<String>? photoAuthors,
  List<Map<String, dynamic>>? mediaGallery,
  Object communityVibes = const <String, int>{
    'Gün Batımı': 9,
    'Fotoğraflık': 6,
    'Sakin': 2,
  },
  Object? communityWarnings,
  String status = 'OPERATIONAL',
  Map<String, dynamic>? openingHours,
  List<String> relatedRouteIds = const <String>['route-1'],
  bool? isFlagged,
  List<String> flaggedInListIds = const <String>[],
  bool isFromGoogleFallback = false,
}) {
  return <String, dynamic>{
    'id': id,
    'name': ?name,
    'name_translations': ?nameTranslations,
    'short_summary': shortSummary,
    'continent': ?continent,
    'country_code': countryCode,
    'country_name': ?countryName,
    'city': city,
    'ui_category': uiCategory,
    'category_label': ?categoryLabel,
    'average_rating': averageRating,
    'verified_visit_count': verifiedVisitCount,
    'distance_km': ?distanceKm,
    'photo_urls': photoUrls,
    'photo_authors': ?photoAuthors,
    'media_gallery': ?mediaGallery,
    'community_vibes': communityVibes,
    'community_warnings': ?communityWarnings,
    'status': status,
    'opening_hours': ?openingHours,
    'related_route_ids': relatedRouteIds,
    'is_flagged': ?isFlagged,
    'flagged_in_list_ids': flaggedInListIds,
    'is_from_google_fallback': isFromGoogleFallback,
  };
}

Map<String, dynamic> _buildRouteJson({
  required String id,
  required String title,
  String description = 'Ege kıyılarında 4 günlük kültür ve gastronomi rotası.',
  String authorUsername = 'selin_yolda',
  String authorDisplayName = 'Selin Kaya',
  String authorRankLabel = 'Bölge Kaşifi',
  String continent = 'EUROPE',
  List<String> countryCodes = const <String>['TR'],
  List<String> countryNames = const <String>['Türkiye'],
  List<String> cities = const <String>['İzmir', 'Muğla'],
  List<String> featuredMediaUrls = const <String>[],
  List<String> previewPlaceNames = const <String>['Efes Antik Kenti'],
  String dateRangeText = '12 - 15 Mayıs 2026',
  int adultsCount = 2,
  int childrenCount = 0,
  int durationDays = 4,
  double estimatedTotalBudgetUsd = 480,
  double estimatedTotalBudget = 16500,
  String currency = 'TRY',
  int forkCount = 14,
  int totalStopsCount = 6,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'author': <String, dynamic>{
      'username': authorUsername,
      'display_name': authorDisplayName,
      'rank_label': authorRankLabel,
    },
    'continent': continent,
    'country_codes': countryCodes,
    'country_names': countryNames,
    'cities': cities,
    'featured_media_urls': featuredMediaUrls,
    'preview_place_names': previewPlaceNames,
    'date_range_text': dateRangeText,
    'adults_count': adultsCount,
    'children_count': childrenCount,
    'duration_days': durationDays,
    'estimated_total_budget_usd': estimatedTotalBudgetUsd,
    'estimated_total_budget': estimatedTotalBudget,
    'currency': currency,
    'budget_breakdown': <String, dynamic>{
      'Konaklama': 8000,
      'Yeme-İçme': 5500,
    },
    'fork_count': forkCount,
    'is_boosted': true,
    'is_qa_enabled': true,
    'total_stops_count': totalStopsCount,
    'stops': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'stop-1',
        'order_index': 0,
        'day_number': 1,
        'place_name': 'Efes Antik Kenti',
        'city': 'İzmir',
        'ui_category': 'DESTINATION',
        'verification_type': 'GEO_VERIFIED',
        'rating': 5,
        'comment': 'Sabah erken gitmek çok rahat.',
        'vibes': <String>['Tarihi'],
        'warnings': <String>[],
        'photo_urls': <String>[],
      },
    ],
    'stays': <Map<String, dynamic>>[
      <String, dynamic>{
        'stay_type_label': 'Butik Otel',
        'region_or_hotel_name': 'Şirince Taş Konak',
        'nights_count': 2,
      },
    ],
    'questions': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'q-1',
        'asker_username': 'mert_ege',
        'question_text': 'Müze kart geçiyor mu?',
        'created_at_label': '2 gün önce',
        'answer_text': 'Evet, girişte doğrudan okutabilirsiniz.',
      },
    ],
  };
}

void main() {
  setUp(() {
    BeenHereThemeController.instance.setDark();
  });

  // ===========================================================================
  // 1. MODEL JSON SERIALIZATION TESTLERİ
  // ===========================================================================
  group('1. Model JSON Serialization (PlaceDiscoveryItem, UserFavoritePlaceList, PublishedRouteFeedItem)', () {
    test('PlaceDiscoveryItem.fromJson backend yuklerini, uyarilari, medyayi ve bayraklari dogru ayristirir', () {
      final json = _buildPlaceJson(
        id: 'place-efes-1',
        name: null,
        nameTranslations: const <String, String>{
          'en': 'Ephesus Ancient City',
          'tr': 'Efes Antik Kenti',
        },
        averageRating: '4.85',
        verifiedVisitCount: 128,
        distanceKm: 3.45,
        photoUrls: const <String>[],
        photoAuthors: const <String>['', 'Kaan Demir (@kaan_geziyor)'],
        mediaGallery: const <Map<String, dynamic>>[
          <String, dynamic>{
            'url': 'https://cdn.example.invalid/efes-1.jpg',
            'author_display_name': 'Selin Kaya',
            'author_username': 'selin_yolda',
          },
          <String, dynamic>{
            'url': 'https://cdn.example.invalid/efes-2.jpg',
            'author_display_name': 'Ignored Name',
            'author_username': 'ignored',
          },
          <String, dynamic>{
            'url': 'https://cdn.example.invalid/efes-3.jpg',
          },
          <String, dynamic>{
            'url': 'https://cdn.example.invalid/efes-4.jpg',
          },
        ],
        communityVibes: const <String, int>{
          'Sakin': 2,
          'Gün Batımı': 11,
          'Manzaralı': 7,
          'Sıfır Oy': 0,
        },
        status: 'CLOSED_TEMPORARILY',
        openingHours: const <String, dynamic>{
          'closed_days': <String>['Pazartesi'],
        },
        communityWarnings: const <String, int>{
          'Nakit Gerekli': 3,
          'Bilet Kuyruğu Uzun': 8,
          'Boş Uyarı': 0,
        },
        flaggedInListIds: const <String>['list-ege'],
      );

      final item = PlaceDiscoveryItem.fromJson(json);

      expect(item.id, 'place-efes-1');
      expect(item.name, 'Efes Antik Kenti');
      expect(item.averageRating, closeTo(4.85, 0.001));
      expect(item.verifiedVisitCount, 128);
      expect(item.distanceKmFromUser, closeTo(3.45, 0.001));
      expect(item.continent, ContinentFilter.europe);
      expect(item.countryName, 'Türkiye');

      // media_gallery URL fallback + cappedPhotos(3) + photo_authors merge
      expect(item.photoUrls, hasLength(4));
      expect(item.cappedPhotos, hasLength(3));
      expect(item.photoAuthors, <String>[
        'Selin Kaya (@selin_yolda)',
        'Kaan Demir (@kaan_geziyor)',
      ]);
      expect(item.photoAuthorForIndex(0), 'Selin Kaya (@selin_yolda)');
      expect(item.photoAuthorForIndex(1), 'Kaan Demir (@kaan_geziyor)');

      // community_vibes map -> oylara göre sıralı ve 0 oylu kalem filtrelenmiş (len > 3)
      expect(item.communityVibes, <String>['Gün Batımı', 'Manzaralı', 'Sakin']);
      expect(item.communityVibeCounts, <String, int>{
        'Sakin': 2,
        'Gün Batımı': 11,
        'Manzaralı': 7,
        'Sıfır Oy': 0,
      });

      // status + opening_hours + community_warnings
      expect(item.isClosed, isTrue);
      expect(item.statusWarning, 'Efes Antik Kenti geçici olarak kapalıdır.');
      expect(
        item.openingHoursWarning,
        'Efes Antik Kenti Pazartesi günleri kapalıdır.',
      );
      expect(item.communityWarningBadges, hasLength(2));
      expect(item.communityWarningBadges[0].label, 'Bilet Kuyruğu Uzun');
      expect(item.communityWarningBadges[0].votes, 8);
      expect(item.communityWarningBadges[1].label, 'Nakit Gerekli');
      expect(item.communityWarningBadges[1].votes, 3);
      expect(
        item.warnings,
        containsAllInOrder(<String>[
          'Efes Antik Kenti geçici olarak kapalıdır.',
          'Efes Antik Kenti Pazartesi günleri kapalıdır.',
          'Gezgin Saha Uyarısı: Bilet Kuyruğu Uzun (8 oy), Nakit Gerekli (3 oy)',
        ]),
      );

      // is_flagged key'i yoksa flagged_in_list_ids üzerinden otomatik true olur
      expect(item.isFlagged, isTrue);
      expect(item.flaggedInListIds, <String>['list-ege']);
    });

    test('mergeRawPlaceJson zenginlestirilmis alanlari korur ve guncel vibe/uyari/durum verisini isler', () {
      final enriched = PlaceDiscoveryItem.fromJson(
        _buildPlaceJson(
          id: 'place-galata',
          name: 'Galata Kulesi',
          continent: 'EUROPE',
          countryCode: 'TR',
          countryName: 'Türkiye',
          city: 'İstanbul',
          distanceKm: 2.6,
          photoAuthors: const <String>['Zeynep Arslan (@zeynep_kesifte)'],
          communityVibes: const <String, int>{'Gün Batımı': 4},
          communityWarnings: const <String, int>{'Bilet Kuyruğu Uzun': 2},
          relatedRouteIds: const <String>['route-istanbul-1', 'route-istanbul-2'],
          isFlagged: true,
          flaggedInListIds: const <String>['list-kultur'],
          isFromGoogleFallback: true,
        ),
      );

      final rawMutationResponse = <String, dynamic>{
        'id': 'place-galata',
        'name': 'Galata Kulesi',
        'short_summary': 'Güncel özet metni.',
        'country_code': 'TR',
        'city': 'İstanbul',
        'ui_category': 'DESTINATION',
        'average_rating': '4.90',
        'verified_visit_count': 210,
        'status': 'CLOSED_TEMPORARILY',
        'opening_hours': const <String, dynamic>{
          'closed_days': <String>['Salı'],
        },
        'community_vibes': const <String, int>{
          'Fotoğraflık': 14,
          'Gün Batımı': 8,
        },
        'community_warnings': const <String, int>{
          'Rezervasyon Şart': 6,
          'Bilet Kuyruğu Uzun': 2,
        },
      };

      final merged = enriched.mergeRawPlaceJson(rawMutationResponse);

      // Zenginleştirilmiş alanlar korunmalı
      expect(merged.continent, ContinentFilter.europe);
      expect(merged.countryName, 'Türkiye');
      expect(merged.distanceKmFromUser, closeTo(2.6, 0.001));
      expect(merged.isFlagged, isTrue);
      expect(merged.flaggedInListIds, <String>['list-kultur']);
      expect(merged.relatedRouteIds, <String>['route-istanbul-1', 'route-istanbul-2']);
      expect(merged.photoAuthors, <String>['Zeynep Arslan (@zeynep_kesifte)']);
      expect(merged.categoryLabel, 'Gezilecek Yer');
      expect(merged.isFromGoogleFallback, isTrue);

      // Güncellenmiş ham alanlar yansımalı
      expect(merged.shortSummary, 'Güncel özet metni.');
      expect(merged.averageRating, closeTo(4.9, 0.001));
      expect(merged.verifiedVisitCount, 210);
      expect(merged.communityVibes, <String>['Fotoğraflık', 'Gün Batımı']);
      expect(merged.communityVibeCounts, <String, int>{
        'Fotoğraflık': 14,
        'Gün Batımı': 8,
      });
      expect(merged.isClosed, isTrue);
      expect(merged.statusWarning, 'Galata Kulesi geçici olarak kapalıdır.');
      expect(merged.openingHoursWarning, 'Galata Kulesi Salı günleri kapalıdır.');
      expect(merged.communityWarningBadges.first.label, 'Rezervasyon Şart');
      expect(merged.communityWarningBadges.first.votes, 6);
    });

    test('PlaceDiscoveryItem.toJson round-trip tutarliligini korur', () {
      final original = PlaceDiscoveryItem.fromJson(
        _buildPlaceJson(
          id: 'place-roundtrip',
          name: 'Kapadokya Göreme',
          continent: 'ASIA',
          countryCode: 'TR',
          countryName: 'Türkiye',
          city: 'Nevşehir',
          uiCategory: 'ACTIVITY',
          categoryLabel: 'Aktivite & Deneyim',
          averageRating: '4.92',
          verifiedVisitCount: 89,
          distanceKm: 12.4,
          photoUrls: const <String>['https://cdn.example.invalid/kapadokya.jpg'],
          photoAuthors: const <String>['Elif Yılmaz (@elif_rotada)'],
          communityVibes: const <String, int>{'Balon Manzarası': 15, 'Gün Doğumu': 9},
          status: 'CLOSED_PERMANENTLY',
          openingHours: const <String, dynamic>{
            'closed_days': <String>['Pazar'],
          },
          communityWarnings: const <String, int>{'Rüzgar İptali Olabilir': 4},
          relatedRouteIds: const <String>['route-kapadokya'],
          isFlagged: true,
          flaggedInListIds: const <String>['list-1'],
          isFromGoogleFallback: true,
        ),
      );

      final jsonMap = original.toJson();
      final decoded = PlaceDiscoveryItem.fromJson(jsonMap);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.shortSummary, original.shortSummary);
      expect(decoded.continent, original.continent);
      expect(decoded.countryCode, original.countryCode);
      expect(decoded.countryName, original.countryName);
      expect(decoded.city, original.city);
      expect(decoded.uiCategory, original.uiCategory);
      expect(decoded.categoryLabel, original.categoryLabel);
      expect(decoded.averageRating, original.averageRating);
      expect(decoded.verifiedVisitCount, original.verifiedVisitCount);
      expect(decoded.distanceKmFromUser, original.distanceKmFromUser);
      expect(decoded.photoUrls, original.photoUrls);
      expect(decoded.photoAuthors, original.photoAuthors);
      expect(decoded.communityVibes, original.communityVibes);
      expect(decoded.communityVibeCounts, original.communityVibeCounts);
      expect(decoded.isClosed, original.isClosed);
      expect(decoded.statusWarning, original.statusWarning);
      expect(decoded.openingHoursWarning, original.openingHoursWarning);
      expect(decoded.warnings, original.warnings);
      expect(decoded.communityWarningBadges.length, original.communityWarningBadges.length);
      expect(
        decoded.communityWarningBadges.first.label,
        original.communityWarningBadges.first.label,
      );
      expect(
        decoded.communityWarningBadges.first.votes,
        original.communityWarningBadges.first.votes,
      );
      expect(decoded.relatedRouteIds, original.relatedRouteIds);
      expect(decoded.isFlagged, original.isFlagged);
      expect(decoded.flaggedInListIds, original.flaggedInListIds);
      expect(decoded.isFromGoogleFallback, original.isFromGoogleFallback);
    });

    test('UserFavoritePlaceList.fromJson icon/icon_emoji, item_count, kota ve toJson alanlarini destekler', () {
      final fromIcon = UserFavoritePlaceList.fromJson(<String, dynamic>{
        'id': 'list-1',
        'title': 'Ege Koyları',
        'icon': '🌊',
        'place_ids': <String>['p-1', 'p-2'],
        'item_count': 2,
        'max_places_per_list': 10,
        'created_at': '2026-11-10T10:30:00.000Z',
      });

      expect(fromIcon.id, 'list-1');
      expect(fromIcon.title, 'Ege Koyları');
      expect(fromIcon.iconEmoji, '🌊');
      expect(fromIcon.placeIds, <String>['p-1', 'p-2']);
      expect(fromIcon.effectiveItemCount, 2);
      expect(fromIcon.maxPlacesPerList, 10);
      expect(fromIcon.containsPlace('p-1'), isTrue);
      expect(fromIcon.containsPlace('p-9'), isFalse);
      expect(fromIcon.createdAt, DateTime.parse('2026-11-10T10:30:00.000Z'));
      expect(fromIcon.toJson()['icon'], '🌊');
      expect(fromIcon.toJson()['max_places_per_list'], 10);

      final fromLegacyEmoji = UserFavoritePlaceList.fromJson(<String, dynamic>{
        'id': 'list-2',
        'title': 'Gurme Duraklar',
        'icon_emoji': '🍽️',
        'place_ids': <String>['p-3'],
      });
      expect(fromLegacyEmoji.iconEmoji, '🍽️');
      expect(fromLegacyEmoji.effectiveItemCount, 1);
      expect(fromLegacyEmoji.maxPlacesPerList, isNull);

      final defaultEmoji = UserFavoritePlaceList.fromJson(<String, dynamic>{
        'id': 'list-3',
        'title': 'Boş Liste',
        'icon': '   ',
      });
      expect(defaultEmoji.iconEmoji, '🚩');
      expect(defaultEmoji.effectiveItemCount, 0);
    });

    test('PublishedRouteFeedItem.fromJson GET /places/:id/routes yanitini eksiksiz ayristirir', () {
      final route = PublishedRouteFeedItem.fromJson(
        _buildRouteJson(
          id: 'route-ege-99',
          title: 'Efes & Şirince Kültür Rotası',
          currency: 'EUR',
          estimatedTotalBudgetUsd: 620,
          estimatedTotalBudget: 570,
          adultsCount: 2,
          childrenCount: 1,
          durationDays: 3,
          totalStopsCount: 7,
        ),
      );

      expect(route.id, 'route-ege-99');
      expect(route.title, 'Efes & Şirince Kültür Rotası');
      expect(route.authorUsername, 'selin_yolda');
      expect(route.authorDisplayName, 'Selin Kaya');
      expect(route.authorRankLabel, 'Bölge Kaşifi');
      expect(route.continent, ContinentFilter.europe);
      expect(route.countryCodes, <String>['TR']);
      expect(route.countryNames, <String>['Türkiye']);
      expect(route.cities, <String>['İzmir', 'Muğla']);
      expect(route.localCurrencySymbol, '€');
      expect(route.estimatedBudgetUsd, 620);
      expect(route.estimatedBudgetLocal, 570);
      expect(route.travelersCount, 3);
      expect(route.durationDays, 3);
      expect(route.effectiveStopsCount, 7);
      expect(route.stops, hasLength(1));
      expect(route.stops.first.placeName, 'Efes Antik Kenti');
      expect(route.stays, hasLength(1));
      expect(route.stays.first.regionOrHotelName, 'Şirince Taş Konak');
      expect(route.questions, hasLength(1));
      expect(route.questions.first.askerUsername, 'mert_ege');
    });
  });

  // ===========================================================================
  // 2. PLACES API SERVICE — TÜM 14 ENDPOINT DOĞRULAMASI
  // ===========================================================================
  group('2. PlacesApiService All 14 Endpoints (MockClient Verification)', () {
    late List<http.Request> capturedRequests;
    late Future<http.Response> Function(http.Request request) handler;
    late BeenHereApiClient apiClient;
    late PlacesApiService apiService;

    setUp(() {
      capturedRequests = <http.Request>[];
      handler = (http.Request request) async => _envelopeResponse(<String, dynamic>{});
      final mockClient = MockClient((http.Request request) async {
        capturedRequests.add(request);
        return handler(request);
      });
      apiClient = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
        authToken: 'dev:test-user',
      );
      apiService = PlacesApiService(apiClient: apiClient);
    });

    tearDown(() {
      apiClient.close();
    });

    test('1) GET /places/feed parametreleri gonderir ve bos/null parametreleri cikarir', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'page': 2,
            'limit': 15,
            'seed': 'seed-42',
            'has_more': true,
            'prioritized_categories': <String>['DESTINATION'],
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'p-1', name: 'Galata Kulesi'),
            ],
            'count': 1,
            'total_count': 42,
          });

      final res = await apiService.fetchPlacesFeed(
        page: 2,
        limit: 15,
        seed: ' seed-42 ',
        continent: 'EUROPE',
        continents: <String>['EUROPE', 'ASIA'],
        regions: <String>['mediterranean'],
        countryCode: 'TR',
        countryCodes: <String>['TR', 'IT'],
        city: 'İstanbul',
        cities: <String>['İstanbul', 'Roma'],
        district: 'Beyoğlu',
        districts: <String>['Beyoğlu', 'Kadıköy'],
        uiCategory: 'FOOD',
        vibe: 'Kahve',
      );

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/feed');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(req.url.queryParameters, <String, String>{
        'page': '2',
        'limit': '15',
        'seed': 'seed-42',
        'continent': 'EUROPE',
        'continents': 'EUROPE,ASIA',
        'regions': 'mediterranean',
        'country_code': 'TR',
        'country_codes': 'TR,IT',
        'city': 'İstanbul',
        'cities': 'İstanbul,Roma',
        'district': 'Beyoğlu',
        'districts': 'Beyoğlu,Kadıköy',
        'ui_category': 'FOOD',
        'vibe': 'Kahve',
      });
      expect(res.page, 2);
      expect(res.hasMore, isTrue);
      expect(res.totalCount, 42);
      expect(res.items.single.name, 'Galata Kulesi');

      // Boş/null parametreler whitelist ihlali olmaması için URL'e eklenmemeli
      capturedRequests.clear();
      await apiService.fetchPlacesFeed(
        page: 0,
        limit: 100,
        seed: '   ',
        continent: ' ',
        continents: const <String>[],
        regions: null,
        countryCode: ' ',
        countryCodes: const <String>[],
        city: ' ',
        cities: const <String>[],
        district: '',
        districts: const <String>[],
        uiCategory: ' ',
        vibe: '',
      );
      final cleanReq = capturedRequests.single;
      expect(cleanReq.url.queryParameters, <String, String>{
        'page': '1',
        'limit': '50',
      });
    });

    test('2) GET /places/search filtreleri dogru kodlar ve bos alanlari gondermez', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'search_mode': 'NEARBY',
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'p-2', name: 'Saat Kulesi'),
            ],
            'count': 1,
            'total_count': 17,
            'can_fetch_from_google': true,
            'min_google_query_length': 3,
            'google_fetch_prompt': 'Google Haritalar\'da Ara',
          });

      final res = await apiService.searchPlaces(
        query: '  Saat Kulesi  ',
        searchMode: 'NEARBY',
        lang: 'tr',
        lat: 38.4192,
        lng: 27.1287,
        radius: 5000,
        continent: 'EUROPE',
        continents: <String>['EUROPE'],
        regions: <String>['aegean'],
        city: 'İzmir',
        cities: <String>['İzmir'],
        district: 'Konak',
        districts: <String>['Konak', 'Urla'],
        countryCode: 'TR',
        countryCodes: <String>['TR'],
        uiCategory: 'DESTINATION',
        googleType: 'tourist_attraction',
        vibe: 'Tarihi',
        limit: 25,
      );

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/search');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(req.url.queryParameters, <String, String>{
        'q': 'Saat Kulesi',
        'search_mode': 'NEARBY',
        'lang': 'tr',
        'lat': '38.4192',
        'lng': '27.1287',
        'radius': '5000',
        'continent': 'EUROPE',
        'continents': 'EUROPE',
        'regions': 'aegean',
        'city': 'İzmir',
        'cities': 'İzmir',
        'district': 'Konak',
        'districts': 'Konak,Urla',
        'country_code': 'TR',
        'country_codes': 'TR',
        'ui_category': 'DESTINATION',
        'google_type': 'tourist_attraction',
        'vibe': 'Tarihi',
        'limit': '25',
      });
      expect(res.searchMode, 'NEARBY');
      expect(res.totalCount, 17);
      expect(res.canFetchFromGoogle, isTrue);
      expect(res.items.single.name, 'Saat Kulesi');

      capturedRequests.clear();
      await apiService.searchPlaces(
        query: '   ',
        searchMode: 'SOMETHING_ELSE',
        lang: '',
        city: ' ',
        countryCodes: const <String>[],
      );
      final minimalReq = capturedRequests.single;
      expect(minimalReq.url.queryParameters, <String, String>{
        'search_mode': 'GLOBAL',
        'limit': '20',
      });
    });

    test('3) GET /places/:id mekan detayini ceker', () async {
      handler = (_) async => _envelopeResponse(
            _buildPlaceJson(
              id: 'place-tr-1',
              name: 'Amintas Kaya Mezarları',
              status: 'CLOSED_TEMPORARILY',
            ),
          );

      final item = await apiService.fetchPlaceById('place-tr-1');

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/place-tr-1');
      expect(req.url.queryParameters, isEmpty);
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(item.name, 'Amintas Kaya Mezarları');
      expect(item.isClosed, isTrue);
    });

    test('4) GET /places/:id/routes ilintili rotalari ceker', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'place_id': 'place-tr-1',
            'page': 2,
            'limit': 5,
            'has_more': false,
            'items': <Map<String, dynamic>>[
              _buildRouteJson(id: 'route-1', title: 'Likya Yolu Turu'),
            ],
            'count': 1,
          });

      final res = await apiService.fetchPlaceRelatedRoutes(
        'place-tr-1',
        page: 2,
        limit: 5,
      );

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/place-tr-1/routes');
      expect(req.url.queryParameters, <String, String>{
        'page': '2',
        'limit': '5',
      });
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(res.placeId, 'place-tr-1');
      expect(res.items.single.title, 'Likya Yolu Turu');
    });

    test('5) GET /places/:id/nearby yakin benzer lokasyonlari ceker', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'base_place_id': 'place-tr-1',
            'ui_category': 'DESTINATION',
            'radius_meters': 4000,
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'place-nearby-1', name: 'Kayaköy'),
            ],
            'count': 1,
            'can_fetch_from_google': false,
          });

      final res = await apiService.fetchNearbyPlaces(
        'place-tr-1',
        radius: 4000,
        lang: 'en',
        limit: 12,
      );

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/place-tr-1/nearby');
      expect(req.url.queryParameters, <String, String>{
        'radius': '4000',
        'lang': 'en',
        'limit': '12',
      });
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(res.radiusMeters, 4000);
      expect(res.items.single.name, 'Kayaköy');
    });

    test('6) POST /places/fetch-google Google fallback istegi gonderir ve opsiyonel bos alanlari cikarir', () async {
      handler = (_) async => _envelopeResponse(
            <Map<String, dynamic>>[
              _buildPlaceJson(id: 'gp-1', name: 'Pamukkale Travertenleri'),
            ],
            statusCode: 201,
          );

      final items = await apiService.fetchFromGoogle(
        query: '  Pamukkale Travertenleri  ',
        searchMode: 'NEARBY',
        lang: 'tr',
        lat: 37.9204,
        lng: 29.1235,
        radius: 5000,
        googleType: 'natural_feature',
      );

      final req = capturedRequests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/places/fetch-google');
      expect(req.url.queryParameters, isEmpty);
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(jsonDecode(req.body), <String, dynamic>{
        'query': 'Pamukkale Travertenleri',
        'search_mode': 'NEARBY',
        'lang': 'tr',
        'lat': 37.9204,
        'lng': 29.1235,
        'radius': 5000,
        'google_type': 'natural_feature',
      });
      expect(items.single.name, 'Pamukkale Travertenleri');

      // Opsiyonel alanlar boşken body sade olmalı
      capturedRequests.clear();
      await apiService.fetchFromGoogle(query: 'Efes', googleType: '   ');
      expect(jsonDecode(capturedRequests.single.body), <String, dynamic>{
        'query': 'Efes',
        'search_mode': 'GLOBAL',
        'lang': 'tr',
      });
    });

    test('7) POST /places/:id/vibes bosluklari temizler ve vibe oyu gonderir', () async {
      handler = (_) async => _envelopeResponse(
            _buildPlaceJson(
              id: 'place-tr-1',
              name: 'Efes',
              communityVibes: const <String, int>{'Gün Batımı': 5},
            ),
            statusCode: 201,
          );

      final raw = await apiService.addCommunityVibes(
        'place-tr-1',
        <String>['  Gün Batımı ', '', '  Manzaralı  '],
      );

      final req = capturedRequests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/places/place-tr-1/vibes');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(jsonDecode(req.body), <String, dynamic>{
        'vibes': <String>['Gün Batımı', 'Manzaralı'],
      });
      expect(raw['id'], 'place-tr-1');
    });

    test('8) POST /places/:id/warnings bosluklari temizler ve saha uyarisi gonderir', () async {
      handler = (_) async => _envelopeResponse(
            _buildPlaceJson(
              id: 'place-tr-1',
              name: 'Efes',
              communityWarnings: const <String, int>{'Nakit Gerekli': 3},
            ),
            statusCode: 201,
          );

      final raw = await apiService.addCommunityWarnings(
        'place-tr-1',
        <String>[' Nakit Gerekli ', '   '],
      );

      final req = capturedRequests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/places/place-tr-1/warnings');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(jsonDecode(req.body), <String, dynamic>{
        'warnings': <String>['Nakit Gerekli'],
      });
      expect(raw['id'], 'place-tr-1');
    });

    test('9) GET /places/lists/me favori listelerini ve kota bilgisini getirir', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'list-1',
                'title': 'Favori Liste 1',
                'icon': '🚩',
                'place_ids': <String>['place-tr-1'],
                'item_count': 1,
                'max_places_per_list': 10,
              },
            ],
            'count': 1,
            'suggested_next_title': 'Favori Liste 2',
            'quota': <String, dynamic>{
              'is_premium': false,
              'max_lists': 3,
              'max_places_per_list': 10,
            },
          });

      final res = await apiService.fetchMyPlaceLists();

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/lists/me');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(res.items.single.id, 'list-1');
      expect(res.suggestedNextTitle, 'Favori Liste 2');
      expect(res.quota.isPremium, isFalse);
      expect(res.quota.maxLists, 3);
      expect(res.quota.maxPlacesPerList, 10);
    });

    test('10) POST /places/lists yeni liste olusturur ve bos alanlari gondermez', () async {
      handler = (_) async => _envelopeResponse(
            <String, dynamic>{
              'id': 'list-new',
              'title': 'Ege Planı',
              'icon': '🌊',
              'place_ids': <String>[],
              'item_count': 0,
            },
            statusCode: 201,
          );

      final created = await apiService.createPlaceList(
        title: '  Ege Planı  ',
        icon: ' 🌊 ',
      );

      final req = capturedRequests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/places/lists');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(jsonDecode(req.body), <String, dynamic>{
        'title': 'Ege Planı',
        'icon': '🌊',
      });
      expect(created.id, 'list-new');

      capturedRequests.clear();
      await apiService.createPlaceList(title: '   ', icon: null);
      expect(jsonDecode(capturedRequests.single.body), <String, dynamic>{});
    });

    test('11) GET /places/lists/:listId liste detayini ve icerigini getirir', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{
            'id': 'list-1',
            'title': 'Ege Planı',
            'icon': '🌊',
            'item_count': 1,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'item-1',
                'list_id': 'list-1',
                'place_id': 'place-tr-1',
                'note': 'Gün batımında git',
                'place': _buildPlaceJson(id: 'place-tr-1', name: 'Alaçatı'),
              },
            ],
          });

      final detail = await apiService.fetchPlaceListDetails('list-1');

      final req = capturedRequests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/places/lists/list-1');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(detail.items.single.place?.name, 'Alaçatı');
      expect(detail.items.single.note, 'Gün batımında git');
    });

    test('12) POST /places/lists/:listId/items mekana notla veya notsuz ekler', () async {
      handler = (_) async => _envelopeResponse(
            <String, dynamic>{
              'id': 'item-9',
              'list_id': 'list-1',
              'place_id': 'place-tr-1',
              'note': 'Kahvaltı için uğra',
            },
            statusCode: 201,
          );

      final added = await apiService.addPlaceToList(
        listId: 'list-1',
        placeId: 'place-tr-1',
        note: ' Kahvaltı için uğra ',
      );

      final req = capturedRequests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/places/lists/list-1/items');
      expect(req.headers['Authorization'], 'Bearer dev:test-user');
      expect(jsonDecode(req.body), <String, dynamic>{
        'place_id': 'place-tr-1',
        'note': 'Kahvaltı için uğra',
      });
      expect(added.placeId, 'place-tr-1');

      capturedRequests.clear();
      await apiService.addPlaceToList(
        listId: 'list-1',
        placeId: 'place-tr-2',
        note: '   ',
      );
      expect(jsonDecode(capturedRequests.single.body), <String, dynamic>{
        'place_id': 'place-tr-2',
      });
    });

    test('13) DELETE /places/lists/:listId/items/:placeId mekani listeden cikarir', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{'removed': true});

      final removed200 = await apiService.removePlaceFromList(
        listId: 'list-1',
        placeId: 'place-tr-1',
      );
      expect(removed200, isTrue);
      expect(capturedRequests.single.method, 'DELETE');
      expect(
        capturedRequests.single.url.path,
        '/places/lists/list-1/items/place-tr-1',
      );
      expect(capturedRequests.single.headers['Authorization'], 'Bearer dev:test-user');

      capturedRequests.clear();
      handler = (_) async => http.Response('', 204);
      final removed204 = await apiService.removePlaceFromList(
        listId: 'list-1',
        placeId: 'place-tr-1',
      );
      expect(removed204, isTrue);
    });

    test('14) DELETE /places/lists/:listId listeyi siler', () async {
      handler = (_) async => _envelopeResponse(<String, dynamic>{'deleted': true});

      final deleted200 = await apiService.deletePlaceList('list-1');
      expect(deleted200, isTrue);
      expect(capturedRequests.single.method, 'DELETE');
      expect(capturedRequests.single.url.path, '/places/lists/list-1');
      expect(capturedRequests.single.headers['Authorization'], 'Bearer dev:test-user');

      capturedRequests.clear();
      handler = (_) async => http.Response('', 204);
      final deleted204 = await apiService.deletePlaceList('list-1');
      expect(deleted204, isTrue);
    });
  });

  // ===========================================================================
  // 3. PLACES STORE & VIEWMODEL UZAK DURUM AKIŞLARI
  // ===========================================================================
  group('3. PlacesStore & PlaceSearchViewModel Remote State Flows', () {
    late List<http.Request> requests;
    late Future<http.Response> Function(http.Request request) router;
    late BeenHereApiClient apiClient;
    late PlacesApiService apiService;
    late PlacesStore store;
    late PlaceSearchViewModel vm;

    void setupWithRouter(
      Future<http.Response> Function(http.Request request) customRouter, {
      int feedPageSize = 2,
    }) {
      requests = <http.Request>[];
      router = customRouter;
      final mockClient = MockClient((http.Request request) async {
        requests.add(request);
        return router(request);
      });
      apiClient = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );
      apiService = PlacesApiService(apiClient: apiClient);
      store = PlacesStore(apiService: apiService, feedPageSize: feedPageSize);
      vm = PlaceSearchViewModel(placesStore: store, enableRemoteBackend: true);
    }

    tearDown(() {
      vm.dispose();
      store.dispose();
      apiClient.close();
    });

    test('initializePlaces ve loadMoreFeed sayfalama, seed koruma ve tekillestirmeyi dogru calistirir', () async {
      setupWithRouter((http.Request req) async {
        if (req.url.path == '/places/lists/me') {
          return _envelopeResponse(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'list-ege',
                'title': 'Ege Planım',
                'icon': '🌊',
                'place_ids': <String>['place-2'],
                'item_count': 1,
                'max_places_per_list': 10,
              },
            ],
            'count': 1,
            'suggested_next_title': 'Favori Liste 2',
            'quota': <String, dynamic>{
              'is_premium': false,
              'max_lists': 3,
              'max_places_per_list': 10,
            },
          });
        }
        if (req.url.path == '/places/feed') {
          final page = int.parse(req.url.queryParameters['page'] ?? '1');
          if (page == 1) {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 2,
              'seed': 'feed-seed-xyz',
              'has_more': true,
              'prioritized_categories': <String>['DESTINATION'],
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'place-1', name: 'Galata Kulesi'),
                _buildPlaceJson(id: 'place-2', name: 'Efes Antik Kenti'),
              ],
              'count': 2,
            });
          }
          // Sayfa 2 mükerrer place-2 + yeni place-3 döner; has_more: false olur
          return _envelopeResponse(<String, dynamic>{
            'page': 2,
            'limit': 2,
            'seed': 'feed-seed-xyz',
            'has_more': false,
            'prioritized_categories': <String>['DESTINATION'],
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'place-2', name: 'Efes Antik Kenti'),
              _buildPlaceJson(id: 'place-3', name: 'Pamukkale'),
            ],
            'count': 2,
          });
        }
        return _envelopeResponse(<String, dynamic>{});
      });

      await vm.initializePlaces();

      expect(vm.displayedPlaces.map((p) => p.id), <String>['place-1', 'place-2']);
      expect(vm.displayedPlaces[0].isFlagged, isFalse);
      expect(vm.displayedPlaces[1].isFlagged, isTrue);
      expect(vm.displayedPlaces[1].flaggedInListIds, <String>['list-ege']);
      expect(vm.favoriteLists, hasLength(1));
      expect(vm.listsQuota?.maxLists, 3);
      expect(vm.listsQuota?.maxPlacesPerList, 10);
      expect(vm.hasMoreFeed, isTrue);
      expect(store.feedSeed, 'feed-seed-xyz');

      await vm.loadMoreFeed();

      final page2Req = requests.last;
      expect(page2Req.url.path, '/places/feed');
      expect(page2Req.url.queryParameters['page'], '2');
      expect(page2Req.url.queryParameters['seed'], 'feed-seed-xyz');
      expect(
        vm.displayedPlaces.map((p) => p.id),
        <String>['place-1', 'place-2', 'place-3'],
      );
      expect(vm.hasMoreFeed, isFalse);

      // has_more false iken tekrar çağrılırsa ek istek atılmamalı
      final countBeforeExtraLoad = requests.length;
      await vm.loadMoreFeed();
      expect(requests.length, countBeforeExtraLoad);
    });

    testWidgets(
      'Arama debounce (5 sn + 3 karakter), cografya filtresi, nearby ve Google fallback calisir',
      (WidgetTester tester) async {
        setupWithRouter((http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{
                'is_premium': false,
                'max_lists': 3,
                'max_places_per_list': 10,
              },
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'feed-1', name: 'Roma Kolezyum'),
              ],
            });
          }
          if (req.url.path == '/places/search') {
            final q = req.url.queryParameters['q'] ?? '';
            return _envelopeResponse(<String, dynamic>{
              'search_mode': req.url.queryParameters['search_mode'] ?? 'GLOBAL',
              'items': q == 'Gizli Kanyon'
                  ? <Map<String, dynamic>>[]
                  : <Map<String, dynamic>>[
                      _buildPlaceJson(id: 'search-1', name: 'Kapadokya Vadisi'),
                    ],
              'count': q == 'Gizli Kanyon' ? 0 : 1,
              'can_fetch_from_google': true,
              'min_google_query_length': 3,
              'google_fetch_prompt':
                  'Aradığınız mekanı bulamadınız mı? Google Haritalar\'da Ara',
            });
          }
          if (req.url.path == '/places/fetch-google') {
            return _envelopeResponse(
              <Map<String, dynamic>>[
                _buildPlaceJson(id: 'gp-99', name: 'Gizli Kanyon Terası'),
              ],
              statusCode: 201,
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        }, feedPageSize: 10);

        await vm.initializePlaces();
        expect(vm.displayedPlaces.single.id, 'feed-1');

        // 1. Kıta seçimi -> /places/feed continent=EUROPE&continents=EUROPE
        vm.toggleContinentCheckbox(ContinentFilter.europe);
        await tester.pump();
        expect(
          requests.any(
            (r) =>
                r.url.path == '/places/feed' &&
                r.url.queryParameters['continent'] == 'EUROPE' &&
                r.url.queryParameters['continents'] == 'EUROPE',
          ),
          isTrue,
        );

        // 2. 3 karakter altı debounce başlatmamalı
        final requestsBeforeShortInput = requests.length;
        vm.onSearchInputChanged('Ka');
        expect(vm.isWaitingForDebounce, isFalse);
        await tester.pump(const Duration(seconds: 6));
        expect(requests.length, requestsBeforeShortInput);

        // 3. >= 3 karakter -> 5 saniye sonra otomatik /places/search tetiklenmeli
        vm.onSearchInputChanged('Kapadokya');
        expect(vm.isWaitingForDebounce, isTrue);
        await tester.pump(const Duration(seconds: 4));
        expect(
          requests.where((r) => r.url.path == '/places/search'),
          isEmpty,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(vm.isWaitingForDebounce, isFalse);
        final searchReq =
            requests.lastWhere((r) => r.url.path == '/places/search');
        expect(searchReq.url.queryParameters['q'], 'Kapadokya');
        expect(searchReq.url.queryParameters['continent'], 'EUROPE');
        expect(vm.displayedPlaces.single.name, 'Kapadokya Vadisi');
        expect(vm.canFetchFromGoogle, isTrue);

        // 4. Manuel executeTextSearchNow() -> 'Gizli Kanyon' boş sonuç döner, Google fallback ekler
        vm.onSearchInputChanged('Gizli Kanyon');
        expect(vm.executeTextSearchNow(), isTrue);
        await tester.pump();
        expect(vm.displayedPlaces, isEmpty);
        expect(vm.canFetchFromGoogle, isTrue);

        final fetched = await vm.fetchFromGoogleMapsFallbackAsync();
        expect(fetched.single.id, 'gp-99');
        expect(fetched.single.isFromGoogleFallback, isTrue);
        expect(vm.displayedPlaces.first.id, 'gp-99');
        expect(vm.displayedPlaces.first.isFromGoogleFallback, isTrue);

        // 5. Yakınımdaki Mekanlar modu -> NEARBY + default lat/lng göndermeli
        vm.toggleNearbySearch();
        await tester.pump();
        final nearbyReq = requests.lastWhere((r) => r.url.path == '/places/search');
        expect(nearbyReq.url.queryParameters['search_mode'], 'NEARBY');
        expect(nearbyReq.url.queryParameters['lat'], isNotNull);
        expect(nearbyReq.url.queryParameters['lng'], isNotNull);
      },
    );

    test('Lazy detail, related routes, nearby places, voteVibes ve reportWarnings durumlari gunceller', () async {
      setupWithRouter((http.Request req) async {
        if (req.url.path == '/places/lists/me') {
          return _envelopeResponse(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'list-fav',
                'title': 'Favoriler',
                'icon': '🚩',
                'place_ids': <String>['place-1'],
                'item_count': 1,
              },
            ],
            'count': 1,
            'suggested_next_title': 'Favori Liste 2',
            'quota': <String, dynamic>{'is_premium': true},
          });
        }
        if (req.url.path == '/places/feed') {
          return _envelopeResponse(<String, dynamic>{
            'page': 1,
            'limit': 10,
            'seed': 's1',
            'has_more': false,
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(
                id: 'place-1',
                name: 'Bodrum Kalesi',
                continent: 'EUROPE',
                countryCode: 'TR',
                countryName: 'Türkiye',
                city: 'Muğla',
                distanceKm: 4.2,
                communityVibes: const <String, int>{'Tarihi': 3},
                relatedRouteIds: const <String>['r-1'],
              ),
            ],
          });
        }
        if (req.url.path == '/places/place-1') {
          return _envelopeResponse(
            _buildPlaceJson(
              id: 'place-1',
              name: 'Bodrum Kalesi',
              shortSummary: 'Detaylı müze ve kale bilgisi.',
              continent: 'EUROPE',
              countryCode: 'TR',
              countryName: 'Türkiye',
              city: 'Muğla',
              averageRating: '4.80',
              verifiedVisitCount: 55,
              distanceKm: null,
              communityVibes: const <String, int>{'Tarihi': 3, 'Manzaralı': 2},
              relatedRouteIds: const <String>['r-1'],
            ),
          );
        }
        if (req.url.path == '/places/place-1/routes') {
          return _envelopeResponse(<String, dynamic>{
            'place_id': 'place-1',
            'page': 1,
            'limit': 10,
            'has_more': false,
            'items': <Map<String, dynamic>>[
              _buildRouteJson(id: 'r-1', title: 'Bodrum Yarımadası'),
            ],
          });
        }
        if (req.url.path == '/places/place-1/nearby') {
          return _envelopeResponse(<String, dynamic>{
            'base_place_id': 'place-1',
            'ui_category': 'DESTINATION',
            'radius_meters': 3000,
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'place-near', name: 'Halikarnas Mozolesi'),
            ],
            'can_fetch_from_google': false,
          });
        }
        if (req.url.path == '/places/place-1/vibes') {
          return _envelopeResponse(
            <String, dynamic>{
              'id': 'place-1',
              'name': 'Bodrum Kalesi',
              'short_summary': 'Detaylı müze ve kale bilgisi.',
              'country_code': 'TR',
              'city': 'Muğla',
              'ui_category': 'DESTINATION',
              'average_rating': '4.80',
              'verified_visit_count': 55,
              'community_vibes': const <String, int>{
                'Gün Batımı': 7,
                'Tarihi': 3,
                'Manzaralı': 2,
              },
            },
            statusCode: 201,
          );
        }
        if (req.url.path == '/places/place-1/warnings') {
          return _envelopeResponse(
            <String, dynamic>{
              'id': 'place-1',
              'name': 'Bodrum Kalesi',
              'short_summary': 'Detaylı müze ve kale bilgisi.',
              'country_code': 'TR',
              'city': 'Muğla',
              'ui_category': 'DESTINATION',
              'average_rating': '4.80',
              'verified_visit_count': 55,
              'status': 'CLOSED_TEMPORARILY',
              'community_vibes': const <String, int>{
                'Gün Batımı': 7,
                'Tarihi': 3,
                'Manzaralı': 2,
              },
              'community_warnings': const <String, int>{
                'Nakit Gerekli': 4,
              },
            },
            statusCode: 201,
          );
        }
        return _envelopeResponse(<String, dynamic>{});
      });

      await vm.initializePlaces();

      final detailed = await vm.loadPlaceDetails('place-1');
      expect(detailed?.shortSummary, 'Detaylı müze ve kale bilgisi.');
      expect(detailed?.distanceKmFromUser, closeTo(4.2, 0.001));
      expect(detailed?.isFlagged, isTrue);
      expect(vm.getPlaceDetails('place-1')?.shortSummary, 'Detaylı müze ve kale bilgisi.');

      await vm.loadRelatedRoutes('place-1');
      expect(vm.hasLoadedRelatedRoutes('place-1'), isTrue);
      expect(
        vm.getRelatedRoutesForPlace(vm.displayedPlaces.single).single.title,
        'Bodrum Yarımadası',
      );

      await vm.loadNearbyPlaces('place-1');
      expect(vm.hasLoadedNearbyPlaces('place-1'), isTrue);
      expect(
        vm.getSimilarPlacesForPlace(vm.displayedPlaces.single).single.name,
        'Halikarnas Mozolesi',
      );

      final vibeUpdated = await vm.voteVibes('place-1', const <String>['Gün Batımı']);
      expect(vibeUpdated?.communityVibes.first, 'Gün Batımı');
      expect(vibeUpdated?.countryName, 'Türkiye');
      expect(vibeUpdated?.isFlagged, isTrue);
      expect(vm.displayedPlaces.single.communityVibeCounts['Gün Batımı'], 7);
      expect(vm.getPlaceDetails('place-1')?.communityVibeCounts['Gün Batımı'], 7);

      final warningUpdated = await vm.reportWarnings(
        'place-1',
        const <String>['Nakit Gerekli'],
      );
      expect(warningUpdated?.isClosed, isTrue);
      expect(warningUpdated?.communityWarningBadges.single.label, 'Nakit Gerekli');
      expect(warningUpdated?.communityWarningBadges.single.votes, 4);
      expect(vm.displayedPlaces.single.isClosed, isTrue);
      expect(
        vm.getPlaceDetails('place-1')?.communityWarningBadges.single.label,
        'Nakit Gerekli',
      );
    });

    test('Favori liste CRUD islemleri ve Free plan 403 kota hatasi cokmeden yonetilir', () async {
      var listsCount = 1;
      setupWithRouter((http.Request req) async {
        if (req.url.path == '/places/lists/me') {
          return _envelopeResponse(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'list-1',
                'title': 'Ege Koyları',
                'icon': '🌊',
                'place_ids': <String>[],
                'item_count': 0,
                'max_places_per_list': 10,
              },
            ],
            'count': 1,
            'suggested_next_title': 'Favori Liste 2',
            'quota': <String, dynamic>{
              'is_premium': false,
              'max_lists': 3,
              'max_places_per_list': 10,
            },
          });
        }
        if (req.url.path == '/places/feed') {
          return _envelopeResponse(<String, dynamic>{
            'page': 1,
            'limit': 10,
            'seed': 's1',
            'has_more': false,
            'items': <Map<String, dynamic>>[
              _buildPlaceJson(id: 'place-1', name: 'Akyaka'),
            ],
          });
        }
        if (req.url.path == '/places/lists/list-1/items' && req.method == 'POST') {
          return _envelopeResponse(
            <String, dynamic>{
              'id': 'item-1',
              'list_id': 'list-1',
              'place_id': 'place-1',
            },
            statusCode: 201,
          );
        }
        if (req.url.path == '/places/lists/list-1/items/place-1' &&
            req.method == 'DELETE') {
          return _envelopeResponse(<String, dynamic>{'removed': true});
        }
        if (req.url.path == '/places/lists' && req.method == 'POST') {
          if (listsCount >= 2) {
            return _errorEnvelopeResponse(
              statusCode: 403,
              path: '/places/lists',
              message:
                  'Free planda en fazla 3 favori liste oluşturabilirsiniz. Sınırsız liste için Premium\'a geçin.',
            );
          }
          listsCount++;
          return _envelopeResponse(
            <String, dynamic>{
              'id': 'list-2',
              'title': 'Sonbahar Rotam',
              'icon': '🚩',
              'place_ids': <String>[],
              'item_count': 0,
              'max_places_per_list': 10,
            },
            statusCode: 201,
          );
        }
        if (req.url.path == '/places/lists/list-2/items' && req.method == 'POST') {
          return _envelopeResponse(
            <String, dynamic>{
              'id': 'item-2',
              'list_id': 'list-2',
              'place_id': 'place-1',
            },
            statusCode: 201,
          );
        }
        if (req.url.path == '/places/lists/list-2' && req.method == 'GET') {
          return _envelopeResponse(<String, dynamic>{
            'id': 'list-2',
            'title': 'Sonbahar Rotam',
            'icon': '🚩',
            'item_count': 1,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'item-2',
                'list_id': 'list-2',
                'place_id': 'place-1',
                'place': _buildPlaceJson(id: 'place-1', name: 'Akyaka'),
              },
            ],
          });
        }
        if (req.url.path == '/places/lists/list-2' && req.method == 'DELETE') {
          listsCount--;
          return _envelopeResponse(<String, dynamic>{'deleted': true});
        }
        return _envelopeResponse(<String, dynamic>{});
      });

      await vm.initializePlaces();
      expect(vm.isPlaceFlaggedInAnyList('place-1'), isFalse);

      // 1. Ekleme & Çıkarma toggle
      final added = await vm.togglePlaceInListAsync(
        listId: 'list-1',
        placeId: 'place-1',
      );
      expect(added, isTrue);
      expect(vm.isPlaceFlaggedInAnyList('place-1'), isTrue);
      expect(vm.displayedPlaces.single.isFlagged, isTrue);

      final removed = await vm.togglePlaceInListAsync(
        listId: 'list-1',
        placeId: 'place-1',
      );
      expect(removed, isTrue);
      expect(vm.isPlaceFlaggedInAnyList('place-1'), isFalse);
      expect(vm.displayedPlaces.single.isFlagged, isFalse);

      // 2. Yeni liste oluşturma + mekan ekleme + detay yükleme
      final created = await vm.createNewFavoriteListAndAddPlaceAsync(
        listTitle: 'Sonbahar Rotam',
        placeId: 'place-1',
      );
      expect(created?.id, 'list-2');
      expect(vm.favoriteLists, hasLength(2));
      expect(vm.isPlaceFlaggedInAnyList('place-1'), isTrue);

      final detail = await vm.loadPlaceListDetails('list-2');
      expect(detail?.items.single.place?.name, 'Akyaka');
      expect(vm.getListDetails('list-2')?.itemCount, 1);

      // 3. Free plan 403 kota hatası çökmeden mutationErrorMessage set etmeli
      final quotaBlocked = await vm.createNewFavoriteListAndAddPlaceAsync(
        listTitle: 'Kota Aşan Liste',
        placeId: 'place-1',
      );
      expect(quotaBlocked, isNull);
      expect(
        vm.mutationErrorMessage,
        contains('Free planda en fazla 3 favori liste'),
      );
      expect(vm.favoriteLists, hasLength(2));

      // 4. Liste silme
      final deleted = await vm.deleteFavoriteListAsync('list-2');
      expect(deleted, isTrue);
      expect(vm.favoriteLists, hasLength(1));
      expect(vm.isPlaceFlaggedInAnyList('place-1'), isFalse);
      expect(vm.getListDetails('list-2'), isNull);
    });

    test('Sunucu 500 veya ag hatasi errorMessage set eder ve enableOfflineDemoFallback statik verilere gecer', () async {
      setupWithRouter((http.Request req) async {
        if (req.url.path == '/places/feed') {
          return _errorEnvelopeResponse(
            statusCode: 500,
            path: '/places/feed',
            message: 'Sunucu geçici olarak yanıt veremiyor.',
          );
        }
        return _envelopeResponse(<String, dynamic>{});
      });

      await vm.initializePlaces();
      expect(vm.errorMessage, 'Sunucu geçici olarak yanıt veremiyor.');
      expect(vm.displayedPlaces, isEmpty);

      // Ağ istisnası senaryosu
      vm.dispose();
      store.dispose();
      apiClient.close();

      setupWithRouter((http.Request req) async {
        throw http.ClientException('Connection refused', req.url);
      });

      await vm.initializePlaces();
      expect(vm.errorMessage, contains('Sunucuya bağlanılamadı'));
      expect(vm.displayedPlaces, isEmpty);

      vm.enableOfflineDemoFallback();
      expect(vm.isUsingOfflineDemoFallback, isTrue);
      expect(vm.isUsingRemoteData, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.displayedPlaces, hasLength(6));
      expect(
        vm.displayedPlaces.any((p) => p.name == 'Amintas Kaya Mezarları'),
        isTrue,
      );
    });

    testWidgets(
      'effectiveGoogleFallbackQuery oncelik sirasi ve remote shouldShowNotFoundBannerAtEnd kurallari dogru calisir',
      (WidgetTester tester) async {
        bool returnEmptyFeed = true;
        setupWithRouter((http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': returnEmptyFeed
                  ? <Map<String, dynamic>>[]
                  : <Map<String, dynamic>>[
                      _buildPlaceJson(id: 'feed-1', name: 'Galata Kulesi'),
                    ],
            });
          }
          if (req.url.path == '/places/search') {
            return _envelopeResponse(<String, dynamic>{
              'search_mode': 'GLOBAL',
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'search-1', name: 'Efes Antik Kenti'),
              ],
              'count': 1,
              'can_fetch_from_google': false,
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        }, feedPageSize: 10);

        // 1. Uzak modda bos sonuc -> banner gorunur ve fallback 'Popüler Turistik Mekanlar' olur
        await vm.initializePlaces();
        expect(vm.isUsingRemoteData, isTrue);
        expect(vm.displayedPlaces, isEmpty);
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(vm.effectiveGoogleFallbackQuery, 'Popüler Turistik Mekanlar');

        // 2. Uzak modda dolu vitrin + filtresiz -> banner gizli ve fallback bos
        returnEmptyFeed = false;
        await vm.refreshPlaces();
        expect(vm.displayedPlaces, hasLength(1));
        expect(vm.shouldShowNotFoundBannerAtEnd, isFalse);
        expect(vm.effectiveGoogleFallbackQuery, '');

        // 3. Agac sehir / ulke / kita secimi -> banner acilir, etiketler + 'gezilecek yerler'
        vm.toggleCityCheckbox('Fethiye');
        await tester.pump();
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(vm.effectiveGoogleFallbackQuery, 'Fethiye gezilecek yerler');

        vm.toggleCityCheckbox('Fethiye');
        vm.toggleCountryCheckbox('IT');
        await tester.pump();
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(vm.effectiveGoogleFallbackQuery, 'İtalya gezilecek yerler');

        vm.toggleContinentCheckbox(ContinentFilter.asia);
        await tester.pump();
        expect(vm.effectiveGoogleFallbackQuery, 'İtalya Asya gezilecek yerler');
        vm.resetToGlobal();
        await tester.pump();

        // 4. Aktif konum filtre haplari -> '<etiketler> gezilecek yerler'
        vm.applyFilterPills(<RouteFeedFilterPill>[
          const RouteFeedFilterPill(
            id: 'city:marmaris',
            type: RouteFilterPillType.city,
            label: 'Marmaris',
            cityName: 'Marmaris',
            countryCode: 'TR',
          ),
          const RouteFeedFilterPill(
            id: 'country:IT',
            type: RouteFilterPillType.country,
            label: 'İtalya',
            countryCode: 'IT',
          ),
        ]);
        await tester.pump();
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(
          vm.effectiveGoogleFallbackQuery,
          'Marmaris İtalya gezilecek yerler',
        );

        // Konum haplari pasife cekilirse ve sonuclar doluysa fallback bos olur
        vm.toggleFilterPill('city:marmaris');
        vm.toggleFilterPill('country:IT');
        await tester.pump();
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(vm.effectiveGoogleFallbackQuery, '');

        // 5. Oncelik sirasi: draft > committed/keyword > konum filtresi
        vm.toggleFilterPill('city:marmaris');
        await tester.pump();
        expect(vm.effectiveGoogleFallbackQuery, 'Marmaris gezilecek yerler');

        vm.onSearchInputChanged('Kapadokya');
        expect(vm.executeTextSearchNow(), isTrue);
        await tester.pump();
        expect(vm.effectiveGoogleFallbackQuery, 'Kapadokya');

        vm.onSearchInputChanged('Efes Antik');
        expect(vm.effectiveGoogleFallbackQuery, 'Efes Antik');
        vm.clearSearchInput();
        await tester.pump();

        // 6. Statik (legacy) modda showcase filtrelerinde banner acilmaz
        final staticVm = PlaceSearchViewModel();
        addTearDown(staticVm.dispose);
        expect(staticVm.isUsingRemoteData, isFalse);
        expect(staticVm.shouldShowNotFoundBannerAtEnd, isFalse);
        staticVm.applyFilterPills(<RouteFeedFilterPill>[
          const RouteFeedFilterPill(
            id: 'region:western_europe',
            type: RouteFilterPillType.region,
            label: 'Batı Avrupa',
            regionId: 'western_europe',
            continent: ContinentFilter.europe,
          ),
        ]);
        expect(staticVm.shouldShowNotFoundBannerAtEnd, isFalse);
        expect(
          staticVm.effectiveGoogleFallbackQuery,
          'Batı Avrupa gezilecek yerler',
        );
      },
    );

    testWidgets(
      'Ilce filtresi (selectedDistricts ve RouteFilterPillType.district) districts parametresi gonderir ve total_count gunceller',
      (WidgetTester tester) async {
        setupWithRouter((http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            final districts = req.url.queryParameters['districts'] ?? '';
            final totalCount = districts.contains('Konak')
                ? 19
                : (districts.contains('Beyoğlu') ? 8 : 34);
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'feed-district-1', name: 'Galata Kulesi'),
              ],
              'count': 1,
              'total_count': totalCount,
            });
          }
          if (req.url.path == '/places/search') {
            return _envelopeResponse(<String, dynamic>{
              'search_mode': 'GLOBAL',
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'search-district-1', name: 'Konak Kafe'),
              ],
              'count': 1,
              'total_count': 5,
              'can_fetch_from_google': true,
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        }, feedPageSize: 10);

        await vm.initializePlaces();
        expect(vm.geographyFilteredPlacesCount, 34);

        // 1. Agac ilce secimi -> /places/feed district & districts gonderir, total_count guncellenir
        vm.toggleDistrictCheckbox('İstanbul', 'Beyoğlu');
        await tester.pump();

        final treeDistrictReq =
            requests.lastWhere((r) => r.url.path == '/places/feed');
        expect(treeDistrictReq.url.queryParameters['district'], 'Beyoğlu');
        expect(treeDistrictReq.url.queryParameters['districts'], 'Beyoğlu');
        expect(vm.geographyFilteredPlacesCount, 8);
        expect(vm.shouldShowNotFoundBannerAtEnd, isTrue);
        expect(vm.effectiveGoogleFallbackQuery, 'Beyoğlu gezilecek yerler');

        // 2. RouteFilterPillType.district hapi -> keyword'e degil districts + cities parametrelerine gider
        vm.applyFilterPills(<RouteFeedFilterPill>[
          const RouteFeedFilterPill(
            id: 'district:TR:İzmir:Konak',
            type: RouteFilterPillType.district,
            label: 'Konak',
            districtName: 'Konak',
            cityName: 'İzmir',
            countryCode: 'TR',
          ),
        ]);
        await tester.pump();

        final pillReq = requests.last;
        expect(pillReq.url.path, '/places/feed');
        expect(pillReq.url.queryParameters['districts'], contains('Konak'));
        expect(pillReq.url.queryParameters['cities'], 'İzmir');
        expect(pillReq.url.queryParameters['city'], 'İzmir');
        expect(pillReq.url.queryParameters.containsKey('q'), isFalse);
        expect(vm.geographyFilteredPlacesCount, 19);

        // 3. Arama metni ile birlesince /places/search districts parametresi alir
        vm.onSearchInputChanged('Kafe');
        expect(vm.executeTextSearchNow(), isTrue);
        await tester.pump();

        final searchReq =
            requests.lastWhere((r) => r.url.path == '/places/search');
        expect(searchReq.url.queryParameters['q'], 'Kafe');
        expect(searchReq.url.queryParameters['districts'], contains('Konak'));
        expect(vm.geographyFilteredPlacesCount, 5);
      },
    );

    testWidgets(
      'setUiCategory feed sayfalama filtresini korur, tekrar secimde temizler ve resetToGlobal sifirlar',
      (WidgetTester tester) async {
        setupWithRouter((http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            final page = int.parse(req.url.queryParameters['page'] ?? '1');
            final uiCategory = req.url.queryParameters['ui_category'];
            final totalCount = uiCategory == 'FOOD'
                ? 12
                : (uiCategory == 'ACCOMMODATION' ? 7 : 30);
            return _envelopeResponse(<String, dynamic>{
              'page': page,
              'limit': 2,
              'seed': 'cat-seed',
              'has_more': page == 1,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'cat-place-$page-${uiCategory ?? 'all'}',
                  name: uiCategory == 'FOOD'
                      ? 'Lezzet Durağı $page'
                      : 'Genel Mekan $page',
                  uiCategory: uiCategory ?? 'DESTINATION',
                ),
              ],
              'count': 1,
              'total_count': totalCount,
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        }, feedPageSize: 2);

        await vm.initializePlaces();
        expect(vm.geographyFilteredPlacesCount, 30);
        expect(vm.selectedUiCategory, isNull);

        await vm.setUiCategory('FOOD');
        expect(vm.selectedUiCategory, 'FOOD');
        expect(vm.geographyFilteredPlacesCount, 12);
        final foodReq1 = requests.lastWhere((r) => r.url.path == '/places/feed');
        expect(foodReq1.url.queryParameters['ui_category'], 'FOOD');
        expect(foodReq1.url.queryParameters['page'], '1');

        // Sayfa 2 yüklemesi ui_category filtresini korumalı
        await vm.loadMoreFeed();
        final foodReq2 = requests.lastWhere((r) => r.url.path == '/places/feed');
        expect(foodReq2.url.queryParameters['page'], '2');
        expect(foodReq2.url.queryParameters['ui_category'], 'FOOD');
        expect(vm.displayedPlaces, hasLength(2));

        // Aynı kategoriye tekrar tıklanınca 'Tümü' (null) moduna dönmeli
        await vm.setUiCategory('FOOD');
        expect(vm.selectedUiCategory, isNull);
        final clearedReq =
            requests.lastWhere((r) => r.url.path == '/places/feed');
        expect(clearedReq.url.queryParameters.containsKey('ui_category'), isFalse);
        expect(vm.geographyFilteredPlacesCount, 30);

        // Kategori aktifken resetToGlobal() kategoriyi de sıfırlamalı
        await vm.setUiCategory('ACCOMMODATION');
        expect(vm.selectedUiCategory, 'ACCOMMODATION');
        expect(vm.geographyFilteredPlacesCount, 7);

        vm.resetToGlobal();
        await tester.pump();
        expect(vm.selectedUiCategory, isNull);
        final resetReq =
            requests.lastWhere((r) => r.url.path == '/places/feed');
        expect(resetReq.url.queryParameters.containsKey('ui_category'), isFalse);
        expect(vm.geographyFilteredPlacesCount, 30);
      },
    );
  });

  // ===========================================================================
  // 4. PLACE SEARCH SCREEN WIDGET ENTEGRASYON TESTLERİ
  // ===========================================================================
  group('4. PlaceSearchScreen Widget Integration Tests (MockClient Remote Mode)', () {
    Future<({
      PlaceSearchViewModel placeVm,
      HomeFeedViewModel homeVm,
      PlacesStore store,
      BeenHereApiClient client,
    })> mountScreen(
      WidgetTester tester, {
      required Future<http.Response> Function(http.Request request) handler,
      GeographyStore? geographyStore,
    }) async {
      final mockClient = MockClient(handler);
      final client = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: mockClient,
      );
      final service = PlacesApiService(apiClient: client);
      final store = PlacesStore(apiService: service);
      final placeVm = PlaceSearchViewModel(
        placesStore: store,
        geographyStore: geographyStore,
        enableRemoteBackend: true,
      );
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
      await tester.pumpAndSettle();

      return (
        placeVm: placeVm,
        homeVm: homeVm,
        store: store,
        client: client,
      );
    }

    Future<void> unmountAndDispose(
      WidgetTester tester,
      ({
        PlaceSearchViewModel placeVm,
        HomeFeedViewModel homeVm,
        PlacesStore store,
        BeenHereApiClient client,
      }) deps,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      deps.placeVm.dispose();
      deps.homeVm.dispose();
      deps.store.dispose();
      deps.client.close();
    }

    testWidgets('GET /places/feed ile gelen mekan kartlarini render eder ve gorsel hatasinda fallback gosterir', (WidgetTester tester) async {
      final calledPaths = <String>[];
      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledPaths.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{
                'is_premium': false,
                'max_lists': 3,
                'max_places_per_list': 10,
              },
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 'feed-seed',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'place-galata',
                  name: 'Galata Kulesi',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  city: 'İstanbul',
                  averageRating: '4.9',
                  verifiedVisitCount: 120,
                  photoUrls: const <String>[],
                  communityVibes: const <String, int>{
                    'Manzaralı': 10,
                    'Tarihi': 8,
                    'Fotoğraflık': 6,
                  },
                  relatedRouteIds: const <String>['route-1', 'route-2'],
                ),
              ],
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      expect(
        calledPaths,
        containsAll(<String>['GET /places/feed', 'GET /places/lists/me']),
      );
      expect(find.byType(PlaceDiscoveryCompactCard), findsOneWidget);
      expect(find.text('Galata Kulesi'), findsOneWidget);
      expect(find.text('Türkiye, İstanbul'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.textContaining('Ziyaretçi'), findsNothing);
      expect(find.text('#Manzaralı'), findsOneWidget);
      expect(find.text('#Tarihi'), findsOneWidget);
      expect(find.text('#Fotoğraflık'), findsOneWidget);
      expect(find.text('Listeye Kaydet'), findsNothing);
      expect(find.text('Rotaya Ekle'), findsNothing);
      expect(find.text('(Taslak veya anı rotaya)'), findsNothing);
      expect(find.text('Detay / Katkı'), findsNothing);
      expect(find.byTooltip('Listeye Kaydet'), findsOneWidget);
      expect(find.byTooltip('Rotaya Ekle'), findsOneWidget);
      expect(find.byTooltip('Detay / Katkı'), findsOneWidget);
      expect(find.text('2 Rotada Geçiyor'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('PlaceDiscoveryCompactCard harici gorsel yuklenemediginde errorBuilder fallback gosterir', (WidgetTester tester) async {
      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 'feed-seed',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'place-broken-img',
                  name: 'Kız Kulesi',
                  city: 'İstanbul',
                  photoUrls: const <String>[
                    'https://example.invalid/kiz-kulesi.jpg',
                  ],
                ),
              ],
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      expect(find.text('Kız Kulesi'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('API hatasi durumunda hata kartini gosterir ve Ornek Verilerle Onizle demo moduna gecer', (WidgetTester tester) async {
      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          if (req.url.path == '/places/feed') {
            return _errorEnvelopeResponse(
              statusCode: 500,
              path: '/places/feed',
              message: 'Veritabanı bağlantısı geçici olarak kullanılamıyor.',
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      expect(find.text('Mekanlar Yüklenemedi'), findsOneWidget);
      expect(
        find.text('Veritabanı bağlantısı geçici olarak kullanılamıyor.'),
        findsOneWidget,
      );
      expect(find.text('Tekrar Dene'), findsOneWidget);
      expect(find.text('Örnek Verilerle Önizle'), findsOneWidget);

      await tester.tap(find.text('Örnek Verilerle Önizle'));
      await tester.pumpAndSettle();

      expect(find.text('Çevrimdışı örnek veriler görüntüleniyor.'), findsOneWidget);
      expect(find.text('Canlı Veriye Dön'), findsOneWidget);
      expect(find.text('Amintas Kaya Mezarları'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Detay / Katki akisi GET /places/:id, POST vibes ve POST warnings calistirip UI gunceller', (WidgetTester tester) async {
      final calledRequests = <String>[];
      Map<String, dynamic>? lastVibeBody;
      Map<String, dynamic>? lastWarningBody;

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledRequests.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'place-efes',
                  name: 'Efes Antik Kenti',
                  shortSummary: 'İlk kısa özet.',
                  communityVibes: const <String, int>{'Tarihi': 4},
                ),
              ],
            });
          }
          if (req.url.path == '/places/place-efes' && req.method == 'GET') {
            return _envelopeResponse(
              _buildPlaceJson(
                id: 'place-efes',
                name: 'Efes Antik Kenti',
                shortSummary: 'Güncel arkeolojik alan detayı.',
                communityVibes: const <String, int>{'Tarihi': 4, 'Gün Batımı': 3},
              ),
            );
          }
          if (req.url.path == '/places/place-efes/vibes' &&
              req.method == 'POST') {
            lastVibeBody = jsonDecode(req.body) as Map<String, dynamic>;
            return _envelopeResponse(
              <String, dynamic>{
                'id': 'place-efes',
                'name': 'Efes Antik Kenti',
                'short_summary': 'Güncel arkeolojik alan detayı.',
                'country_code': 'TR',
                'city': 'İzmir',
                'ui_category': 'DESTINATION',
                'average_rating': '4.85',
                'verified_visit_count': 42,
                'community_vibes': const <String, int>{
                  'Gün Batımı': 12,
                  'Tarihi': 4,
                },
              },
              statusCode: 201,
            );
          }
          if (req.url.path == '/places/place-efes/warnings' &&
              req.method == 'POST') {
            lastWarningBody = jsonDecode(req.body) as Map<String, dynamic>;
            return _envelopeResponse(
              <String, dynamic>{
                'id': 'place-efes',
                'name': 'Efes Antik Kenti',
                'short_summary': 'Güncel arkeolojik alan detayı.',
                'country_code': 'TR',
                'city': 'İzmir',
                'ui_category': 'DESTINATION',
                'average_rating': '4.85',
                'verified_visit_count': 42,
                'status': 'OPERATIONAL',
                'community_vibes': const <String, int>{
                  'Gün Batımı': 12,
                  'Tarihi': 4,
                },
                'community_warnings': const <String, int>{
                  'Nakit Gerekli': 5,
                },
              },
              statusCode: 201,
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      final detailButton = find.byTooltip('Detay / Katkı');
      await tester.ensureVisible(detailButton);
      await tester.pumpAndSettle();
      await tester.tap(detailButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('GET /places/place-efes'));
      expect(find.text('Güncel arkeolojik alan detayı.'), findsNWidgets(2));
      expect(find.text('#Gün Batımı (3)'), findsOneWidget);

      // Vibe seç ve "Vibe Oyla" butonuna bas
      final sunsetChip = find.widgetWithText(FilterChip, 'Gün Batımı');
      await tester.ensureVisible(sunsetChip);
      await tester.tap(sunsetChip);
      await tester.pump();

      final voteVibeButton = find.widgetWithText(FilledButton, 'Vibe Oyla');
      await tester.ensureVisible(voteVibeButton);
      await tester.tap(voteVibeButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/place-efes/vibes'));
      expect(lastVibeBody, <String, dynamic>{
        'vibes': <String>['Gün Batımı'],
      });
      expect(find.text('#Gün Batımı (12)'), findsOneWidget);
      expect(find.text('Vibe oylamanız kaydedildi!'), findsOneWidget);

      // Uyarı seç ve "Uyarı Bildir" butonuna bas
      final cashWarningChip = find.widgetWithText(FilterChip, 'Nakit Gerekli');
      await tester.ensureVisible(cashWarningChip);
      await tester.tap(cashWarningChip);
      await tester.pump();

      final reportWarningButton =
          find.widgetWithText(OutlinedButton, 'Uyarı Bildir');
      await tester.ensureVisible(reportWarningButton);
      await tester.tap(reportWarningButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/place-efes/warnings'));
      expect(lastWarningBody, <String, dynamic>{
        'warnings': <String>['Nakit Gerekli'],
      });
      expect(find.text('Nakit Gerekli (5 oy)'), findsOneWidget);
      expect(find.text('Saha uyarınız toplulukla paylaşıldı!'), findsOneWidget);

      // Modal kapatıldığında arkadaki PlaceDiscoveryCompactCard da güncel vibe ve uyarıyı göstermeli
      Navigator.of(
        tester.element(find.text('Saha uyarınız toplulukla paylaşıldı!')),
      ).pop();
      await tester.pumpAndSettle();

      expect(find.text('#Gün Batımı'), findsOneWidget);
      expect(
        find.text('Gezgin Saha Uyarısı: Nakit Gerekli (5 oy)'),
        findsOneWidget,
      );

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Kompakt kartta Benzer Lokasyonlar yer almaz ve ilintili rotalar GET /places/:id/routes tetikler', (WidgetTester tester) async {
      final calledPaths = <String>[];
      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledPaths.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'place-sirince',
                  name: 'Şirince Köyü',
                  relatedRouteIds: const <String>['route-ege-1'],
                ),
              ],
            });
          }
          if (req.url.path == '/places/place-sirince/routes') {
            return _envelopeResponse(<String, dynamic>{
              'place_id': 'place-sirince',
              'page': 1,
              'limit': 10,
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildRouteJson(
                  id: 'route-ege-1',
                  title: 'İzmir & Efes Bağ Yolu',
                  durationDays: 3,
                  estimatedTotalBudgetUsd: 350,
                  totalStopsCount: 5,
                ),
              ],
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      // 1. Kompakt kartta Benzer Lokasyonlar bölümü yer almamalı
      expect(find.textContaining('Benzer Lokasyonlar'), findsNothing);
      expect(calledPaths, isNot(contains('GET /places/place-sirince/nearby')));

      // 2. İlintili rotalar metnine dokun -> GET /places/place-sirince/routes
      final relatedRoutesButton = find.text('1 Rotada Geçiyor');
      await tester.ensureVisible(relatedRoutesButton);
      await tester.pumpAndSettle();
      await tester.tap(relatedRoutesButton);
      await tester.pumpAndSettle();

      expect(calledPaths, contains('GET /places/place-sirince/routes'));
      expect(find.text('İzmir & Efes Bağ Yolu'), findsOneWidget);
      expect(find.text('3 Gün'), findsOneWidget);
      expect(find.text('• \$350'), findsOneWidget);
      expect(find.text('• 5 Durak'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Flag modali Liste Icerigini Gor, yeni liste olusturma ve liste silme akislarini calistirir', (WidgetTester tester) async {
      final calledRequests = <String>[];
      final lists = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'list-existing',
          'title': 'Ege Koyları',
          'icon': '🌊',
          'place_ids': <String>['place-other'],
          'item_count': 1,
          'max_places_per_list': 10,
        },
      ];

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledRequests.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': lists,
              'count': lists.length,
              'suggested_next_title': 'Favori Liste ${lists.length + 1}',
              'quota': <String, dynamic>{
                'is_premium': false,
                'max_lists': 3,
                'max_places_per_list': 10,
              },
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'place-cesme', name: 'Çeşme Kalesi'),
              ],
            });
          }
          if (req.url.path == '/places/lists/list-existing' &&
              req.method == 'GET') {
            return _envelopeResponse(<String, dynamic>{
              'id': 'list-existing',
              'title': 'Ege Koyları',
              'icon': '🌊',
              'item_count': 1,
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'item-1',
                  'list_id': 'list-existing',
                  'place_id': 'place-other',
                  'place': _buildPlaceJson(
                    id: 'place-other',
                    name: 'Delikli Koy',
                  ),
                },
              ],
            });
          }
          if (req.url.path == '/places/lists' && req.method == 'POST') {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final created = <String, dynamic>{
              'id': 'list-created',
              'title': body['title'] ?? 'Favori Liste 2',
              'icon': body['icon'] ?? '🚩',
              'place_ids': <String>[],
              'item_count': 0,
              'max_places_per_list': 10,
            };
            lists.add(created);
            return _envelopeResponse(created, statusCode: 201);
          }
          if (req.url.path == '/places/lists/list-created/items' &&
              req.method == 'POST') {
            return _envelopeResponse(
              <String, dynamic>{
                'id': 'item-created',
                'list_id': 'list-created',
                'place_id': 'place-cesme',
              },
              statusCode: 201,
            );
          }
          if (req.url.path == '/places/lists/list-created' &&
              req.method == 'DELETE') {
            lists.removeWhere((l) => l['id'] == 'list-created');
            return _envelopeResponse(<String, dynamic>{'deleted': true});
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      // Flag modalını aç
      await tester.tap(find.byTooltip('Listeye Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Ege Koyları'), findsOneWidget);
      expect(find.text('Free Plan: 1/3 Liste • Maks. 10 mekan/liste'), findsOneWidget);

      // "Liste İçeriğini Gör" -> GET /places/lists/list-existing
      await tester.tap(find.byTooltip('Liste İçeriğini Gör').first);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('GET /places/lists/list-existing'));
      expect(find.text('• Delikli Koy'), findsOneWidget);

      // Yeni liste oluştur -> POST /places/lists + POST /places/lists/list-created/items
      final listTitleField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.startsWith('+ Yeni liste') ?? false),
      );
      await tester.ensureVisible(listTitleField);
      await tester.enterText(listTitleField, 'Hafta Sonu Kaçamağı');
      await tester.pump();

      final createButton = find.widgetWithText(FilledButton, 'Oluştur');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/lists'));
      expect(calledRequests, contains('POST /places/lists/list-created/items'));
      expect(find.text('Hafta Sonu Kaçamağı'), findsOneWidget);
      expect(find.text('Free Plan: 2/3 Liste • Maks. 10 mekan/liste'), findsOneWidget);

      // Oluşturulan listeyi sil -> DELETE /places/lists/list-created
      final deleteLastListButton = find.byTooltip('Listeyi Sil').last;
      await tester.ensureVisible(deleteLastListButton);
      await tester.tap(deleteLastListButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('DELETE /places/lists/list-created'));
      expect(find.text('Hafta Sonu Kaçamağı'), findsNothing);
      expect(find.text('Free Plan: 1/3 Liste • Maks. 10 mekan/liste'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Google Maps fallback karti >= 3 karakterde POST /places/fetch-google tetikler', (WidgetTester tester) async {
      final calledRequests = <String>[];
      Map<String, dynamic>? googleFetchBody;

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledRequests.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'feed-1', name: 'Galata Kulesi'),
              ],
            });
          }
          if (req.url.path == '/places/search') {
            return _envelopeResponse(<String, dynamic>{
              'search_mode': 'GLOBAL',
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'can_fetch_from_google': true,
              'min_google_query_length': 3,
              'google_fetch_prompt':
                  'Aradığınız mekanı bulamadınız mı? Google Haritalar\'da Ara',
            });
          }
          if (req.url.path == '/places/fetch-google' && req.method == 'POST') {
            googleFetchBody = jsonDecode(req.body) as Map<String, dynamic>;
            return _envelopeResponse(
              <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'gp-pamukkale',
                  name: 'Pamukkale Travertenleri',
                  city: 'Denizli',
                ),
              ],
              statusCode: 201,
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      // 1. Arama çubuğuna dokun -> BeenHereSearchPanel üzerinden < 3 karakter ("Ab") ara
      await tester.tap(find.text('Ülke, konum veya şehir ismi ile ara...'));
      await tester.pumpAndSettle();
      expect(find.byType(BeenHereSearchPanel), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(BeenHereSearchPanel),
          matching: find.byType(TextField),
        ),
        'Ab',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Arama'));
      await tester.pumpAndSettle();

      // 2 karakterle Google Maps butonuna basıldığında istek atılmamalı ve uyarı gösterilmeli
      expect(find.text('Aradığınız mekanı bulamadınız mı?'), findsOneWidget);
      await tester.tap(find.text('Google Haritalar\'da Ara'));
      await tester.pumpAndSettle();

      expect(calledRequests, isNot(contains('POST /places/fetch-google')));
      expect(
        find.text(
          '⚠️ Google Haritalar araması için lütfen en az 3 karakter girin.',
        ),
        findsOneWidget,
      );

      // Açık SnackBar'ı kapat ki sonraki ekrandaki alt aksiyon butonunu engellemesin
      ScaffoldMessenger.of(
        tester.element(find.byType(PlaceSearchScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // 2. Önceki kısa kelime hapını temizle ve >= 3 karakter ("Pamukkale Travertenleri") ara
      await tester.tap(find.byKey(const ValueKey<String>('remove_pill_keyword:ab')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ülke, konum veya şehir ismi ile ara...'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(BeenHereSearchPanel),
          matching: find.byType(TextField),
        ),
        'Pamukkale Travertenleri',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Arama'));
      await tester.pumpAndSettle();

      final googleButton = find.text(
        '"Pamukkale Travertenleri" İçin Google Haritalar\'da Ara',
      );
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/fetch-google'));
      expect(googleFetchBody, <String, dynamic>{
        'query': 'Pamukkale Travertenleri',
        'search_mode': 'GLOBAL',
        'lang': 'tr',
      });
      expect(find.text('Pamukkale Travertenleri'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Aktif konum filtresi ile Google fallback turetir ve POST /places/fetch-google gonderir', (WidgetTester tester) async {
      final calledRequests = <String>[];
      Map<String, dynamic>? googleFetchBody;

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledRequests.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(id: 'feed-1', name: 'Galata Kulesi'),
              ],
            });
          }
          if (req.url.path == '/places/fetch-google' && req.method == 'POST') {
            googleFetchBody = jsonDecode(req.body) as Map<String, dynamic>;
            return _envelopeResponse(
              <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'gp-marmaris-1',
                  name: 'Marmaris Kalesi',
                  city: 'Marmaris',
                ),
              ],
              statusCode: 201,
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      // Arama panelinden konum filtresi olarak "Marmaris" sec
      await tester.tap(find.text('Ülke, konum veya şehir ismi ile ara...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marmaris').first);
      await tester.pump();
      await tester.tap(find.text('Arama (1)'));
      await tester.pumpAndSettle();

      final googleButton = find.text(
        '"Marmaris gezilecek yerler" İçin Google Haritalar\'da Ara',
      );
      await tester.scrollUntilVisible(
        googleButton,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey<String>('place-search-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/fetch-google'));
      expect(googleFetchBody, <String, dynamic>{
        'query': 'Marmaris gezilecek yerler',
        'search_mode': 'GLOBAL',
        'lang': 'tr',
      });
      expect(find.text('Marmaris Kalesi'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Bos remote sonuclarda Google fallback karti gosterir ve Populer Turistik Mekanlar sorgusu atar', (WidgetTester tester) async {
      final calledRequests = <String>[];
      Map<String, dynamic>? googleFetchBody;

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          calledRequests.add('${req.method} ${req.url.path}');
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's1',
              'has_more': false,
              'items': <Map<String, dynamic>>[],
            });
          }
          if (req.url.path == '/places/fetch-google' && req.method == 'POST') {
            googleFetchBody = jsonDecode(req.body) as Map<String, dynamic>;
            return _envelopeResponse(
              <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'gp-populer-1',
                  name: 'Ayasofya Camii',
                  city: 'İstanbul',
                ),
              ],
              statusCode: 201,
            );
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      expect(
        find.text('Seçilen bölge/şehir filtresinde henüz keşif noktası bulunmuyor.'),
        findsNothing,
      );
      expect(find.text('Aradığınız mekanı bulamadınız mı?'), findsOneWidget);

      final googleButton = find.text(
        '"Popüler Turistik Mekanlar" İçin Google Haritalar\'da Ara',
      );
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(calledRequests, contains('POST /places/fetch-google'));
      expect(googleFetchBody, <String, dynamic>{
        'query': 'Popüler Turistik Mekanlar',
        'search_mode': 'GLOBAL',
        'lang': 'tr',
      });
      expect(find.text('Ayasofya Camii'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    testWidgets('Kategori filtre bari ui_category gonderir ve backend total_count degerini UI da gosterir', (WidgetTester tester) async {
      final feedRequests = <http.Request>[];

      final deps = await mountScreen(
        tester,
        handler: (http.Request req) async {
          if (req.url.path == '/places/lists/me') {
            return _envelopeResponse(<String, dynamic>{
              'items': <Map<String, dynamic>>[],
              'count': 0,
              'suggested_next_title': 'Favori Liste 1',
              'quota': <String, dynamic>{'is_premium': false},
            });
          }
          if (req.url.path == '/places/feed') {
            feedRequests.add(req);
            final uiCategory = req.url.queryParameters['ui_category'];
            if (uiCategory == 'FOOD') {
              return _envelopeResponse(<String, dynamic>{
                'page': 1,
                'limit': 10,
                'seed': 's-food',
                'has_more': false,
                'items': <Map<String, dynamic>>[
                  _buildPlaceJson(
                    id: 'place-food-1',
                    name: 'Tarihi Kemeraltı Lokantası',
                    uiCategory: 'FOOD',
                    city: 'İzmir',
                  ),
                ],
                'count': 1,
                'total_count': 17,
              });
            }
            return _envelopeResponse(<String, dynamic>{
              'page': 1,
              'limit': 10,
              'seed': 's-all',
              'has_more': false,
              'items': <Map<String, dynamic>>[
                _buildPlaceJson(
                  id: 'place-dest-1',
                  name: 'Galata Kulesi',
                  uiCategory: 'DESTINATION',
                  city: 'İstanbul',
                ),
              ],
              'count': 1,
              'total_count': 42,
            });
          }
          return _envelopeResponse(<String, dynamic>{});
        },
      );

      // 1. Kategori barı tüm seçeneklerle görünmeli ve ilk total_count = 42 olmalı
      expect(find.text('Tümü'), findsOneWidget);
      expect(find.text('Tarihi & Keşif'), findsOneWidget);
      expect(find.text('Yeme & İçme'), findsOneWidget);
      expect(find.text('Konaklama'), findsOneWidget);
      expect(find.text('Aktivite'), findsOneWidget);
      expect(deps.placeVm.geographyFilteredPlacesCount, 42);
      expect(find.text('Galata Kulesi'), findsOneWidget);

      // 2. "Yeme & İçme" chip'ine dokun -> ui_category=FOOD gider ve total_count=17 UI'da görünür
      await tester.tap(
        find.byKey(const ValueKey<String>('place_category_chip_FOOD')),
      );
      await tester.pumpAndSettle();

      expect(deps.placeVm.selectedUiCategory, 'FOOD');
      expect(feedRequests.last.url.queryParameters['ui_category'], 'FOOD');
      expect(find.text('Tarihi Kemeraltı Lokantası'), findsOneWidget);
      expect(deps.placeVm.geographyFilteredPlacesCount, 17);

      // Coğrafya çekmecesi içinde "Uygula (17 Mekan)" olarak total_count görünmeli
      await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
      await tester.pumpAndSettle();
      expect(find.text('Uygula (17 Mekan)'), findsOneWidget);

      await tester.tap(find.text('Uygula (17 Mekan)'));
      await tester.pumpAndSettle();

      // 3. "Tümü" chip'ine dokununca ui_category temizlenir
      await tester.tap(
        find.byKey(const ValueKey<String>('place_category_chip_ALL')),
      );
      await tester.pumpAndSettle();

      expect(deps.placeVm.selectedUiCategory, isNull);
      expect(feedRequests.last.url.queryParameters.containsKey('ui_category'), isFalse);
      expect(deps.placeVm.geographyFilteredPlacesCount, 42);
      expect(find.text('Galata Kulesi'), findsOneWidget);

      await unmountAndDispose(tester, deps);
    });

    Future<GeographyStore> createLoadedGeographyStore() async {
      final geoClient = MockClient((http.Request req) async {
        if (req.url.path == '/geography/tree') {
          return _envelopeResponse(<String, dynamic>{
            'lang': 'tr',
            'global_option': <String, dynamic>{
              'code': 'GLOBAL',
              'name': 'Global',
              'default_name': 'Global',
              'name_translations': <String, String>{'tr': 'Global'},
              'places_count': 42,
              'routes_count': 10,
            },
            'continents': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cont-europe',
                'code': 'EUROPE',
                'name': 'Avrupa',
                'default_name': 'Avrupa',
                'name_translations': <String, String>{'tr': 'Avrupa'},
                'image_url': 'https://cdn.beenhere.dev/geo/europe.jpg',
                'places_count': 18,
                'routes_count': 6,
                'regions': const <Map<String, dynamic>>[],
                'countries': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'country-tr',
                    'code': 'TR',
                    'continent_code': 'EUROPE',
                    'name': 'Türkiye',
                    'default_name': 'Türkiye',
                    'name_translations': <String, String>{'tr': 'Türkiye'},
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
                        'name_translations': <String, String>{'tr': 'İzmir'},
                        'image_url': 'https://cdn.beenhere.dev/geo/izmir.jpg',
                        'is_popular': true,
                        'places_count': 6,
                        'routes_count': 2,
                        'districts': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'id': 'dist-konak',
                            'slug': 'tr:izmir:konak',
                            'city_slug': 'tr:izmir',
                            'country_code': 'TR',
                            'name': 'Konak',
                            'default_name': 'Konak',
                            'name_translations': <String, String>{
                              'tr': 'Konak',
                            },
                            'places_count': 3,
                          },
                          <String, dynamic>{
                            'id': 'dist-urla',
                            'slug': 'tr:izmir:urla',
                            'city_slug': 'tr:izmir',
                            'country_code': 'TR',
                            'name': 'Urla',
                            'default_name': 'Urla',
                            'name_translations': <String, String>{
                              'tr': 'Urla',
                            },
                            'places_count': 2,
                          },
                        ],
                      },
                    ],
                  },
                  <String, dynamic>{
                    'id': 'country-hr',
                    'code': 'HR',
                    'continent_code': 'EUROPE',
                    'name': 'Hırvatistan',
                    'default_name': 'Hırvatistan',
                    'name_translations': <String, String>{'tr': 'Hırvatistan'},
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
              'cities': const <Map<String, dynamic>>[],
              'regions': const <Map<String, dynamic>>[],
              'continents': const <Map<String, dynamic>>[],
            },
          });
        }
        return _envelopeResponse(<String, dynamic>{});
      });

      final geoApiClient = BeenHereApiClient(
        baseUrl: 'http://localhost:3000',
        client: geoClient,
      );
      addTearDown(geoApiClient.close);
      final geoStore = GeographyStore(
        apiService: GeographyApiService(apiClient: geoApiClient),
      );
      await geoStore.ensureLoaded(lang: 'tr');
      return geoStore;
    }

    testWidgets(
      'Cekmece acikken coklu secimlerde 0 backend istegi atar, canli sayim hesaplar ve X ile iptalde eski filtreye doner',
      (WidgetTester tester) async {
        final geoStore = await createLoadedGeographyStore();
        addTearDown(geoStore.dispose);

        final placeQueryRequests = <http.Request>[];
        final deps = await mountScreen(
          tester,
          geographyStore: geoStore,
          handler: (http.Request req) async {
            if (req.url.path == '/places/lists/me') {
              return _envelopeResponse(<String, dynamic>{
                'items': <Map<String, dynamic>>[],
                'count': 0,
                'suggested_next_title': 'Favori Liste 1',
                'quota': <String, dynamic>{'is_premium': false},
              });
            }
            if (req.url.path == '/places/feed' ||
                req.url.path == '/places/search') {
              placeQueryRequests.add(req);
              final countries = req.url.queryParameters['country_codes'] ?? '';
              return _envelopeResponse(<String, dynamic>{
                'page': 1,
                'limit': 10,
                'seed': 's-draft',
                'has_more': false,
                'items': <Map<String, dynamic>>[
                  _buildPlaceJson(
                    id: 'place-draft-1',
                    name: countries == 'HR'
                        ? 'Dubrovnik Surları'
                        : 'Galata Kulesi',
                  ),
                ],
                'count': 1,
                'total_count': countries == 'HR' ? 4 : 42,
              });
            }
            return _envelopeResponse(<String, dynamic>{});
          },
        );

        // Başlangıç aktif filtresi olarak Hırvatistan'ı uygula
        deps.placeVm.toggleCountryCheckbox('HR');
        await tester.pumpAndSettle();
        expect(deps.placeVm.selectedFullCountryCodes, <String>{'HR'});
        expect(deps.placeVm.geographyFilteredPlacesCount, 4);

        final requestsBeforeDrawer = placeQueryRequests.length;

        // 1. Çekmeceyi aç -> 0 ek backend isteği
        await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
        await tester.pumpAndSettle();
        expect(placeQueryRequests.length, requestsBeforeDrawer);
        expect(find.text('Uygula (4 Mekan)'), findsOneWidget);

        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        // 2. Kıta > Ülke > Şehir aç, birden fazla ilçe/ülke/kıta seç -> her adımda 0 istek, anlık sayaç güncellenir
        await tapVisible(find.text(ContinentFilter.europe.label));
        await tapVisible(find.text('🇹🇷 Türkiye'));
        await tapVisible(find.text('İzmir'));

        await tapVisible(find.text('Konak (3)'));
        expect(find.text('Uygula (7 Mekan)'), findsOneWidget);

        await tapVisible(find.text('Urla (2)'));
        expect(find.text('Uygula (9 Mekan)'), findsOneWidget);

        final trCheckbox = find.descendant(
          of: find.ancestor(
            of: find.text('🇹🇷 Türkiye'),
            matching: find.byType(Row),
          ),
          matching: find.byType(Checkbox),
        );
        await tapVisible(trCheckbox);
        expect(find.text('Uygula (14 Mekan)'), findsOneWidget);

        final europeCheckbox = find.descendant(
          of: find.ancestor(
            of: find.text(ContinentFilter.europe.label),
            matching: find.byType(Row),
          ),
          matching: find.byType(Checkbox),
        );
        await tapVisible(europeCheckbox);
        expect(find.text('Uygula (18 Mekan)'), findsOneWidget);

        expect(placeQueryRequests.length, requestsBeforeDrawer);

        // 3. X butonuyla çekmeceyi kapat -> önceki HR seçimine geri döner ve 0 istek atar
        await tester.tap(
          find.descendant(
            of: find.byType(IconButton),
            matching: find.byIcon(Icons.close_rounded),
          ),
        );
        await tester.pumpAndSettle();

        expect(placeQueryRequests.length, requestsBeforeDrawer);
        expect(deps.placeVm.selectedFullContinents, isEmpty);
        expect(deps.placeVm.selectedFullCountryCodes, <String>{'HR'});
        expect(deps.placeVm.selectedDistricts, isEmpty);
        expect(deps.placeVm.geographyFilteredPlacesCount, 4);

        await unmountAndDispose(tester, deps);
      },
    );

    testWidgets(
      'Cekmecede degisiklik yoksa Uygula 0 ek istek atar, coklu secim ve Global e Don tek 1 istek ile uygulanir',
      (WidgetTester tester) async {
        final geoStore = await createLoadedGeographyStore();
        addTearDown(geoStore.dispose);

        final placeQueryRequests = <http.Request>[];
        final deps = await mountScreen(
          tester,
          geographyStore: geoStore,
          handler: (http.Request req) async {
            if (req.url.path == '/places/lists/me') {
              return _envelopeResponse(<String, dynamic>{
                'items': <Map<String, dynamic>>[],
                'count': 0,
                'suggested_next_title': 'Favori Liste 1',
                'quota': <String, dynamic>{'is_premium': false},
              });
            }
            if (req.url.path == '/places/feed' ||
                req.url.path == '/places/search') {
              placeQueryRequests.add(req);
              final districts = req.url.queryParameters['districts'] ?? '';
              final uiCategory = req.url.queryParameters['ui_category'];
              final totalCount = districts.contains('Konak')
                  ? 9
                  : (uiCategory == 'FOOD' ? 17 : 42);
              return _envelopeResponse(<String, dynamic>{
                'page': 1,
                'limit': 10,
                'seed': 's-commit',
                'has_more': false,
                'items': <Map<String, dynamic>>[
                  _buildPlaceJson(id: 'place-commit-1', name: 'Galata Kulesi'),
                ],
                'count': 1,
                'total_count': totalCount,
              });
            }
            return _envelopeResponse(<String, dynamic>{});
          },
        );

        placeQueryRequests.clear();

        // 1. Hiç seçim değiştirmeden aç & Uygula bas -> 0 ek istek
        await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Uygula (42 Mekan)'));
        await tester.pumpAndSettle();
        expect(placeQueryRequests, isEmpty);

        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        // 2. Çekmecede birden fazla seçim yap ve Uygula'ya bas -> yalnızca 1 istek gider
        await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
        await tester.pumpAndSettle();

        await tapVisible(find.text(ContinentFilter.europe.label));
        await tapVisible(find.text('🇹🇷 Türkiye'));
        await tapVisible(find.text('İzmir'));
        await tapVisible(find.text('Konak (3)'));
        await tapVisible(find.text('Urla (2)'));

        final hrCheckbox = find.descendant(
          of: find.ancestor(
            of: find.text('🇭🇷 Hırvatistan'),
            matching: find.byType(Row),
          ),
          matching: find.byType(Checkbox),
        );
        await tapVisible(hrCheckbox);

        expect(placeQueryRequests, isEmpty);
        expect(find.text('Uygula (9 Mekan)'), findsOneWidget);

        await tester.tap(find.text('Uygula (9 Mekan)'));
        await tester.pumpAndSettle();

        expect(placeQueryRequests, hasLength(1));
        final committedReq = placeQueryRequests.single;
        expect(committedReq.url.path, '/places/feed');
        expect(committedReq.url.queryParameters['country_code'], 'HR');
        expect(committedReq.url.queryParameters['country_codes'], 'HR');
        expect(committedReq.url.queryParameters['districts'], contains('Konak'));
        expect(committedReq.url.queryParameters['districts'], contains('Urla'));

        // 3. Kategori aktifken çekmecede Global'e Dön + X rollback -> uiCategory korunur, 0 istek
        await tester.tap(
          find.byKey(const ValueKey<String>('place_category_chip_FOOD')),
        );
        await tester.pumpAndSettle();
        expect(deps.placeVm.selectedUiCategory, 'FOOD');
        placeQueryRequests.clear();

        await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Global\'e Dön'));
        await tester.pumpAndSettle();

        expect(deps.placeVm.selectedUiCategory, isNull);
        expect(placeQueryRequests, isEmpty);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(deps.placeVm.selectedUiCategory, 'FOOD');
        expect(deps.placeVm.selectedFullCountryCodes, <String>{'HR'});
        expect(placeQueryRequests, isEmpty);

        // 4. Global'e Dön + Uygula -> uiCategory ve coğrafya tek 1 istekle temizlenir
        await tester.tap(find.byTooltip('Bölge, Ülke ve Şehir Filtresi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Global\'e Dön'));
        await tester.pumpAndSettle();
        expect(find.text('Uygula (42 Mekan)'), findsOneWidget);

        await tester.tap(find.text('Uygula (42 Mekan)'));
        await tester.pumpAndSettle();

        expect(placeQueryRequests, hasLength(1));
        expect(
          placeQueryRequests.single.url.queryParameters.containsKey('ui_category'),
          isFalse,
        );
        expect(
          placeQueryRequests.single.url.queryParameters.containsKey('districts'),
          isFalse,
        );
        expect(deps.placeVm.selectedUiCategory, isNull);

        await unmountAndDispose(tester, deps);
      },
    );
  });

  // ===========================================================================
  // 5. PLACE DISCOVERY COMPACT CARD & ESKİ KART KORUMA TESTLERİ
  // ===========================================================================
  group('5. PlaceDiscoveryCompactCard Responsive, Fotoğraf Sayısı & Eski Kart Koruma Testleri', () {
    Widget wrapCard({
      required Widget child,
      required double width,
    }) {
      return MaterialApp(
        theme: BeenHereThemeController.instance.isDark
            ? BeenHereTheme.darkTheme
            : BeenHereTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Dar ekran (375px) + 1/2/3+ fotoğraf slider + şeffaf akış + gezgin atıfı + ikon aksiyonlar overflow olmadan render edilir',
      (WidgetTester tester) async {
        final singlePhotoPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-1-photo',
            name: 'Big Ben',
            countryCode: 'GB',
            countryName: 'İngiltere',
            city: 'Londra',
            averageRating: '4.9',
            verifiedVisitCount: 185,
            photoUrls: const <String>[
              'https://example.invalid/big-ben-1.jpg',
            ],
            communityVibes: const <String, int>{
              'Tarihi': 14,
              'İkonik': 9,
              'Fotoğraflık': 6,
            },
          ),
        );

        final twoPhotoPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-2-photos',
            name: 'Çok Uzun Tarihi Antik Tiyatro ve Panoramik Seyir Terası Kompleksi',
            countryCode: 'TR',
            countryName: 'Türkiye',
            city: 'Antalya / Kaş',
            averageRating: '4.8',
            verifiedVisitCount: 95,
            distanceKm: 2.4,
            photoUrls: const <String>[
              'https://example.invalid/photo-1.jpg',
              'https://example.invalid/photo-2.jpg',
            ],
            communityVibes: const <String, int>{
              'PanoramikGünBatımıManzarası': 10,
              'Sessiz': 7,
              'Fotoğraflık': 5,
            },
            status: 'CLOSED_TEMPORARILY',
            relatedRouteIds: const <String>['r1', 'r2'],
          ),
        );

        final threePhotoPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-3-photos',
            name: 'Efes Antik Kenti',
            countryCode: 'TR',
            countryName: 'Türkiye',
            city: 'İzmir',
            averageRating: '4.9',
            verifiedVisitCount: 310,
            photoUrls: const <String>[
              'https://example.invalid/efes-1.jpg',
              'https://example.invalid/efes-2.jpg',
              'https://example.invalid/efes-3.jpg',
            ],
            isFlagged: true,
          ),
        );

        // 1. 1 fotoğraf — dar ekran (375px), şeffaf arka plan + ayırıcı, tam genişlik slider, sol sütunda puanlama
        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: singlePhotoPlace,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final singlePageView = tester.widget<PageView>(find.byType(PageView));
        expect(singlePageView.controller?.viewportFraction, closeTo(1.0, 0.001));
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(Divider), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).boxShadow != null,
          ),
          findsNothing,
        );
        expect(
          find.text(singlePhotoPlace.photoAuthorForIndex(0)),
          findsOneWidget,
        );
        expect(find.text('Big Ben'), findsOneWidget);
        expect(find.text('İngiltere, Londra'), findsOneWidget);
        expect(find.text('4.9'), findsOneWidget);
        expect(find.textContaining('Ziyaretçi'), findsNothing);
        expect(find.textContaining('Benzer Lokasyonlar'), findsNothing);
        expect(find.text('Listeye Kaydet'), findsNothing);
        expect(find.text('Rotaya Ekle'), findsNothing);
        expect(find.text('(Taslak veya anı rotaya)'), findsNothing);
        expect(find.text('Detay / Katkı'), findsNothing);
        expect(find.byTooltip('Listeye Kaydet'), findsOneWidget);
        expect(find.byTooltip('Rotaya Ekle'), findsOneWidget);
        expect(find.byTooltip('Detay / Katkı'), findsOneWidget);
        for (final keyId in <String>[
          'compact-flag-button-compact-1-photo',
          'compact-add-to-route-button-compact-1-photo',
          'compact-detail-button-compact-1-photo',
        ]) {
          final btnFinder = find.byKey(ValueKey<String>(keyId));
          expect(btnFinder, findsOneWidget);
          expect(tester.getSize(btnFinder), const Size(27, 27));
          final btnMaterial = tester.widget<Material>(btnFinder);
          expect(btnMaterial.color, Colors.transparent);
          expect(
            find.descendant(
              of: btnFinder,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).border != null,
              ),
            ),
            findsNothing,
          );
        }
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is PhosphorIcon &&
                w.icon == PhosphorIcons.flag(PhosphorIconsStyle.regular),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // 2. 2 fotoğraf + uzun isim + uzun etiket + uyarı + mesafe — dar ekran (375px) & Light tema
        BeenHereThemeController.instance.setLight();
        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: twoPhotoPlace,
              showDistanceBadge: true,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapRelatedRoutesButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final multiPageView = tester.widget<PageView>(find.byType(PageView));
        expect(multiPageView.controller?.viewportFraction, closeTo(0.80, 0.001));
        final twoPhotoSliderFinder = find.byKey(
          ValueKey<String>('compact-photo-slider-${twoPhotoPlace.id}'),
        );
        expect(twoPhotoSliderFinder, findsOneWidget);
        expect(tester.getSize(twoPhotoSliderFinder).height, 208);
        expect(find.byType(Image), findsNWidgets(2));
        final activeSlideHeight =
            tester.getSize(find.byType(Image).at(0)).height;
        final previewSlideHeight =
            tester.getSize(find.byType(Image).at(1)).height;
        expect(activeSlideHeight, 208);
        expect(previewSlideHeight, 180);
        expect(activeSlideHeight, greaterThan(previewSlideHeight));
        expect(
          find.text(twoPhotoPlace.photoAuthorForIndex(0)),
          findsOneWidget,
        );
        expect(
          find.text(twoPhotoPlace.photoAuthorForIndex(1)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: twoPhotoSliderFinder,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is PhosphorIcon &&
                  w.icon == PhosphorIcons.warning(PhosphorIconsStyle.fill),
            ),
          ),
          findsNothing,
        );
        expect(find.text(twoPhotoPlace.statusWarning!), findsOneWidget);
        expect(find.text('4.8'), findsOneWidget);
        expect(find.text('2.4 km'), findsOneWidget);
        expect(find.text('2 Rotada Geçiyor'), findsOneWidget);
        expect(find.textContaining('Ziyaretçi'), findsNothing);
        expect(tester.takeException(), isNull);

        // 3. 3 fotoğraf + listede durumu — yatay kaydırmada 3. foto atıfı görünmeli ve yalnızca ikonlar olmalı
        BeenHereThemeController.instance.setDark();
        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: threePhotoPlace,
              savedLists: const <UserFavoritePlaceList>[
                UserFavoritePlaceList(
                  id: 'list-1',
                  title: 'Ege',
                  iconEmoji: '🚩',
                  placeIds: <String>['compact-3-photos'],
                ),
              ],
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Listede (1)'), findsOneWidget);
        expect(find.text('Listede'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is PhosphorIcon &&
                w.icon == PhosphorIcons.flag(PhosphorIconsStyle.fill),
          ),
          findsOneWidget,
        );
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(0)),
          findsOneWidget,
        );
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(1)),
          findsNothing,
        );
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(2)),
          findsNothing,
        );

        // 1. kez sola kaydır -> index 1 ana slayt olunca sadece 2. foto atıfı görünmeli
        await tester.drag(find.byType(PageView), const Offset(-200, 0));
        await tester.pumpAndSettle();
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(1)),
          findsOneWidget,
        );
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(0)),
          findsNothing,
        );
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(2)),
          findsNothing,
        );

        // 2. kez sola kaydır -> index 2 ana slayt olunca 3. foto atıfı görünmeli
        await tester.drag(find.byType(PageView), const Offset(-200, 0));
        await tester.pumpAndSettle();
        expect(
          find.text(threePhotoPlace.photoAuthorForIndex(2)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Açıklama başlık/konum altında tam genişlikte görünür; uzun açıklamalar 375px ekranda Devamını Oku / Daha Az Göster ile açılıp kapanır',
      (WidgetTester tester) async {
        const shortSummary =
            'Boğaz kıyısında gün batımı eşliğinde kahve içebileceğiniz sakin nokta.';
        const longSummary =
            'Antik dönemden günümüze uzanan taş sokakları, zeytin ağaçlarıyla çevrili manzaralı seyir terasları, yerel butik kafeleri ve gün batımında altın rengine bürünen tarihi taş evleriyle yürüyerek keşfetmeye çok uygun büyüleyici bir durak.';

        final shortDescPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-short-desc',
            name: 'Bebek Sahili',
            countryCode: 'TR',
            countryName: 'Türkiye',
            city: 'İstanbul',
            shortSummary: shortSummary,
            photoUrls: const <String>[
              'https://example.invalid/bebek-1.jpg',
            ],
          ),
        );

        final longDescPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-long-desc',
            name: 'Şirince Seyir Tepesi',
            countryCode: 'TR',
            countryName: 'Türkiye',
            city: 'İzmir',
            shortSummary: longSummary,
            photoUrls: const <String>[
              'https://example.invalid/sirince-1.jpg',
            ],
          ),
        );

        final anotherLongDescPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'compact-long-desc-2',
            name: 'Alaçatı Yel Değirmenleri',
            countryCode: 'TR',
            countryName: 'Türkiye',
            city: 'İzmir',
            shortSummary: longSummary,
            photoUrls: const <String>[
              'https://example.invalid/alacati-1.jpg',
            ],
          ),
        );

        // 1. Kısa açıklama: tamamı görünür, "Devamını Oku" veya chevron çıkmaz
        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: shortDescPlace,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(shortSummary), findsOneWidget);
        expect(find.text('Devamını Oku'), findsNothing);
        expect(find.text('Daha Az Göster'), findsNothing);
        expect(tester.takeException(), isNull);

        // 2. Uzun açıklama (375px dar ekran): başlangıçta kısaltılmış + "Devamını Oku" + aşağı chevron
        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: longDescPlace,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(longSummary), findsNothing);
        expect(find.text('Devamını Oku'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is PhosphorIcon &&
                w.icon == PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // 3. "Devamını Oku" dokunulunca AnimatedSize ile tam metin + "Daha Az Göster" + yukarı chevron görünür
        await tester.tap(find.text('Devamını Oku'));
        await tester.pumpAndSettle();

        expect(find.text(longSummary), findsOneWidget);
        expect(find.text('Devamını Oku'), findsNothing);
        expect(find.text('Daha Az Göster'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is PhosphorIcon &&
                w.icon == PhosphorIcons.caretUp(PhosphorIconsStyle.bold),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // 4. "Daha Az Göster" dokunulunca tekrar kapanır
        await tester.tap(find.text('Daha Az Göster'));
        await tester.pumpAndSettle();

        expect(find.text(longSummary), findsNothing);
        expect(find.text('Devamını Oku'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 5. Açık durumdayken farklı bir mekana geçilince _isDescriptionExpanded sıfırlanır
        await tester.tap(find.text('Devamını Oku'));
        await tester.pumpAndSettle();
        expect(find.text(longSummary), findsOneWidget);

        await tester.pumpWidget(
          wrapCard(
            width: 375,
            child: PlaceDiscoveryCompactCard(
              place: anotherLongDescPlace,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alaçatı Yel Değirmenleri'), findsOneWidget);
        expect(find.text(longSummary), findsNothing);
        expect(find.text('Devamını Oku'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Eski PlaceDiscoveryCard bagimsiz olarak hatasiz render edilmeye devam eder',
      (WidgetTester tester) async {
        final legacyPlace = PlaceDiscoveryItem.fromJson(
          _buildPlaceJson(
            id: 'legacy-place-1',
            name: 'Galata Kulesi',
            city: 'İstanbul',
            photoUrls: const <String>[
              'https://example.invalid/galata-1.jpg',
              'https://example.invalid/galata-2.jpg',
            ],
            relatedRouteIds: const <String>['r-1'],
          ),
        );

        await tester.pumpWidget(
          wrapCard(
            width: 390,
            child: PlaceDiscoveryCard(
              place: legacyPlace,
              savedLists: const <UserFavoritePlaceList>[],
              addedUserRoutes: const <UserEditableRouteOption>[],
              relatedRoutes: const <PublishedRouteFeedItem>[],
              similarPlaces: const <PlaceDiscoveryItem>[],
              showDistanceBadge: false,
              onTapFlagButton: () {},
              onTapAddToRouteButton: () {},
              onTapRelatedRoutesButton: () {},
              onTapDetailButton: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlaceDiscoveryCard), findsOneWidget);
        expect(find.text('Galata Kulesi'), findsOneWidget);
        expect(find.text('1 Rotada Geçiyor'), findsOneWidget);
        expect(find.text('Detay / Katkı'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
