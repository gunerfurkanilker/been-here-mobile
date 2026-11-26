import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/features/home/view_models/home_feed_view_model.dart';
import 'package:been_here_mobile/ui/features/home/views/route_detail_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PublishedRouteFeedItem _buildTestRoute({required int stopCount}) {
  final allStops = const <RouteStopDetailItem>[
    RouteStopDetailItem(
      id: 'stop-1',
      orderIndex: 0,
      dayNumber: 1,
      placeName: 'Birinci Durak',
      city: 'Fethiye',
      uiCategory: 'DESTINATION',
      verificationType: 'GEO_VERIFIED',
      rating: 5,
      comment: 'İlk durak notu.',
      vibes: ['Manzara'],
      warnings: [],
      photoUrls: [],
    ),
    RouteStopDetailItem(
      id: 'stop-2',
      orderIndex: 1,
      dayNumber: 2,
      placeName: 'İkinci Durak',
      city: 'Köyceğiz',
      uiCategory: 'FOOD',
      verificationType: 'GEO_VERIFIED',
      rating: 5,
      comment: 'İkinci durak notu.',
      vibes: ['Doğa'],
      warnings: [],
      photoUrls: [],
    ),
    RouteStopDetailItem(
      id: 'stop-3',
      orderIndex: 2,
      dayNumber: 3,
      placeName: 'Üçüncü Durak',
      city: 'Marmaris',
      uiCategory: 'DESTINATION',
      verificationType: 'PHOTO_VERIFIED',
      rating: 5,
      comment: 'Üçüncü durak notu.',
      vibes: ['Koy'],
      warnings: [],
      photoUrls: [],
    ),
  ];

  return PublishedRouteFeedItem(
    id: 'test-route-slider',
    title: 'Test Slider Rotası',
    description: 'Durak slider precision test rotası.',
    authorUsername: 'test_gezgin',
    authorDisplayName: 'Test Gezgin',
    authorRankLabel: 'Master of Routes',
    continent: ContinentFilter.europe,
    countryCodes: const ['TR'],
    countryNames: const ['Türkiye'],
    cities: const ['Muğla'],
    featuredMediaUrls: const [],
    previewPlaceNames: const ['Birinci Durak', 'İkinci Durak', 'Üçüncü Durak'],
    dateRangeText: '14–18 Temmuz 2026',
    adultsCount: 2,
    childrenCount: 0,
    durationDays: 3,
    estimatedBudgetUsd: 500,
    estimatedBudgetLocal: 17000,
    localCurrencySymbol: '₺',
    budgetBreakdown: const {'Konaklama': 300, 'Yeme-İçme': 200},
    forkCount: 12,
    isBoosted: false,
    isQaEnabled: true,
    stops: allStops.take(stopCount).toList(),
    stays: const [
      RouteStayDetailItem(
        stayTypeLabel: 'Butik Otel',
        regionOrHotelName: 'Selimiye',
        nightsCount: 2,
      ),
    ],
    questions: const [],
  );
}

void main() {
  setUp(() {
    BeenHereThemeController.instance.setDark();
  });

  group('RouteDetailScreen durak slider regresyon testleri', () {
    testWidgets(
      '468.0 viewport genişliğinde precisionErrorTolerance hatası olmadan açılır ve 1/3 -> 2/3 kaydırılır',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(468.0, 900.0);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final vm = HomeFeedViewModel();
        final route = _buildTestRoute(stopCount: 3);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: RouteDetailScreen(
              route: route,
              viewModel: vm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('1 / 3 Durak'), findsOneWidget);

        // Durak slider'ına doğru aşağı kaydır
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final stopsPageView = find.byType(PageView).last;
        expect(stopsPageView, findsOneWidget);
        expect(
          tester.widget<PageView>(stopsPageView).controller?.viewportFraction,
          0.86,
        );

        // Touch ile 2. durağa kaydır
        await tester.fling(stopsPageView, const Offset(-320, 0), 800);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('2 / 3 Durak'), findsOneWidget);
        expect(find.text('📍 İkinci Durak'), findsOneWidget);

        // Masaüstü / Web için fare sürüklemesiyle 3. durağa kaydır
        final center = tester.getCenter(stopsPageView);
        final mouseGesture = await tester.startGesture(
          center,
          kind: PointerDeviceKind.mouse,
        );
        await mouseGesture.moveBy(const Offset(-350, 0));
        await mouseGesture.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('3 / 3 Durak'), findsOneWidget);
        expect(find.text('📍 Üçüncü Durak'), findsOneWidget);
      },
    );

    testWidgets(
      '500.0 viewport genişliğinde (PageView genişliği 468.0, itemExtent 402.48) hatasız çalışır',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(500.0, 900.0);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final vm = HomeFeedViewModel();
        final route = _buildTestRoute(stopCount: 3);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: RouteDetailScreen(
              route: route,
              viewModel: vm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('1 / 3 Durak'), findsOneWidget);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();

        final stopsPageView = find.byType(PageView).last;
        expect(tester.getSize(stopsPageView).width, 468.0);

        await tester.fling(stopsPageView, const Offset(-320, 0), 800);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('2 / 3 Durak'), findsOneWidget);
      },
    );

    testWidgets(
      'Tek duraklı rotada viewportFraction 1.0 ile taşma olmadan açılır',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(468.0, 900.0);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final vm = HomeFeedViewModel();
        final route = _buildTestRoute(stopCount: 1);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: RouteDetailScreen(
              route: route,
              viewModel: vm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('1 / 1 Durak'), findsOneWidget);

        final stopsPageView = find.byType(PageView).last;
        final pageViewWidget = tester.widget<PageView>(stopsPageView);
        expect(pageViewWidget.controller?.viewportFraction, 1.0);
      },
    );
  });
}
