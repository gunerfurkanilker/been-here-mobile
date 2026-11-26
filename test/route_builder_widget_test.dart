import 'dart:convert';
import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:been_here_mobile/data/services/been_here_api_client.dart';
import 'package:been_here_mobile/data/services/geography_api_service.dart';
import 'package:been_here_mobile/data/stores/geography_store.dart';
import 'package:been_here_mobile/domain/models/geography_models.dart';
import 'package:been_here_mobile/domain/models/route_feed_models.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/widgets/been_here_search_panel.dart';
import 'package:been_here_mobile/ui/core/widgets/geography_tree_filter_bar.dart';
import 'package:been_here_mobile/ui/features/route_builder/view_models/route_builder_view_model.dart';
import 'package:been_here_mobile/ui/features/route_builder/views/route_builder_screen.dart';

void main() {
  testWidgets(
    'RouteBuilderScreen: Stepper, sade search bar, bayrak bölmeli ülke kartı ve şehir slider akışı testi',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Üst Stepper kompakt ikonlardan oluşur ve Tooltip mesajlarına sahiptir
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      expect(find.byTooltip('Seçili Tarih'), findsOneWidget);
      expect(find.byTooltip('Seçili Bütçe'), findsOneWidget);
      expect(find.byTooltip('Seçili Ziyaretçi'), findsOneWidget);

      // 2. Stepper'ın hemen altında ortak GeographyTreeFilterBar arama çubuğu: "Ülke veya şehir ismi ile ara..."
      expect(find.byType(GeographyTreeFilterBar), findsOneWidget);
      expect(find.text('Ülke veya şehir ismi ile ara...'), findsOneWidget);

      // 3. Ülke Kartı Sol Bayrak Bölmesi (Flag Strip): 90° Sola Döndürülmüş Dikey Bayrak (Ülke kodu kaldırıldı)
      expect(find.text('🇪🇸'), findsWidgets);
      expect(find.text('ES'), findsNothing);
      expect(find.text('🇹🇷'), findsWidgets);
      expect(find.text('TR'), findsNothing);
      expect(find.byType(RotatedBox), findsWidgets);

      // 4. Doğrudan listelenen Ülkeler ve Şehirler
      expect(find.text('İspanya'), findsOneWidget);
      expect(find.text('Sevilla'), findsOneWidget);
      expect(find.text('Cadiz'), findsOneWidget);
      expect(find.text('Madrid'), findsOneWidget);

      // 5. Ortak arama çubuğu -> BeenHereSearchPanel üzerinden filtreleme testi: "İzmir" seçelim
      await tester.tap(
        find.byKey(const ValueKey<String>('route_builder_search_bar_tap')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BeenHereSearchPanel), findsOneWidget);

      final panelTextField = find.byType(TextField);
      expect(panelTextField, findsOneWidget);
      await tester.enterText(panelTextField, 'İzmir');
      await tester.pump();
      expect(find.text('İzmir ile arama yap'), findsOneWidget);

      // Şehir önerisini seçip "Arama (1)" ile dönelim
      await tester.tap(find.text('İzmir').last);
      await tester.pump();
      await tester.tap(find.text('Arama (1)'));
      await tester.pumpAndSettle();

      // İspanya ve Sevilla elenmeli, Türkiye ve İzmir görünmeli (hem hapta hem kartta)
      expect(find.text('İspanya'), findsNothing);
      expect(find.text('Sevilla'), findsNothing);
      expect(find.text('Türkiye'), findsOneWidget);
      expect(find.text('İzmir'), findsNWidgets(2));

      // "Tümünü Temizle" ile filtre hapı temizlensin
      await tester.tap(find.text('Tümünü Temizle'));
      await tester.pumpAndSettle();
      expect(find.text('İspanya'), findsOneWidget);
      expect(find.text('Sevilla'), findsOneWidget);

      // 6. Şehir seçimi testi: "Sevilla" kartına tıkla
      await tester.tap(find.text('Sevilla'));
      await tester.pumpAndSettle();

      // Sevilla seçilince bağlı olduğu ülke (ES) otomatik seçilmiş olur
      expect(viewModel.selectedCityKeys.contains('ES:Sevilla'), isTrue);
      expect(viewModel.isCountrySelected('ES'), isTrue);
      // Kullanıcı talebi: Ülke kartında ülke isminin altına seçilen şehir gelir
      expect(find.text('Sevilla'), findsNWidgets(2)); // Biri şehir kartı, diğeri İspanya altındaki alt başlık
      expect(find.text('1 Ülke, 1 Şehir Seçildi'), findsOneWidget);

      // İkinci şehir: "Cadiz" kartına da tıkla -> İspanya altında "Sevilla, Cadiz" yazmalı
      await tester.tap(find.text('Cadiz'));
      await tester.pumpAndSettle();
      expect(find.text('Sevilla, Cadiz'), findsOneWidget);
      expect(find.text('1 Ülke, 2 Şehir Seçildi'), findsOneWidget);

      // 7. Ülke Banner kartına tıkla -> Toggle davranışı ile İspanya ve alt şehirleri temizlenir
      await tester.tap(find.text('İspanya'));
      await tester.pumpAndSettle();

      expect(viewModel.isCountrySelected('ES'), isFalse);
      expect(viewModel.selectedCityKeys.contains('ES:Sevilla'), isFalse);
      expect(viewModel.selectedCityKeys.contains('ES:Cadiz'), isFalse);
      expect(find.text('Sevilla, Cadiz'), findsNothing);
      expect(find.text('0 Ülke, 0 Şehir Seçildi'), findsOneWidget);

      // 8. Tekrar Ülke Banner kartına tıkla -> İspanya yeniden seçilir (şehirler boş)
      await tester.tap(find.text('İspanya'));
      await tester.pumpAndSettle();

      expect(viewModel.isCountrySelected('ES'), isTrue);
      expect(find.text('Sevilla, Cadiz'), findsNothing);
      expect(find.text('İspanya Seçili'), findsNothing);

      // 9. Şehir slider boyutu doğrulaması: yükseklik 172.0 px (156 + 16 px no-clip nefes payı), genişlik 220.0 px
      final citiesRowFinder = find.byKey(const PageStorageKey<String>('cities-row-ES'));
      expect(citiesRowFinder, findsOneWidget);
      final citiesListView = tester.widget<ListView>(citiesRowFinder);
      expect(citiesListView.clipBehavior, Clip.none);

      final citiesRowSizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: citiesRowFinder,
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(citiesRowSizedBox.height, 172.0);

      // Sevilla kartının genişliği 220.0 px
      final sevillaText = find.text('Sevilla');
      final sevillaCardSizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: sevillaText,
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sevillaCardSizedBox.width, 220.0);
    },
  );

  testWidgets(
    'RouteBuilderScreen: Alt bar Seçimleri Temizle butonu akışı testi',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. "Temizle" butonu ve tooltip kontrolü
      final clearButtonFinder = find.byKey(
        const ValueKey<String>('wizard-clear-selections-button'),
      );
      expect(clearButtonFinder, findsOneWidget);
      expect(find.text('Temizle'), findsOneWidget);
      expect(find.byTooltip('Seçimleri Temizle'), findsOneWidget);

      // Başlangıçta seçim yok, buton inaktif
      expect(viewModel.hasAnyDestinationSelected, isFalse);
      expect(find.text('0 Ülke, 0 Şehir Seçildi'), findsOneWidget);

      // İnaktifken tıklama hiçbir şeyi değiştirmez
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();
      expect(viewModel.hasAnyDestinationSelected, isFalse);

      // 2. Birkaç şehir seçelim: "Sevilla" ve "Cadiz"
      await tester.tap(find.text('Sevilla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadiz'));
      await tester.pumpAndSettle();

      expect(viewModel.hasAnyDestinationSelected, isTrue);
      expect(viewModel.totalSelectedCountryCount, 1);
      expect(viewModel.totalSelectedCityCount, 2);
      expect(find.text('1 Ülke, 2 Şehir Seçildi'), findsOneWidget);

      // 3. "Temizle" butonuna tıkla
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Tüm seçimler tek seferde sıfırlanmalıdır
      expect(viewModel.hasAnyDestinationSelected, isFalse);
      expect(viewModel.selectedCountryCodes.isEmpty, isTrue);
      expect(viewModel.selectedCityKeys.isEmpty, isTrue);
      expect(find.text('0 Ülke, 0 Şehir Seçildi'), findsOneWidget);

      // 4. Doğrudan ViewModel clearAllDestinationSelections birim testi
      final espCountry = RouteBuilderViewModel.continentsCatalog.first
          .subRegions.first.countries.first;
      viewModel.toggleCountrySelection(espCountry);
      expect(viewModel.hasAnyDestinationSelected, isTrue);

      viewModel.clearAllDestinationSelections();
      expect(viewModel.hasAnyDestinationSelected, isFalse);
      expect(viewModel.selectedCountryCodes.isEmpty, isTrue);
      expect(viewModel.selectedCityKeys.isEmpty, isTrue);
    },
  );

  testWidgets(
    'RouteBuilderScreen: Dikey scroll aşağı yapıldığında üst ilerleme ağacı gizlenir, yukarı yapıldığında tekrar görünür',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Başlangıçta üst ilerleme ağacı görünürdür
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);

      final verticalListView = find.byType(ListView).first;

      // 2. Dikey olarak aşağı doğru scroll yap (parmak yukarı sürüklenir -> dy negatif)
      await tester.drag(verticalListView, const Offset(0, -260));
      await tester.pumpAndSettle();

      // Üst ilerleme ağacı gizlenmiştir
      expect(find.byTooltip('Seçili Konumlar'), findsNothing);

      // 3. Yukarı doğru scroll yap (parmak aşağı sürüklenir -> dy pozitif)
      await tester.drag(verticalListView, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Üst ilerleme ağacı yeniden görünür
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);

      // 4. Tekrar gizle ve adım değiştirildiğinde veya arama yapıldığında otomatik geri gelmesini test et
      await tester.drag(verticalListView, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsNothing);

      // Arama yapıldığında görünür olmalı
      viewModel.updateSearchFilterQuery('Madrid');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);

      // Arama temizlensin
      viewModel.clearSearchFilter();
      await tester.pumpAndSettle();

      // 5. Yatay şehir slider'ı kaydırıldığında üst ilerleme ağacı gizlenmemelidir (axis == Axis.horizontal)
      final horizontalCitiesRow = find.byKey(const PageStorageKey<String>('cities-row-ES'));
      await tester.drag(horizontalCitiesRow, const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);

      // 6. Dikey kaydırıp gizleyelim, ardından adım değiştirildiğinde (currentStep değiştiğinde) tekrar görünür olsun
      await tester.drag(verticalListView, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsNothing);

      // En az bir lokasyon seç ve bir sonraki adıma geç
      final firstCountry = RouteBuilderViewModel.continentsCatalog.first.subRegions.first.countries.first;
      viewModel.toggleCountrySelection(firstCountry);
      await tester.pumpAndSettle();
      viewModel.goToNextStep();
      await tester.pumpAndSettle();

      // Adım değiştiği için üst ilerleme ağacı tekrar görünür olmalıdır
      expect(find.byTooltip('Seçili Tarih'), findsOneWidget);
    },
  );

  testWidgets(
    'RouteBuilderScreen: Dikey scroll alanı ClipRect ve Clip.hardEdge ile kırpılır, üst ilerleme ağacı her zaman gövdenin üstünde kalır',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final progressTreeSectionFinder = find.byKey(
        const ValueKey<String>('wizard-top-progress-tree-section'),
      );
      final bodyClipFinder = find.byKey(
        const ValueKey<String>('wizard-step-body-clip'),
      );
      expect(progressTreeSectionFinder, findsOneWidget);
      expect(bodyClipFinder, findsOneWidget);

      // Üst ilerleme ağacı bölümü opak arka planla kaplıdır
      final progressColoredBox = tester.widget<ColoredBox>(
        progressTreeSectionFinder,
      );
      expect(progressColoredBox.color, BeenHereColors.background);

      // Expanded gövde ClipRect ile sarılıdır ve kırpma aktiftir
      final bodyClipRectWidget = tester.widget<ClipRect>(bodyClipFinder);
      expect(bodyClipRectWidget.clipBehavior, isNot(Clip.none));
      final bodyRenderClipRect = tester.renderObject<RenderClipRect>(
        bodyClipFinder,
      );
      expect(bodyRenderClipRect.clipBehavior, isNot(Clip.none));

      // 1. Adım dikey ListView Clip.hardEdge kullanmalıdır (Clip.none yasak)
      final stepOneFinder = find.byKey(
        const ValueKey<String>('wizard-step-locations'),
      );
      final verticalListViewFinder = find.descendant(
        of: stepOneFinder,
        matching: find.byType(ListView),
      ).first;
      final verticalListView = tester.widget<ListView>(verticalListViewFinder);
      expect(verticalListView.clipBehavior, Clip.hardEdge);
      expect(verticalListView.clipBehavior, isNot(Clip.none));

      // Başlangıç konumunda ilerleme ağacı gövdenin kesinlikle üstündedir
      Rect progressTreeRect = tester.getRect(progressTreeSectionFinder);
      Rect bodyRect = tester.getRect(bodyClipFinder);
      expect(progressTreeRect.bottom, lessThanOrEqualTo(bodyRect.top));

      // Aşağı scroll yap (kartlar yukarı kayar), ardından hafifçe yukarı çekerek
      // liste hala kaydırılmış durumdayken (pixels > 0) ilerleme ağacını geri getir
      await tester.drag(verticalListViewFinder, const Offset(0, -360));
      await tester.pumpAndSettle();
      await tester.drag(verticalListViewFinder, const Offset(0, 60));
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.descendant(
          of: verticalListViewFinder,
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(scrollableState.widget.axisDirection, AxisDirection.down);
      expect(scrollableState.position.pixels, greaterThan(0));
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);

      // Kaydırma sonrası da ilerleme ağacı gövdenin üstünde ve ayrı sınırlar içindedir
      progressTreeRect = tester.getRect(progressTreeSectionFinder);
      bodyRect = tester.getRect(bodyClipFinder);
      expect(progressTreeRect.bottom, lessThanOrEqualTo(bodyRect.top));

      // RenderViewport da Clip.hardEdge ile dikey taşmayı engeller
      final renderViewport = tester.renderObject<RenderViewport>(
        find.descendant(
          of: verticalListViewFinder,
          matching: find.byType(Viewport),
        ).first,
      );
      expect(renderViewport.axisDirection, AxisDirection.down);
      expect(renderViewport.clipBehavior, Clip.hardEdge);

      // 2, 3 ve 4. adımlardaki dikey ListView'ların da Clip.none kullanmadığını doğrula
      final firstCountry = RouteBuilderViewModel
          .continentsCatalog.first.subRegions.first.countries.first;
      viewModel.toggleCountrySelection(firstCountry);
      await tester.pumpAndSettle();

      for (final stepKeyName in [
        'wizard-step-dates',
        'wizard-step-budget',
        'wizard-step-travelers',
      ]) {
        viewModel.goToNextStep();
        await tester.pumpAndSettle();

        final stepBodyFinder = find.byKey(ValueKey<String>(stepKeyName));
        expect(stepBodyFinder, findsOneWidget);

        final stepListView = tester.widget<ListView>(
          find.descendant(
            of: stepBodyFinder,
            matching: find.byType(ListView),
          ).first,
        );
        expect(stepListView.clipBehavior, Clip.hardEdge);
        expect(stepListView.clipBehavior, isNot(Clip.none));

        progressTreeRect = tester.getRect(progressTreeSectionFinder);
        bodyRect = tester.getRect(bodyClipFinder);
        expect(progressTreeRect.bottom, lessThanOrEqualTo(bodyRect.top));
      }
    },
  );

  testWidgets(
    'RouteBuilderScreen: Şehir kartı üzerinden dikey sürükleme ve mouse wheel scroll üst ilerleme ağacını gizler/gösterir, alt bar sabit kalır',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNavLabel = find.text('0 Ülke, 0 Şehir Seçildi');
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      expect(bottomNavLabel, findsOneWidget);

      // 1. Doğrudan şehir kartı ("Sevilla") üzerinden aşağı doğru dikey sürükleme
      final sevillaCard = find.text('Sevilla');
      expect(sevillaCard, findsOneWidget);
      await tester.drag(sevillaCard, const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Seçili Konumlar'), findsNothing);
      expect(bottomNavLabel, findsOneWidget);

      // 2. Doğrudan şehir kartı ("Cadiz") üzerinden yukarı doğru dikey sürükleme
      final cadizCard = find.text('Cadiz');
      expect(cadizCard, findsOneWidget);
      await tester.drag(cadizCard, const Offset(0, 140));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      expect(bottomNavLabel, findsOneWidget);

      // 3. Şehir kartı ("Sevilla") üzerinde mouse wheel (PointerScrollEvent) ile aşağı scroll
      expect(sevillaCard, findsOneWidget);
      final cityCenter = tester.getCenter(sevillaCard);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(cityCenter));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 140)));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Seçili Konumlar'), findsNothing);
      expect(bottomNavLabel, findsOneWidget);

      // 4. Mouse wheel (PointerScrollEvent) ile yukarı scroll -> üst bar geri gelir (liste hala pixels > 0 iken)
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -80)));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      expect(bottomNavLabel, findsOneWidget);
    },
  );

  testWidgets(
    'RouteBuilderScreen: Üst ilerleme ağacı gizlenme/açılma geçişi ara karelerde yumuşak yükseklik ve opaklık değerleriyle animasyon yapar',
    (WidgetTester tester) async {
      final viewModel = RouteBuilderViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteBuilderScreen(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final progressTreeSectionFinder = find.byKey(
        const ValueKey<String>('wizard-top-progress-tree-section'),
      );
      final bodyClipFinder = find.byKey(
        const ValueKey<String>('wizard-step-body-clip'),
      );
      final alignFinder = find
          .descendant(
            of: progressTreeSectionFinder,
            matching: find.byType(Align),
          )
          .first;
      final opacityFinder = find
          .descendant(
            of: progressTreeSectionFinder,
            matching: find.byType(Opacity),
          )
          .first;

      final sevillaCard = find.text('Sevilla');
      final cityCenter = tester.getCenter(sevillaCard);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(cityCenter));

      // 1. Aşağı scroll -> 320ms gizlenme animasyonunun ortasında (160ms) ara değerleri doğrula
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 140)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      final hideAlign = tester.widget<Align>(alignFinder);
      final hideOpacity = tester.widget<Opacity>(opacityFinder);
      expect(hideAlign.heightFactor, greaterThan(0.0));
      expect(hideAlign.heightFactor, lessThan(1.0));
      expect(hideOpacity.opacity, greaterThan(0.0));
      expect(hideOpacity.opacity, lessThan(1.0));

      expect(
        tester.getRect(progressTreeSectionFinder).bottom,
        lessThanOrEqualTo(tester.getRect(bodyClipFinder).top),
      );

      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsNothing);
      expect(
        tester.getRect(progressTreeSectionFinder).bottom,
        lessThanOrEqualTo(tester.getRect(bodyClipFinder).top),
      );

      // 2. Yukarı scroll -> 380ms açılma animasyonunun ortasında (190ms) ara değerleri doğrula
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -80)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 190));

      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      final showAlign = tester.widget<Align>(alignFinder);
      final showOpacity = tester.widget<Opacity>(opacityFinder);
      expect(showAlign.heightFactor, greaterThan(0.0));
      expect(showAlign.heightFactor, lessThan(1.0));
      expect(showOpacity.opacity, greaterThan(0.0));
      expect(showOpacity.opacity, lessThan(1.0));

      expect(
        tester.getRect(progressTreeSectionFinder).bottom,
        lessThanOrEqualTo(tester.getRect(bodyClipFinder).top),
      );

      await tester.pumpAndSettle();
      expect(find.byTooltip('Seçili Konumlar'), findsOneWidget);
      expect(tester.widget<Align>(alignFinder).heightFactor, 1.0);
      expect(tester.widget<Opacity>(opacityFinder).opacity, 1.0);
    },
  );

  group('RouteBuilder - Ortak GeographyTreeFilterBar & BeenHereSearchPanel Testleri', () {
    test(
      'RouteBuilderViewModel: BeenHereSearchFilterController, OR/AND pill filtreleme ve clearAllFilterPills seçimleri korur',
      () {
        final vm = RouteBuilderViewModel();
        final totalCountries = vm.displayedCountries.length;
        expect(totalCountries, 21);
        expect(vm.itemCountUnitLabel, 'Ülke');
        expect(vm.searchContinentsCatalog.length, 5);
        expect(vm.countItemsForContinent(ContinentFilter.europe), 12);
        expect(vm.countItemsForContinent(ContinentFilter.africa), 2);
        expect(vm.countItemsForContinent(ContinentFilter.oceania), 2);

        // Kullanıcı rota için İspanya + Sevilla'yı seçsin
        final espCountry = vm.displayedCountries.firstWhere((c) => c.code == 'ES');
        vm.toggleCitySelection(espCountry.cities.first); // Sevilla
        expect(vm.selectedCountryCodes, {'ES'});
        expect(vm.selectedCityKeys, {'ES:Sevilla'});

        // 1. Kıta/Bölge filtre hapı uygula (Afrika -> MA, ZA)
        vm.applyFilterPills([
          const RouteFeedFilterPill(
            id: 'continent:AFRICA',
            type: RouteFilterPillType.continent,
            label: 'Afrika',
            continent: ContinentFilter.africa,
          ),
        ]);
        expect(vm.displayedCountries.map((c) => c.code).toList(), ['MA', 'ZA']);

        // 2. İkinci konum hapı ekle (Şehir: İzmir -> OR birleşimi ile MA, ZA, TR)
        vm.applyFilterPills([
          ...vm.filterPills,
          const RouteFeedFilterPill(
            id: 'city:izmir',
            type: RouteFilterPillType.city,
            label: 'İzmir',
            cityName: 'İzmir',
            countryCode: 'TR',
          ),
        ]);
        expect(
          vm.displayedCountries.map((c) => c.code).toList(),
          ['TR', 'MA', 'ZA'],
        );
        // Türkiye için yalnızca İzmir şehri gösterilmeli
        final trCountry = vm.displayedCountries.firstWhere((c) => c.code == 'TR');
        expect(
          vm.getDisplayedCitiesForCountry(trCountry).map((c) => c.name).toList(),
          ['İzmir'],
        );

        // 3. Kelime hapı ekle ("Marakeş" -> AND kesişimi ile sadece MA kalır)
        vm.applyFilterPills([
          ...vm.filterPills,
          const RouteFeedFilterPill(
            id: 'keyword:marakeş',
            type: RouteFilterPillType.keyword,
            label: '"Marakeş"',
            keyword: 'Marakeş',
          ),
        ]);
        expect(vm.displayedCountries.map((c) => c.code).toList(), ['MA']);

        // 4. clearAllFilterPills çağrıldığında filtre hapları temizlenir ama rota seçimleri KORUNUR!
        vm.clearAllFilterPills();
        expect(vm.filterPills, isEmpty);
        expect(vm.displayedCountries.length, totalCountries);
        expect(vm.selectedCountryCodes, {'ES'});
        expect(vm.selectedCityKeys, {'ES:Sevilla'});
      },
    );

    testWidgets(
      'Arama çubuğu BeenHereSearchPanel açar, hapları uygular, toggle/kaldırır ve Tümünü Temizle seçilen rota konumlarını korur',
      (WidgetTester tester) async {
        final vm = RouteBuilderViewModel();

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        // Önce kullanıcı rota için "Sevilla" ve "Cadiz" şehirlerini seçsin
        await tester.tap(find.text('Sevilla'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cadiz'));
        await tester.pumpAndSettle();
        expect(find.text('1 Ülke, 2 Şehir Seçildi'), findsOneWidget);

        // 1. Arama çubuğuna tıkla -> BeenHereSearchPanel açılmalı
        await tester.tap(
          find.byKey(const ValueKey<String>('route_builder_search_bar_tap')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BeenHereSearchPanel), findsOneWidget);
        expect(find.text('Arama Sonuçları'), findsOneWidget);
        expect(find.text('Kıtalar'), findsOneWidget);
        expect(find.text('12 Ülke'), findsOneWidget);

        // Önce arama kutusuna "izmir" yazıp şehir önerisini seçelim
        await tester.enterText(find.byType(TextField), 'izmir');
        await tester.pump();
        expect(find.text('izmir ile arama yap'), findsOneWidget);
        await tester.tap(find.text('İzmir'));
        await tester.pump();
        expect(find.text('Arama (1)'), findsOneWidget);

        // Panel içinde Asya kıta kartını görünür alana kaydırıp seçelim
        final verticalScrollable = find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('been_here_search_panel_scroll'),
              ),
              matching: find.byType(Scrollable),
            )
            .first;

        await tester.scrollUntilVisible(
          find.text('Asya'),
          250,
          scrollable: verticalScrollable,
        );
        await tester.tap(find.text('Asya'));
        await tester.pump();
        expect(find.text('Arama (2)'), findsOneWidget);

        // "Arama (2)" ile RouteBuilderScreen'e dön
        await tester.tap(find.text('Arama (2)'));
        await tester.pumpAndSettle();

        expect(find.byType(BeenHereSearchPanel), findsNothing);
        // Haplar görünmeli ve liste filtrelenmiş olmalı (Türkiye + Asya ülkeleri)
        expect(find.text('Asya'), findsOneWidget);
        expect(find.text('İzmir'), findsWidgets);
        expect(find.text('İspanya'), findsNothing);
        expect(vm.displayedCountries.map((c) => c.code).toList(), [
          'TR',
          'JP',
          'RU',
          'TH',
        ]);

        // Seçilen rota konumları halen korunuyor olmalı!
        expect(vm.selectedCountryCodes, {'ES'});
        expect(vm.selectedCityKeys, {'ES:Sevilla', 'ES:Cadiz'});
        expect(find.text('1 Ülke, 2 Şehir Seçildi'), findsOneWidget);

        // 2. "İzmir" hapının gövdesine dokun -> pasif (disabled) olmalı, sadece Asya kalmalı
        await tester.tap(find.text('İzmir').first);
        await tester.pumpAndSettle();
        expect(vm.filterPills.firstWhere((p) => p.id == 'city:izmir').isEnabled, isFalse);
        expect(vm.displayedCountries.map((c) => c.code).toList(), ['JP', 'RU', 'TH']);

        // Tekrar dokun -> aktifleşmeli
        await tester.tap(find.text('İzmir').first);
        await tester.pumpAndSettle();
        expect(vm.filterPills.firstWhere((p) => p.id == 'city:izmir').isEnabled, isTrue);
        expect(vm.displayedCountries.any((c) => c.code == 'TR'), isTrue);

        // 3. "Asya" hapının X ikonuyla sil -> yalnızca İzmir (TR) kalmalı
        await tester.tap(
          find.byKey(const ValueKey<String>('remove_pill_continent:ASIA')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Asya'), findsNothing);
        expect(vm.displayedCountries.map((c) => c.code).toList(), ['TR']);

        // 4. "Tümünü Temizle" butonuna bas -> tüm haplar temizlenir ama
        // kullanıcının seçtiği İspanya / Sevilla, Cadiz seçimleri ASLA silinmez!
        await tester.tap(find.text('Tümünü Temizle'));
        await tester.pumpAndSettle();

        expect(vm.filterPills, isEmpty);
        expect(find.text('Tümünü Temizle'), findsNothing);
        expect(find.text('İspanya'), findsOneWidget);
        expect(vm.selectedCountryCodes, {'ES'});
        expect(vm.selectedCityKeys, {'ES:Sevilla', 'ES:Cadiz'});
        expect(find.text('1 Ülke, 2 Şehir Seçildi'), findsOneWidget);
      },
    );
  });

  group('RouteBuilderViewModel - GeographyStore DB Entegrasyonu', () {
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
            'places_count': 10,
            'routes_count': 5,
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
                'country_codes': <String>['TR'],
                'country_names': <String>['Türkiye'],
                'places_count': 5,
                'routes_count': 3,
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
                    'image_url': 'https://cdn.beenhere.dev/geo/izmir.jpg',
                    'is_popular': true,
                    'places_count': 3,
                    'routes_count': 2,
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
                'places_count': 5,
                'routes_count': 2,
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
                    'places_count': 3,
                    'routes_count': 2,
                  },
                  <String, dynamic>{
                    'id': 'city-milano',
                    'slug': 'it:milano',
                    'country_code': 'IT',
                    'name': 'Milano',
                    'default_name': 'Milano',
                    'name_translations': <String, String>{
                      'tr': 'Milano',
                      'en': 'Milan',
                    },
                    'image_url': 'https://cdn.beenhere.dev/geo/milano.jpg',
                    'is_popular': false,
                    'places_count': 2,
                    'routes_count': 0,
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

    test('Yüklü GeographyStore ile Balkanlar ve çoklu dil ülke/şehir filtrelemesi çalışır', () async {
      final store = buildTestGeographyStore();
      final vm = RouteBuilderViewModel(geographyStore: store);

      var notifiedCount = 0;
      vm.addListener(() => notifiedCount++);

      // Store yüklenmeden önce statik katalog (21 ülke) kullanılır
      expect(vm.displayedCountries.length, 21);

      await store.ensureLoaded(lang: 'tr');
      expect(notifiedCount, greaterThan(0));

      // DB'den gelen 2 ülke (bölgeye atanmamış IT dahil) listelenmeli
      expect(vm.displayedCountries.map((c) => c.code).toList(), ['TR', 'IT']);
      expect(vm.countItemsForContinent(ContinentFilter.europe), 2);

      // searchContinentsCatalog içinde Balkanlar yer almalı
      final europe = vm.searchContinentsCatalog.firstWhere(
        (c) => c.continent == ContinentFilter.europe,
      );
      final balkans = europe.regions.firstWhere((r) => r.id == 'balkans');
      expect(balkans.name, 'Balkanlar');
      expect(vm.countItemsForRegion(balkans), 1);

      // Çoklu dil önerileri: "Balkans" -> "Balkanlar", "Rome" -> "Roma"
      expect(
        vm.buildSearchSuggestions('Balkans').any(
              (s) =>
                  s.type == RouteSearchSuggestionType.region &&
                  s.title == 'Balkanlar',
            ),
        isTrue,
      );
      expect(
        vm.buildSearchSuggestions('Rome').any(
              (s) =>
                  s.type == RouteSearchSuggestionType.city &&
                  s.title == 'Roma',
            ),
        isTrue,
      );

      // Çoklu dil arama metni: "Rome" yazılınca İtalya -> Roma görünmeli
      vm.updateSearchFilterQuery('Rome');
      expect(vm.displayedCountries.map((c) => c.code).toList(), ['IT']);
      expect(
        vm
            .getDisplayedCitiesForCountry(vm.displayedCountries.first)
            .map((c) => c.name)
            .toList(),
        ['Roma'],
      );

      // Çoklu dil arama metni: "Balkans" yazılınca Balkanlar ülkesi (TR) görünmeli
      vm.updateSearchFilterQuery('Balkans');
      expect(vm.displayedCountries.map((c) => c.code).toList(), ['TR']);
      vm.clearSearchFilter();

      // Kelime hapı ile çoklu dil eşleşmesi ("Italia")
      vm.applyFilterPills([
        const RouteFeedFilterPill(
          id: 'keyword:italia',
          type: RouteFilterPillType.keyword,
          label: '"Italia"',
          keyword: 'Italia',
        ),
      ]);
      expect(vm.displayedCountries.map((c) => c.code).toList(), ['IT']);
      expect(
        vm
            .getDisplayedCitiesForCountry(vm.displayedCountries.first)
            .map((c) => c.name)
            .toList(),
        ['Roma', 'Milano'],
      );

      vm.dispose();
      store.dispose();
    });
  });

  group('RouteBuilder - Adım 2: Tarih Aralığı Seçimi (4 Modlu Akış)', () {
    final fixedToday = DateTime(2026, 11, 17);

    GeographyStore buildHemisphereStore(List<Map<String, dynamic>> countries) {
      final payload = <String, dynamic>{
        'lang': 'tr',
        'continents': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'cont-sa',
            'code': 'SOUTH_AMERICA',
            'name': 'Güney Amerika',
            'default_name': 'Güney Amerika',
            'name_translations': <String, String>{'tr': 'Güney Amerika'},
            'image_url': '',
            'places_count': 10,
            'routes_count': 5,
            'regions': <Map<String, dynamic>>[],
            'countries': countries,
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

    tearDown(() {
      BeenHereThemeController.instance.setDark();
    });

    testWidgets(
      '2x2 Tarih Aralığı Seçimi ana ekranı ve modernize edilmiş Esnek Tarihler (hızlı dönem, mikro pill, temizleme) çalışır',
      (WidgetTester tester) async {
        final vm = RouteBuilderViewModel(clock: () => fixedToday);
        final spain = RouteBuilderViewModel
            .continentsCatalog.first.subRegions.first.countries.first;
        vm.toggleCountrySelection(spain);
        vm.goToStep(RouteWizardStep.dates);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ana Hub'da 4 kart görünür
        expect(find.text('Tarih Aralığı Seçimi'), findsOneWidget);
        expect(find.text('Esnek Tarihler'), findsOneWidget);
        expect(find.text('Anlık Gezi'), findsOneWidget);
        expect(find.text('Mevsimler'), findsOneWidget);
        expect(find.text('Belirli Tarihler'), findsOneWidget);

        // 2. Esnek Tarihler alt ekranına geç
        await tester.tap(
          find.byKey(const ValueKey<String>('date-mode-card-flexible')),
        );
        await tester.pumpAndSettle();

        // Hızlı dönem kısayolları ve 12 ay seçeneğinin ilk/sonraki ayları görünür
        expect(find.text('Tek Ay'), findsOneWidget);
        expect(find.text('2 Aylık Dönem'), findsOneWidget);
        expect(find.text('3 Aylık Dönem'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('flexible-month-2026-11')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('flexible-month-2027-1')),
          findsOneWidget,
        );

        // Hızlı kısayol: "2 Aylık Dönem" -> Kasım 2026 - Aralık 2026 + Başlangıç / Bitiş mikro pill'leri
        await tester.tap(
          find.byKey(const ValueKey<String>('flexible-shortcut-2-months')),
        );
        await tester.pumpAndSettle();
        expect(vm.formattedDateSummary, 'Kasım 2026 - Aralık 2026');
        expect(find.text('Başlangıç'), findsOneWidget);
        expect(find.text('Bitiş'), findsOneWidget);

        // Temizle butonu ile esnek seçim sıfırlanır
        await tester.tap(
          find.byKey(const ValueKey<String>('flexible-clear-button')),
        );
        await tester.pumpAndSettle();
        expect(vm.flexibleStartMonth, isNull);
        expect(vm.flexibleEndMonth, isNull);

        // Kasım 2026 seç -> tek ay özeti + "Başlangıç" mikro pill'i
        await tester.tap(
          find.byKey(const ValueKey<String>('flexible-month-2026-11')),
        );
        await tester.pumpAndSettle();
        expect(vm.formattedDateSummary, 'Kasım 2026');
        expect(find.text('Kasım 2026'), findsOneWidget);
        expect(find.text('Başlangıç'), findsOneWidget);
        expect(find.text('Bütçe Seçimi (Kasım 2026)'), findsOneWidget);

        // Ocak 2027 seç -> aralık oluşur, başlık ve alt bar güncellenir
        await tester.tap(
          find.byKey(const ValueKey<String>('flexible-month-2027-1')),
        );
        await tester.pumpAndSettle();
        expect(vm.formattedDateSummary, 'Kasım 2026 - Ocak 2027');
        expect(find.text('Kasım 2026 - Ocak 2027'), findsOneWidget);
        expect(find.text('Başlangıç'), findsOneWidget);
        expect(find.text('Bitiş'), findsOneWidget);
        expect(
          find.text('Bütçe Seçimi (Kasım 2026 - Ocak 2027)'),
          findsOneWidget,
        );

        // Backend payload doğrulaması
        final payload = vm.datePayload;
        expect(payload.dateMode, 'FLEXIBLE');
        expect(payload.flexiblePeriod, 'Kasım 2026 - Ocak 2027');
        expect(payload.startDate, isNull);
        expect(payload.endDate, isNull);

        // Geri ok ile ana 2x2 hub'a dönülür ve özet pill'i görünür
        await tester.tap(
          find.byKey(const ValueKey<String>('date-subview-back-button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tarih Aralığı Seçimi'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('date-hub-active-summary')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Anlık Gezi (CalendarDatePicker2): bugünü içermeyen aralıkta hata verir, bugünü kapsayan aralığı ve hızlı kısayolları kabul eder',
      (WidgetTester tester) async {
        final vm = RouteBuilderViewModel(clock: () => fixedToday);
        final spain = RouteBuilderViewModel
            .continentsCatalog.first.subRegions.first.countries.first;
        vm.toggleCountrySelection(spain);
        vm.goToStep(RouteWizardStep.dates);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('date-mode-card-instant')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Seçilen Tarih Aralığı'), findsOneWidget);
        expect(find.byType(CalendarDatePicker2), findsOneWidget);
        // Türkçe ay/yıl başlığı ve Pazartesi başlangıçlı Türkçe gün etiketleri
        expect(find.text('Kasım'), findsOneWidget);
        expect(find.text('2026'), findsOneWidget);
        expect(find.text('Pzt'), findsOneWidget);
        expect(find.text('Paz'), findsOneWidget);
        expect(find.text('November'), findsNothing);

        // 1. Bugünü (2026-11-17) kapsamayan tamamen gelecek aralık: 20 - 25 Kasım
        final day20 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-20'),
        );
        final day25 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-25'),
        );
        await tester.ensureVisible(day20);
        await tester.pumpAndSettle();
        await tester.tap(day20);
        await tester.pumpAndSettle();

        await tester.ensureVisible(day25);
        await tester.pumpAndSettle();
        await tester.tap(day25);
        await tester.pumpAndSettle();

        expect(
          vm.instantTripValidationError,
          'Anlık gezi için seçilen tarih aralığı bugünü kapsamalıdır.',
        );
        expect(
          find.byKey(const ValueKey<String>('instant-trip-validation-error')),
          findsOneWidget,
        );
        expect(vm.instantTripRange, isNull);

        // 2. Bugünü kapsayan aralık: 15 Kasım - 20 Kasım (15 <= 17 <= 20)
        final day15 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-15'),
        );
        await tester.ensureVisible(day15);
        await tester.pumpAndSettle();
        await tester.tap(day15);
        await tester.pumpAndSettle();

        await tester.ensureVisible(day20);
        await tester.pumpAndSettle();
        await tester.tap(day20);
        await tester.pumpAndSettle();

        expect(vm.instantTripValidationError, isNull);
        expect(
          find.byKey(const ValueKey<String>('instant-trip-validation-error')),
          findsNothing,
        );
        expect(vm.instantTripRange, isNotNull);
        expect(vm.instantTripRange!.start, DateTime(2026, 11, 15));
        expect(vm.instantTripRange!.end, DateTime(2026, 11, 20));
        expect(find.text('15 Kas 2026'), findsOneWidget);
        expect(find.text('20 Kas 2026'), findsOneWidget);
        expect(find.text('6 Gün'), findsOneWidget);
        expect(vm.datePayload.dateMode, 'CURRENT_OR_PAST_TRIP');
        expect(vm.datePayload.startDate, '2026-11-15');
        expect(vm.datePayload.endDate, '2026-11-20');

        // 3. Hızlı kısayollar: "Bugün" ve "Son 3 Gün"
        final todayShortcut = find.byKey(
          const ValueKey<String>('instant-shortcut-today'),
        );
        await tester.ensureVisible(todayShortcut);
        await tester.pumpAndSettle();
        await tester.tap(todayShortcut);
        await tester.pumpAndSettle();
        expect(vm.instantTripRange!.start, DateTime(2026, 11, 17));
        expect(vm.instantTripRange!.end, DateTime(2026, 11, 17));
        expect(find.text('1 Gün'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('instant-shortcut-last-3-days')),
        );
        await tester.pumpAndSettle();
        expect(vm.instantTripRange!.start, DateTime(2026, 11, 15));
        expect(vm.instantTripRange!.end, DateTime(2026, 11, 17));
        expect(find.text('3 Gün'), findsOneWidget);
      },
    );

    testWidgets(
      'Mevsimler: ülkelere göre yarım küre otomatik algılanır, çoklu mevsim ve yıl geçişli aralıklar hesaplanır',
      (WidgetTester tester) async {
        // 1. Brezilya + Arjantin (GeographyStore üzerinden) -> Güney Yarım Küre
        final southStore = buildHemisphereStore(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'br',
            'code': 'BR',
            'continent_code': 'SOUTH_AMERICA',
            'hemisphere': 'SOUTHERN',
            'name': 'Brezilya',
            'default_name': 'Brezilya',
            'name_translations': <String, String>{'tr': 'Brezilya'},
            'flag_emoji': '🇧🇷',
            'image_url': '',
            'places_count': 1,
            'routes_count': 1,
            'cities': <Map<String, dynamic>>[],
          },
          <String, dynamic>{
            'id': 'ar',
            'code': 'AR',
            'continent_code': 'SOUTH_AMERICA',
            'hemisphere': 'SOUTHERN',
            'name': 'Arjantin',
            'default_name': 'Arjantin',
            'name_translations': <String, String>{'tr': 'Arjantin'},
            'flag_emoji': '🇦🇷',
            'image_url': '',
            'places_count': 1,
            'routes_count': 1,
            'cities': <Map<String, dynamic>>[],
          },
        ]);
        await southStore.ensureLoaded(lang: 'tr');

        final southVm = RouteBuilderViewModel(
          geographyStore: southStore,
          clock: () => fixedToday,
        );
        for (final country in southVm.displayedCountries) {
          southVm.toggleCountrySelection(country);
        }
        expect(southVm.recommendedHemisphere, GeographyHemisphere.southern);
        expect(southVm.selectedHemisphere, GeographyHemisphere.southern);
        southVm.dispose();
        southStore.dispose();

        // 2. Türkiye + İtalya -> Kuzey Yarım Küre + UI widget akışı
        final vm = RouteBuilderViewModel(clock: () => fixedToday);
        final allCountries = RouteBuilderViewModel.continentsCatalog
            .expand((c) => c.allCountries)
            .toList(growable: false);
        final turkey = allCountries.firstWhere((c) => c.code == 'TR');
        final italy = allCountries.firstWhere((c) => c.code == 'IT');
        vm.toggleCountrySelection(turkey);
        vm.toggleCitySelection(italy.cities.first);
        expect(vm.selectedHemisphere, GeographyHemisphere.northern);

        vm.goToStep(RouteWizardStep.dates);
        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('date-mode-card-seasons')),
        );
        await tester.pumpAndSettle();

        // Kış kartı Kasım 2026 itibarıyla Aralık 2026 - Şubat 2027 göstermeli
        expect(find.text('Aralık 2026 - Şubat 2027'), findsOneWidget);

        // Yaz ve İlkbahar çoklu seçimi
        await tester.tap(
          find.byKey(const ValueKey<String>('season-card-summer')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('season-card-spring')),
        );
        await tester.pumpAndSettle();

        expect(vm.formattedSelectedSeasonsTitle, 'Yaz ve İlkbahar');
        expect(
          vm.formattedSelectedSeasonRanges,
          'Mart - Mayıs 2027 / Haziran - Ağustos 2027',
        );
        expect(find.text('Yaz ve İlkbahar'), findsOneWidget);
        expect(
          find.text('Mart - Mayıs 2027 / Haziran - Ağustos 2027'),
          findsOneWidget,
        );
        expect(vm.datePayload.dateMode, 'SEASONS');
        expect(vm.datePayload.flexiblePeriod!.length, lessThanOrEqualTo(120));
        expect(vm.datePayload.dateRangeLabel.length, lessThanOrEqualTo(140));

        // Güney Yarım Küre toggle'ına basınca aralıklar güncellenmeli
        await tester.tap(
          find.byKey(const ValueKey<String>('hemisphere-toggle-southern')),
        );
        await tester.pumpAndSettle();
        expect(vm.selectedHemisphere, GeographyHemisphere.southern);
        expect(
          vm.formattedSelectedSeasonRanges,
          'Eylül - Kasım 2026 / Aralık 2026 - Şubat 2027',
        );
      },
    );

    testWidgets(
      'Belirli Tarihler (CalendarDatePicker2): geçmiş günler devre dışı, kısayollar ve gün seçimi özet kartları günceller',
      (WidgetTester tester) async {
        final vm = RouteBuilderViewModel(clock: () => fixedToday);
        final spain = RouteBuilderViewModel
            .continentsCatalog.first.subRegions.first.countries.first;
        vm.toggleCountrySelection(spain);
        vm.goToStep(RouteWizardStep.dates);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('date-mode-card-custom')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CalendarDatePicker2), findsOneWidget);
        expect(find.text('Seçiniz'), findsNWidgets(2));

        // Geçmiş gün (2026-11-10) tıklandığında seçilmemeli
        final pastDay10 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-10'),
        );
        await tester.ensureVisible(pastDay10);
        await tester.pumpAndSettle();
        await tester.tap(pastDay10);
        await tester.pumpAndSettle();
        expect(vm.specificDateRange, isNull);

        // "1 Hafta" hızlı kısayoluna tıklandığında Başlangıç/Bitiş kapsülleri güncellenir
        final oneWeekShortcut = find.byKey(
          const ValueKey<String>('specific-shortcut-1-week'),
        );
        await tester.ensureVisible(oneWeekShortcut);
        await tester.pumpAndSettle();
        await tester.tap(oneWeekShortcut);
        await tester.pumpAndSettle();

        expect(vm.specificDateRange!.start, DateTime(2026, 11, 17));
        expect(vm.specificDateRange!.end, DateTime(2026, 11, 23));
        expect(find.text('17 Kas 2026'), findsOneWidget);
        expect(find.text('23 Kas 2026'), findsOneWidget);
        expect(find.text('7 Gün'), findsOneWidget);

        // Temizle butonu seçimi sıfırlar
        await tester.tap(
          find.byKey(const ValueKey<String>('calendar-clear-button')),
        );
        await tester.pumpAndSettle();
        expect(vm.specificDateRange, isNull);

        // Bugün (2026-11-17) ve ileri tarih (2026-11-22) gün tıklamalarıyla seçilebilmeli
        final day17 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-17'),
        );
        final day22 = find.byKey(
          const ValueKey<String>('calendar-day-2026-11-22'),
        );
        await tester.ensureVisible(day17);
        await tester.pumpAndSettle();
        await tester.tap(day17);
        await tester.pumpAndSettle();

        await tester.ensureVisible(day22);
        await tester.pumpAndSettle();
        await tester.tap(day22);
        await tester.pumpAndSettle();

        expect(vm.specificDateRange, isNotNull);
        expect(vm.specificDateRange!.start, DateTime(2026, 11, 17));
        expect(vm.specificDateRange!.end, DateTime(2026, 11, 22));
        expect(find.text('17 Kas 2026'), findsOneWidget);
        expect(find.text('22 Kas 2026'), findsOneWidget);
        expect(find.text('6 Gün'), findsOneWidget);
        expect(vm.datePayload.dateMode, 'CUSTOM_RANGE');
        expect(vm.datePayload.startDate, '2026-11-17');
        expect(vm.datePayload.endDate, '2026-11-22');

        // Türkçe ay seçici modu açılır ve Türkçe kısaltmalar gösterir
        await tester.tap(find.text('Kasım'));
        await tester.pumpAndSettle();
        expect(find.text('Oca'), findsOneWidget);
        expect(find.text('Ara'), findsOneWidget);
        await tester.tap(find.text('Ara'));
        await tester.pumpAndSettle();
        expect(find.text('Aralık'), findsOneWidget);
      },
    );

    testWidgets(
      'Dark ve Light temalarda 375px dar ekranda tüm tarih alt görünümleri taşma yapmaz',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final isLight in [false, true]) {
          if (isLight) {
            BeenHereThemeController.instance.setLight();
          } else {
            BeenHereThemeController.instance.setDark();
          }

          final vm = RouteBuilderViewModel(clock: () => fixedToday);
          final spain = RouteBuilderViewModel
              .continentsCatalog.first.subRegions.first.countries.first;
          vm.toggleCountrySelection(spain);
          vm.goToStep(RouteWizardStep.dates);

          await tester.pumpWidget(
            MaterialApp(
              theme: isLight
                  ? BeenHereTheme.lightTheme
                  : BeenHereTheme.darkTheme,
              home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          for (final modeKey in [
            'date-mode-card-flexible',
            'date-mode-card-instant',
            'date-mode-card-seasons',
            'date-mode-card-custom',
          ]) {
            await tester.tap(find.byKey(ValueKey<String>(modeKey)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            await tester.tap(
              find.byKey(const ValueKey<String>('date-subview-back-button')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          vm.dispose();
        }
      },
    );
  });

  group('RouteBuilder - Dinamik Ülke & Şehir Görselleri ve Yer Tutucu Asset Testleri', () {
    GeographyStore buildDynamicImageGeographyStore() {
      final payload = <String, dynamic>{
        'lang': 'tr',
        'continents': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'cont-europe',
            'code': 'EUROPE',
            'name': 'Avrupa',
            'default_name': 'Avrupa',
            'name_translations': <String, String>{'tr': 'Avrupa'},
            'image_url': '',
            'places_count': 10,
            'routes_count': 5,
            'regions': <Map<String, dynamic>>[],
            'countries': <Map<String, dynamic>>[
              // 1. Ülke image_url boş, ilk şehirde Unsplash placeholder, ikinci şehirde gerçek URL var ->
              // Ülke ikinci şehrin gerçek fotoğrafını almalı; ilk şehir skyline asset kullanmalı.
              <String, dynamic>{
                'id': 'country-tr',
                'code': 'TR',
                'continent_code': 'EUROPE',
                'name': 'Türkiye',
                'default_name': 'Türkiye',
                'name_translations': <String, String>{'tr': 'Türkiye'},
                'flag_emoji': '🇹🇷',
                'image_url': '',
                'places_count': 5,
                'routes_count': 2,
                'cities': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'city-ankara',
                    'slug': 'tr:ankara',
                    'country_code': 'TR',
                    'name': 'Ankara',
                    'default_name': 'Ankara',
                    'name_translations': <String, String>{'tr': 'Ankara'},
                    'image_url':
                        'https://images.unsplash.com/photo-1569383746724-6f1b882b8f46?auto=format&fit=crop&w=600&q=80',
                    'is_popular': true,
                    'places_count': 2,
                    'routes_count': 1,
                  },
                  <String, dynamic>{
                    'id': 'city-izmir',
                    'slug': 'tr:izmir',
                    'country_code': 'TR',
                    'name': 'İzmir',
                    'default_name': 'İzmir',
                    'name_translations': <String, String>{'tr': 'İzmir'},
                    'image_url': 'https://cdn.beenhere.dev/geo/izmir-real.jpg',
                    'is_popular': true,
                    'places_count': 3,
                    'routes_count': 1,
                  },
                  <String, dynamic>{
                    'id': 'city-bursa',
                    'slug': 'tr:bursa',
                    'country_code': 'TR',
                    'name': 'Bursa',
                    'default_name': 'Bursa',
                    'name_translations': <String, String>{'tr': 'Bursa'},
                    'image_url': null,
                    'is_popular': false,
                    'places_count': 1,
                    'routes_count': 0,
                  },
                ],
              },
              // 2. Hem ülke hem şehirleri fotoğrafsız -> her ikisi de yerel skyline asset kullanmalı.
              <String, dynamic>{
                'id': 'country-gr',
                'code': 'GR',
                'continent_code': 'EUROPE',
                'name': 'Yunanistan',
                'default_name': 'Yunanistan',
                'name_translations': <String, String>{'tr': 'Yunanistan'},
                'flag_emoji': '🇬🇷',
                'image_url': null,
                'places_count': 2,
                'routes_count': 1,
                'cities': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'city-athens',
                    'slug': 'gr:athens',
                    'country_code': 'GR',
                    'name': 'Atina',
                    'default_name': 'Atina',
                    'name_translations': <String, String>{'tr': 'Atina'},
                    'image_url': '',
                    'is_popular': true,
                    'places_count': 2,
                    'routes_count': 1,
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

    String? extractNetworkImageUrl(Image imageWidget) {
      final provider = imageWidget.image;
      if (provider is NetworkImage) {
        return provider.url;
      }
      if (provider is ResizeImage) {
        final inner = provider.imageProvider;
        if (inner is NetworkImage) {
          return inner.url;
        }
      }
      return null;
    }

    String? extractAssetImageName(Image imageWidget) {
      final provider = imageWidget.image;
      if (provider is AssetImage) {
        return provider.assetName;
      }
      return null;
    }

    tearDown(() {
      BeenHereThemeController.instance.setDark();
    });

    test(
      'ViewModel: Statik fallback Unsplash URL içermez ve DB eşlemesi ülke/şehir görsellerini doğru çözer',
      () async {
        // 1. Çevrimdışı statik fallback ülkeleri ve şehirleri Unsplash URL'si taşımaz
        for (final continent in RouteBuilderViewModel.continentsCatalog) {
          for (final country in continent.allCountries) {
            expect(country.imageUrl, isEmpty);
            for (final city in country.cities) {
              expect(city.imageUrl, isEmpty);
            }
          }
        }

        // 2. GeographyStore üzerinden gelen verilerde Unsplash temizlenir ve
        // boş ülke fotoğrafı ilk fotoğraflı şehirden çekilir
        final store = buildDynamicImageGeographyStore();
        final vm = RouteBuilderViewModel(geographyStore: store);
        await store.ensureLoaded(lang: 'tr');

        final tr = vm.displayedCountries.firstWhere((c) => c.code == 'TR');
        expect(tr.imageUrl, 'https://cdn.beenhere.dev/geo/izmir-real.jpg');
        expect(
          tr.cities.firstWhere((c) => c.name == 'Ankara').imageUrl,
          isEmpty,
        );
        expect(
          tr.cities.firstWhere((c) => c.name == 'İzmir').imageUrl,
          'https://cdn.beenhere.dev/geo/izmir-real.jpg',
        );
        expect(
          tr.cities.firstWhere((c) => c.name == 'Bursa').imageUrl,
          isEmpty,
        );

        final gr = vm.displayedCountries.firstWhere((c) => c.code == 'GR');
        expect(gr.imageUrl, isEmpty);
        expect(
          gr.cities.firstWhere((c) => c.name == 'Atina').imageUrl,
          isEmpty,
        );

        vm.dispose();
        store.dispose();
      },
    );

    testWidgets(
      'Fotoğraflı şehir/ülke Image.network, fotoğrafsız şehir/ülke skyline Image.asset kullanır (Dark & Light)',
      (WidgetTester tester) async {
        final store = buildDynamicImageGeographyStore();
        await store.ensureLoaded(lang: 'tr');

        for (final isLight in [false, true]) {
          if (isLight) {
            BeenHereThemeController.instance.setLight();
          } else {
            BeenHereThemeController.instance.setDark();
          }

          final vm = RouteBuilderViewModel(geographyStore: store);

          await tester.pumpWidget(
            MaterialApp(
              theme: isLight
                  ? BeenHereTheme.lightTheme
                  : BeenHereTheme.darkTheme,
              home: Scaffold(body: RouteBuilderScreen(viewModel: vm)),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // 1. Fotoğrafı bulunan şehir ("İzmir") gerçek URL ile Image.network çizer
          final izmirStack = find
              .ancestor(
                of: find.text('İzmir'),
                matching: find.byType(Stack),
              )
              .first;
          final izmirImage = tester.widget<Image>(
            find
                .descendant(of: izmirStack, matching: find.byType(Image))
                .first,
          );
          expect(
            extractNetworkImageUrl(izmirImage),
            'https://cdn.beenhere.dev/geo/izmir-real.jpg',
          );

          // 2. Unsplash'tan temizlenen ("Ankara") ve null olan ("Bursa") şehir kartları
          // Image.network açmadan doğrudan yerel skyline Image.asset kullanır
          for (final emptyCityName in ['Ankara', 'Bursa']) {
            final cityStack = find
                .ancestor(
                  of: find.text(emptyCityName),
                  matching: find.byType(Stack),
                )
                .first;
            final cityImage = tester.widget<Image>(
              find
                  .descendant(of: cityStack, matching: find.byType(Image))
                  .first,
            );
            expect(extractNetworkImageUrl(cityImage), isNull);
            expect(
              extractAssetImageName(cityImage),
              RouteBuilderViewModel.cityPlaceholderAsset,
            );
          }

          // 3. Kendi image_url'i boş ama şehirlerinden birinde fotoğraf olan ülke ("Türkiye")
          // arka planında o şehrin fotoğrafını (Image.network) kullanır
          final turkeyBannerStack = find
              .ancestor(
                of: find.text('Türkiye'),
                matching: find.byType(Stack),
              )
              .first;
          final turkeyImage = tester.widget<Image>(
            find
                .descendant(
                  of: turkeyBannerStack,
                  matching: find.byType(Image),
                )
                .first,
          );
          expect(
            extractNetworkImageUrl(turkeyImage),
            'https://cdn.beenhere.dev/geo/izmir-real.jpg',
          );

          // 4. Hem ülkesi hem şehirleri fotoğrafsız olan ("Yunanistan" ve "Atina")
          // yerel skyline Image.asset kullanır
          final greeceBannerStack = find
              .ancestor(
                of: find.text('Yunanistan'),
                matching: find.byType(Stack),
              )
              .first;
          final greeceImage = tester.widget<Image>(
            find
                .descendant(
                  of: greeceBannerStack,
                  matching: find.byType(Image),
                )
                .first,
          );
          expect(extractNetworkImageUrl(greeceImage), isNull);
          expect(
            extractAssetImageName(greeceImage),
            RouteBuilderViewModel.cityPlaceholderAsset,
          );

          final athensStack = find
              .ancestor(
                of: find.text('Atina'),
                matching: find.byType(Stack),
              )
              .first;
          final athensImage = tester.widget<Image>(
            find
                .descendant(of: athensStack, matching: find.byType(Image))
                .first,
          );
          expect(extractNetworkImageUrl(athensImage), isNull);
          expect(
            extractAssetImageName(athensImage),
            RouteBuilderViewModel.cityPlaceholderAsset,
          );

          vm.dispose();
        }

        store.dispose();
      },
    );
  });

  group('RouteBuilder - Adım 3: Çoklu Para Birimli Dinamik Bütçe Seçimi', () {
    BuilderCountryCatalogItem findCatalogCountry(String code) {
      for (final continent in RouteBuilderViewModel.continentsCatalog) {
        for (final country in continent.allCountries) {
          if (country.code == code) return country;
        }
      }
      throw StateError('Country not found: $code');
    }

    test('ViewModel: Varsayılan 0-Sınırsız, ülke para birimi tekilleştirme, çift yönlü kur dönüşümü ve sınırsız üst tutar desteği', () async {
      final viewModel = RouteBuilderViewModel();
      addTearDown(viewModel.dispose);

      // Varsayılan değerler: TRY birincil, USD ikincil, 0 – Sınırsız (ucu açık), eklenen döviz boş
      expect(viewModel.isBudgetEnabled, isTrue);
      expect(viewModel.userCurrencyCode, 'TRY');
      expect(viewModel.secondaryCurrencyCode, 'USD');
      expect(viewModel.minBudget, 0);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.isMaxBudgetOpenEnded, isTrue);
      expect(viewModel.addedCountryCurrencies, isEmpty);
      expect(viewModel.formattedBudgetSummary, '₺0 – Sınırsız');

      final defaultUsdRange = viewModel.budgetAmountForCurrency('USD');
      expect(defaultUsdRange.min, 0);
      expect(defaultUsdRange.max, isNull);

      // Ucu açık modda sadece Min artırılınca üst sınır ucu açık (null) kalmaya devam eder
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'TRY',
        minAmount: 15000,
      );
      expect(viewModel.minBudget, 15000);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.isMaxBudgetOpenEnded, isTrue);
      expect(viewModel.formattedBudgetSummary, r'₺15.000+ ($435+)');

      // İspanya (ES) + Fransa (FR) + Tayland (TH) + Türkiye (TR) seçelim
      final es = findCatalogCountry('ES');
      final fr = findCatalogCountry('FR');
      final th = findCatalogCountry('TH');
      final tr = findCatalogCountry('TR');

      expect(es.currencyCode, 'EUR');
      expect(es.currencySymbol, '€');
      expect(th.currencyCode, 'THB');
      expect(th.currencySymbol, '฿');

      viewModel.toggleCountrySelection(tr);
      viewModel.toggleCountrySelection(es);
      viewModel.toggleCountrySelection(fr);
      viewModel.toggleCountrySelection(th);

      // TRY hariç ve ES+FR tek EUR altında birleşmiş olmalı
      final available = viewModel.availableSelectedCountryCurrencies;
      expect(available.map((e) => e.code).toList(), ['EUR', 'THB']);
      final eurOption = available.firstWhere((e) => e.code == 'EUR');
      expect(eurOption.symbol, '€');
      expect(eurOption.countryNames, ['İspanya', 'Fransa']);
      expect(eurOption.flagEmojis, ['🇪🇸', '🇫🇷']);

      // Varsayılan olarak eklenen ülke para birimleri yine boştur
      expect(viewModel.addedCountryCurrencies, isEmpty);

      // THB ekle -> listede görünür; clearAllDestinationSelections() eklenen dövizleri de sıfırlar
      viewModel.addCountryCurrency('THB');
      expect(viewModel.addedCountryCurrencies.map((e) => e.code), ['THB']);

      // USD üzerinden somut aralık güncelleme: $1000 min, $2000 max -> TRY ve THB canlı güncellenir
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'USD',
        minAmount: 1000,
        maxAmount: 2000,
      );
      expect(viewModel.minBudget, closeTo(34500, 0.01));
      expect(viewModel.maxBudget, closeTo(69000, 0.01));
      expect(viewModel.isMaxBudgetOpenEnded, isFalse);
      expect(
        viewModel.formattedBudgetSummary,
        r'₺34.500 – ₺69.000 ($1.000 – $2.000)',
      );
      final thbRange = viewModel.budgetAmountForCurrency('THB');
      expect(thbRange.min, closeTo(34800, 0.1));
      expect(thbRange.max, closeTo(69600, 0.1));

      // Yüksek manuel tutar: 250.000 TRY -> üst sınır engeli olmadan kabul edilir ve dövizlere çevrilir
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'TRY',
        maxAmount: 250000,
      );
      expect(viewModel.maxBudget, 250000);
      expect(viewModel.budgetAmountForCurrency('USD').max, closeTo(7246.38, 0.1));
      expect(viewModel.budgetAmountForCurrency('THB').max, closeTo(252173.91, 0.1));

      // Somut üst sınır varken min > max dengelenmesi
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'TRY',
        minAmount: 320000,
      );
      expect(viewModel.minBudget, 320000);
      expect(viewModel.maxBudget, 320000);

      // clearMaxAmount: true ile tekrar ucu açık (Sınırsız) moda dönüş
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'TRY',
        minAmount: 0,
        clearMaxAmount: true,
      );
      expect(viewModel.minBudget, 0);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.isMaxBudgetOpenEnded, isTrue);
      expect(viewModel.formattedBudgetSummary, '₺0 – Sınırsız');

      // Farklı kullanıcı para birimlerinde 0 – Sınırsız korunur ve yüksek manuel tutar (örn. 1.500.000 ¥) engel olmadan kabul edilir
      viewModel.setUserCurrencyCode('USD');
      expect(viewModel.minBudget, 0);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.formattedBudgetSummary, r'$0 – Sınırsız');

      viewModel.setUserCurrencyCode('EUR');
      expect(viewModel.minBudget, 0);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.formattedBudgetSummary, '€0 – Sınırsız');

      viewModel.setUserCurrencyCode('JPY');
      viewModel.updateBudgetRangeForCurrency(
        currencyCode: 'JPY',
        maxAmount: 1500000,
      );
      expect(viewModel.maxBudget, 1500000);
      expect(viewModel.formattedBudgetSummary, contains('¥1.500.000'));

      // TRY'ye geri dön ve kur özeti formatlarını kontrol et
      viewModel.setUserCurrencyCode('TRY');
      expect(viewModel.exchangeRateSummary('USD', 'TRY'), contains('≈'));
      expect(viewModel.exchangeRateSummary('TRY', 'THB'), contains('₺'));

      // Bütçe kapatılınca alt bar etiketi güncellenir
      viewModel.setBudgetEnabled(false);
      expect(viewModel.formattedBudgetSummary, 'Bütçe Sınırı Yok');

      // Tüm konum seçimleri temizlenince eklenen para birimleri de temizlenir
      viewModel.clearAllDestinationSelections();
      expect(viewModel.addedCountryCurrencies, isEmpty);
    });

    test('ViewModel: GeographyStore DB kurları ve ülke para birimi alanları aktarılır', () async {
      final mockClient = MockClient((request) async {
        final payload = <String, dynamic>{
          'version': 1,
          'lang': 'tr',
          'exchange_rates': [
            {
              'code': 'USD',
              'symbol': r'$',
              'name_tr': 'ABD Doları',
              'rate_per_usd': 1.0,
            },
            {
              'code': 'TRY',
              'symbol': '₺',
              'name_tr': 'Türk Lirası',
              'rate_per_usd': 40.0,
            },
            {
              'code': 'THB',
              'symbol': '฿',
              'name_tr': 'Tayland Bahtı',
              'rate_per_usd': 36.0,
            },
          ],
          'continents': [
            {
              'id': 'c-asia',
              'code': 'ASIA',
              'name': 'Asya',
              'default_name': 'Asia',
              'name_translations': {'tr': 'Asya'},
              'image_url': '',
              'regions': [],
              'countries': [
                {
                  'id': 'country-th',
                  'code': 'TH',
                  'continent_code': 'ASIA',
                  'name': 'Tayland',
                  'default_name': 'Thailand',
                  'name_translations': {'tr': 'Tayland'},
                  'aliases': [],
                  'flag_emoji': '🇹🇭',
                  'image_url': '',
                  'places_count': 10,
                  'routes_count': 2,
                  'currency_code': 'THB',
                  'currency_symbol': '฿',
                  'currency_name_tr': 'Tayland Bahtı',
                  'cities': [],
                },
              ],
            },
          ],
        };
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
            client: mockClient,
          ),
        ),
      );
      await store.ensureLoaded(lang: 'tr');

      final vm = RouteBuilderViewModel(geographyStore: store);
      addTearDown(() {
        vm.dispose();
        store.dispose();
      });

      final th = vm.displayedCountries.firstWhere((c) => c.code == 'TH');
      expect(th.currencyCode, 'THB');
      expect(th.currencySymbol, '฿');
      expect(th.currencyNameTr, 'Tayland Bahtı');

      // DB kuru (1 USD = 40 TRY) ile dönüşüm doğrulanır
      vm.updateBudgetRangeForCurrency(
        currencyCode: 'USD',
        minAmount: 100,
        maxAmount: 200,
      );
      expect(vm.minBudget, closeTo(4000, 0.01));
      expect(vm.maxBudget, closeTo(8000, 0.01));
    });

    testWidgets(
      'Widget: TRY ve USD varsayılan görünür, ülke dövizleri gizli başlar, modal ile eklenir ve çift yönlü senkron çalışır',
      (WidgetTester tester) async {
        final viewModel = RouteBuilderViewModel();
        addTearDown(viewModel.dispose);

        // Tayland + İspanya + Fransa seçili iken Bütçe adımına geçelim
        viewModel.toggleCountrySelection(findCatalogCountry('TH'));
        viewModel.toggleCountrySelection(findCatalogCountry('ES'));
        viewModel.toggleCountrySelection(findCatalogCountry('FR'));
        viewModel.goToStep(RouteWizardStep.budget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RouteBuilderScreen(viewModel: viewModel),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> scrollBudgetTo(Finder target) async {
          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey<String>('wizard-step-budget')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            target,
            180,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
        }

        // 1. Ayrı üst "Bütçe" başlığı yok; "Bütçe Yok" hapı kartın sağ üst köşesine entegre,
        // bütünleşik kartta TRY ve USD görünür, THB/EUR GİZLİ başlar
        final unifiedCardFinder = find.byKey(
          const ValueKey<String>('budget-unified-card'),
        );
        final noLimitPillFinder = find.byKey(
          const ValueKey<String>('budget-no-limit-pill'),
        );
        expect(find.text('Bütçe'), findsNothing);
        expect(find.text('Bütçe Yok'), findsOneWidget);
        expect(find.byType(Switch), findsNothing);
        expect(find.text('Varsayılan Para Birimin'), findsNothing);
        expect(find.text('Küresel Karşılık'), findsNothing);
        expect(unifiedCardFinder, findsOneWidget);
        expect(
          find.descendant(
            of: unifiedCardFinder,
            matching: noLimitPillFinder,
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('budget-card-TRY')),
            matching: noLimitPillFinder,
          ),
          findsOneWidget,
        );
        final enabledCardRect = tester.getRect(unifiedCardFinder);
        final enabledPillRect = tester.getRect(noLimitPillFinder);
        expect(
          enabledPillRect.center.dx,
          greaterThan(enabledCardRect.center.dx),
        );
        expect(enabledPillRect.top - enabledCardRect.top, lessThan(24));
        expect(find.byKey(const ValueKey<String>('budget-card-TRY')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('budget-card-USD')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('budget-card-THB')), findsNothing);
        expect(find.byKey(const ValueKey<String>('budget-card-EUR')), findsNothing);
        expect(find.text('Ekonomik'), findsNothing);
        expect(find.text('Orta'), findsNothing);
        expect(find.text('Konforlu'), findsNothing);
        expect(find.text('Lüks'), findsNothing);

        // Varsayılan 0 – Sınırsız (ucu açık) UI doğrulaması ve RangeSlider olmaması:
        // TRY ve USD Min=0, Maks boş (hint: 'Sınırsız'), ekranda RangeSlider ve uç etiketleri bulunmaz
        expect(find.byType(RangeSlider), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('budget-range-slider')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('budget-slider-min-label')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('budget-slider-max-label')),
          findsNothing,
        );

        final initialTryMin = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-TRY-min')),
        );
        final initialTryMax = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-TRY-max')),
        );
        final initialUsdMax = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-USD-max')),
        );
        expect(initialTryMin.controller?.text, '0');
        expect(initialTryMax.controller?.text, isEmpty);
        expect(initialTryMax.decoration?.hintText, 'Sınırsız');
        expect(initialUsdMax.controller?.text, isEmpty);
        expect(initialUsdMax.decoration?.hintText, 'Sınırsız');
        expect(find.text('Ziyaretçi Seçimi (₺0 – Sınırsız)'), findsOneWidget);

        // TRY Maks kutusuna somut değer girilince USD Maks canlı güncellenir, silinince tekrar Sınırsız olur
        final initialTryMaxFinder = find.byKey(
          const ValueKey<String>('budget-input-TRY-max'),
        );
        await tester.enterText(initialTryMaxFinder, '50000');
        await tester.pumpAndSettle();
        expect(viewModel.isMaxBudgetOpenEnded, isFalse);
        expect(viewModel.maxBudget, 50000);
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-USD-max')),
          ).controller?.text,
          '1.449',
        );

        await tester.enterText(initialTryMaxFinder, '');
        await tester.pumpAndSettle();
        expect(viewModel.isMaxBudgetOpenEnded, isTrue);
        expect(viewModel.maxBudget, isNull);
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-TRY-max')),
          ).controller?.text,
          isEmpty,
        );
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-USD-max')),
          ).controller?.text,
          isEmpty,
        );

        await scrollBudgetTo(find.text('+ Ülke Para Birimi Ekle'));
        expect(find.text('+ Ülke Para Birimi Ekle'), findsOneWidget);

        // 2. "+ Ülke Para Birimi Ekle" butonuna bas -> seçili ülkelerin dövizleri listelenir (THB & tekil EUR)
        await tester.tap(
          find.byKey(const ValueKey<String>('budget-add-currency-button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('budget-currency-picker-sheet')),
          findsOneWidget,
        );
        expect(find.textContaining('Tayland Bahtı (THB ฿)'), findsOneWidget);
        expect(find.textContaining('Euro (EUR €)'), findsOneWidget);
        expect(find.textContaining('İspanya, Fransa'), findsOneWidget);

        // 3. Tayland Bahtı (THB) seçeneğini ekle -> sheet kapanır ve THB kartı açılır
        await tester.tap(
          find.byKey(const ValueKey<String>('budget-currency-option-THB')),
        );
        await tester.pumpAndSettle();

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-card-THB')));
        expect(find.byKey(const ValueKey<String>('budget-card-THB')), findsOneWidget);

        // 4. Çift yönlü dinamik dönüşüm (ucu açıkken Min girilince Maks ucu açık kalır):
        // THB Minimum kutusuna 20000 gir -> TRY ve USD Min kutuları canlı güncellenir, Maks Sınırsız kalır
        final thbMinFinder = find.byKey(
          const ValueKey<String>('budget-input-THB-min'),
        );
        await scrollBudgetTo(thbMinFinder);
        await tester.enterText(thbMinFinder, '20000');
        await tester.pumpAndSettle();

        expect(viewModel.isMaxBudgetOpenEnded, isTrue);
        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-TRY-min')));
        final tryMinField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-TRY-min')),
        );
        expect(tryMinField.controller?.text, '19.828');

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-USD-min')));
        final usdMinField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-USD-min')),
        );
        expect(usdMinField.controller?.text, '575');

        // USD Maksimum kutusuna 2000 gir -> TRY ve THB Maks kutuları canlı güncellenir
        final usdMaxFinder = find.byKey(
          const ValueKey<String>('budget-input-USD-max'),
        );
        await scrollBudgetTo(usdMaxFinder);
        await tester.enterText(usdMaxFinder, '2000');
        await tester.pumpAndSettle();

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-TRY-max')));
        final tryMaxField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-TRY-max')),
        );
        expect(tryMaxField.controller?.text, '69.000');

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-THB-max')));
        final thbMaxField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-THB-max')),
        );
        expect(thbMaxField.controller?.text, '69.600');

        // Yüksek tutar (250000 TRY) elle girildiğinde üst sınır engeli olmadan USD ve THB güncellenir
        final tryMaxFinder = find.byKey(
          const ValueKey<String>('budget-input-TRY-max'),
        );
        await scrollBudgetTo(tryMaxFinder);
        await tester.enterText(tryMaxFinder, '250000');
        await tester.pumpAndSettle();
        expect(viewModel.maxBudget, 250000);
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-USD-max')),
          ).controller?.text,
          '7.246',
        );
        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-THB-max')));
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-THB-max')),
          ).controller?.text,
          '252.174',
        );

        // Maks kutusu boşaltıldığında tüm para birimleri tekrar Sınırsız (ucu açık) moda döner
        await scrollBudgetTo(tryMaxFinder);
        await tester.enterText(tryMaxFinder, '');
        await tester.pumpAndSettle();
        expect(viewModel.isMaxBudgetOpenEnded, isTrue);
        expect(viewModel.maxBudget, isNull);
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-USD-max')),
          ).controller?.text,
          isEmpty,
        );
        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-THB-max')));
        expect(
          tester.widget<TextField>(
            find.byKey(const ValueKey<String>('budget-input-THB-max')),
          ).controller?.text,
          isEmpty,
        );

        // TRY Minimum kutusuna 25000 gir -> USD ve THB Min kutuları canlı güncellenir
        final tryMinFinder = find.byKey(
          const ValueKey<String>('budget-input-TRY-min'),
        );
        await scrollBudgetTo(tryMinFinder);
        await tester.enterText(tryMinFinder, '25000');
        await tester.pumpAndSettle();

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-USD-min')));
        final usdMinAfterTry = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-USD-min')),
        );
        expect(usdMinAfterTry.controller?.text, '725');

        await scrollBudgetTo(find.byKey(const ValueKey<String>('budget-input-THB-min')));
        final thbMinAfterTry = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('budget-input-THB-min')),
        );
        expect(thbMinAfterTry.controller?.text, '25.217');

        // Min kutusu boşaltıldığında 0 olur
        await scrollBudgetTo(tryMinFinder);
        await tester.enterText(tryMinFinder, '');
        await tester.pumpAndSettle();
        expect(viewModel.minBudget, 0);
        expect(viewModel.formattedBudgetSummary, '₺0 – Sınırsız');

        // 5. THB kartını X butonuyla kaldır -> kart kaybolur
        final removeThbFinder = find.byKey(
          const ValueKey<String>('budget-remove-currency-THB'),
        );
        await scrollBudgetTo(removeThbFinder);
        await tester.tap(removeThbFinder);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('budget-card-THB')), findsNothing);

        // 6. Kartın sağ üst köşesindeki "Bütçe Yok" hapı -> bütçeyi kapatır,
        // kapalı kartın aynı sağ üst köşesinde aktif "Bütçe Yok ✓" gösterir (ekstra ikinci buton yok)
        await tester.drag(
          find.descendant(
            of: find.byKey(const ValueKey<String>('wizard-step-budget')),
            matching: find.byType(ListView),
          ).first,
          const Offset(0, 600),
        );
        await tester.pumpAndSettle();
        final pillRectBeforeDisable = tester.getRect(noLimitPillFinder);
        await tester.tap(noLimitPillFinder);
        await tester.pumpAndSettle();

        final disabledCardFinder = find.byKey(
          const ValueKey<String>('budget-disabled-state-card'),
        );
        expect(viewModel.isBudgetEnabled, isFalse);
        expect(unifiedCardFinder, findsNothing);
        expect(disabledCardFinder, findsOneWidget);
        expect(find.text('Bütçe sınırı belirtilmedi'), findsOneWidget);
        expect(find.text('Bütçe Yok ✓'), findsOneWidget);
        expect(find.text('Bütçe Belirle'), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('budget-enable-cta-button')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: disabledCardFinder,
            matching: noLimitPillFinder,
          ),
          findsOneWidget,
        );
        final disabledCardRect = tester.getRect(disabledCardFinder);
        final disabledPillRect = tester.getRect(noLimitPillFinder);
        expect(
          disabledPillRect.center.dx,
          greaterThan(disabledCardRect.center.dx),
        );
        expect(
          disabledPillRect.top,
          closeTo(pillRectBeforeDisable.top, 1.0),
        );
        expect(
          disabledPillRect.right,
          closeTo(pillRectBeforeDisable.right, 1.0),
        );
        expect(
          find.text('Ziyaretçi Seçimi (Bütçe Sınırı Yok)'),
          findsOneWidget,
        );

        // Aynı sağ üst köşedeki "Bütçe Yok ✓" hapına tekrar dokunulunca bütçe yeniden açılır
        await tester.tap(noLimitPillFinder);
        await tester.pumpAndSettle();
        expect(viewModel.isBudgetEnabled, isTrue);
        expect(disabledCardFinder, findsNothing);
        expect(unifiedCardFinder, findsOneWidget);
        expect(find.text('Bütçe Yok'), findsOneWidget);
        expect(
          find.descendant(
            of: unifiedCardFinder,
            matching: noLimitPillFinder,
          ),
          findsOneWidget,
        );

        // Tekrar kapatıp 4. adıma geçilebildiğini doğrula
        await tester.tap(noLimitPillFinder);
        await tester.pumpAndSettle();
        expect(viewModel.isBudgetEnabled, isFalse);

        // Kapalıyken bile İleri butonu ile 4. adıma geçilebilmeli
        await tester.tap(find.text('Ziyaretçi Seçimi (Bütçe Sınırı Yok)'));
        await tester.pumpAndSettle();
        expect(viewModel.currentStep, RouteWizardStep.travelers);
      },
    );

    testWidgets(
      'Widget: Dark ve Light temada 375px dar ekranda bütçe adımı ve modal sıfır overflow verir',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          BeenHereThemeController.instance.setDark();
        });

        for (final isDark in [true, false]) {
          if (isDark) {
            BeenHereThemeController.instance.setDark();
          } else {
            BeenHereThemeController.instance.setLight();
          }

          final viewModel = RouteBuilderViewModel();
          // Yalnızca Türkiye (TRY) seçiliyken modal mesajını ve eklenen döviz kartını test edelim
          viewModel.toggleCountrySelection(findCatalogCountry('TR'));
          viewModel.addCountryCurrency('EUR');
          viewModel.goToStep(RouteWizardStep.budget);

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark
                  ? BeenHereTheme.darkTheme
                  : BeenHereTheme.lightTheme,
              home: Scaffold(
                body: RouteBuilderScreen(viewModel: viewModel),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey<String>('wizard-step-budget')),
                matching: find.byType(Scrollable),
              )
              .first;

          expect(tester.takeException(), isNull);
          expect(find.byType(RangeSlider), findsNothing);
          expect(find.byKey(const ValueKey<String>('budget-card-TRY')), findsOneWidget);

          // Dar ekranda sağ üst köşedeki Bütçe Yok toggle geçişi de sıfır overflow vermeli
          final narrowNoLimitPill = find.byKey(
            const ValueKey<String>('budget-no-limit-pill'),
          );
          await tester.tap(narrowNoLimitPill);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('budget-disabled-state-card')),
            findsOneWidget,
          );
          await tester.tap(narrowNoLimitPill);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('budget-unified-card')),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<String>('budget-card-USD')),
            180,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey<String>('budget-card-USD')), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<String>('budget-card-EUR')),
            180,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey<String>('budget-card-EUR')), findsOneWidget);

          // Modal açılıp TRY/USD bilgilendirme + popüler para birimleri dar ekranda taşma yapmamalı
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<String>('budget-add-currency-button')),
            180,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey<String>('budget-add-currency-button')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining('zaten TRY / USD kullanıyor'),
            findsOneWidget,
          );

          Navigator.of(
            tester.element(
              find.byKey(const ValueKey<String>('budget-currency-picker-sheet')),
            ),
          ).pop();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          viewModel.dispose();
        }
      },
    );
  });

  group('RouteBuilder - 4. Adım Sonrası 3\'lü Mod Seçimi ve Swipe & Pick (Wireframe 1 & 2) Testleri', () {
    BuilderCountryCatalogItem findCountryByCode(String code) {
      for (final continent in RouteBuilderViewModel.continentsCatalog) {
        for (final subRegion in continent.subRegions) {
          for (final country in subRegion.countries) {
            if (country.code == code) return country;
          }
        }
      }
      throw StateError('Ülke bulunamadı: $code');
    }

    testWidgets(
      'Wireframe 1 & 2: 3\'lü Mod Seçimi, Özel Turlar yönlendirmesi, fotoğraf geçişi, sağa/sola kaydırma, geri al (undo), çoklu filtre, elle arama ve rota önizlemesi akışı',
      (WidgetTester tester) async {
        final viewModel = RouteBuilderViewModel();
        viewModel.toggleCountrySelection(findCountryByCode('GB'));
        viewModel.goToStep(RouteWizardStep.travelers);

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(
              body: RouteBuilderScreen(viewModel: viewModel),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 4. Adımda "Rotayı Oluşturmaya Başla (2 Kişi)" butonuna tıkla
        final startButton = find.text('Rotayı Oluşturmaya Başla (2 Kişi)');
        expect(startButton, findsOneWidget);
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // Wireframe 1: 3'lü Mod Seçim Ekranı açılmalı
        expect(
          find.byKey(const ValueKey<String>('route-mode-selection-view')),
          findsOneWidget,
        );
        expect(find.text('Özgün Rota'), findsOneWidget);
        expect(
          find.text('Bağımsız olarak kendi rotanızı oluşturun'),
          findsOneWidget,
        );
        expect(find.text('Gezgin Rotaları'), findsOneWidget);
        expect(
          find.text('Yerli ve global gezginlerin deneyimlerinden faydalanın'),
          findsOneWidget,
        );
        expect(find.text('Özel Turlar'), findsOneWidget);
        expect(
          find.text('Tur şirketlerinin düzenlediği seyahat rotalarını keşfedin'),
          findsOneWidget,
        );

        // 2. "Parametreler" butonuna basınca 4. adıma geri dönmeli, tekrar basınca Mod Seçimi açılmalı
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-back-to-params-button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Seçili Ziyaretçi Adımı'), findsOneWidget);

        await tester.tap(find.text('Rotayı Oluşturmaya Başla (2 Kişi)'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('route-mode-selection-view')),
          findsOneWidget,
        );

        // 3. "Özel Turlar" seçildiğinde istisna yönlendirme ekranı açılmalı
        await tester.tap(
          find.byKey(const ValueKey<String>('route-mode-card-private-tours')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('private-tours-redirect-view')),
          findsOneWidget,
        );
        expect(
          find.text('Kurumsal Tur Şirketleri Özel Yönlendirmesi'),
          findsOneWidget,
        );

        // "Mod Seçimine Dön" ile tekrar 3'lü Mod Seçim ekranına dönelim
        await tester.tap(
          find.byKey(
            const ValueKey<String>('private-tours-back-to-modes-button'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('route-mode-selection-view')),
          findsOneWidget,
        );

        // 4. "Özgün Rota" kartına tıkla -> Wireframe 2 Swipe & Pick ekranı açılmalı
        await tester.tap(
          find.byKey(const ValueKey<String>('route-mode-card-original')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('swipe-deck-stage-view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
          findsOneWidget,
        );

        // Wireframe 2 üzerindeki 6 kontrol butonu ve alt orta mekan kimliği doğrulanır
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-filter-button')),
          findsOneWidget,
        );
        expect(
          find.text('Kategoriler, Gezginler, Tur şirketleri'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-manual-search-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-dismissed-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-selected-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-undo-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-preview-button')),
          findsOneWidget,
        );

        // İlk vitrin mekanı: Big Ben / İngiltere, Londra / Tarihi Yapı, Simge Yapı
        expect(find.text('Big Ben'), findsOneWidget);
        expect(find.text('İngiltere, Londra'), findsOneWidget);
        expect(find.text('Tarihi Yapı, Simge Yapı'), findsOneWidget);

        // 5. Karta dokunma (Tap) -> ilgili mekanın fotoğrafları arasında geçiş
        expect(find.textContaining('Fotoğraf 1/3'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Fotoğraf 2/3'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Fotoğraf 3/3'), findsOneWidget);

        // 6. Sağa kaydırma eylemi (Swipe Right) -> Seçili mekanlar listesine ekleme
        await tester.drag(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
          const Offset(240, 0),
        );
        await tester.pumpAndSettle();

        expect(viewModel.selectedDeckPlaces.length, 1);
        expect(viewModel.selectedDeckPlaces.first.name, 'Big Ben');
        expect(
          find.byKey(
            const ValueKey<String>(
              'swipe-side-mini-card-selected-gb-london-big-ben',
            ),
          ),
          findsOneWidget,
        );
        // Sıradaki mekana geçilmiş olmalı (Tower Bridge)
        expect(find.text('Tower Bridge'), findsOneWidget);

        // 7. Sola kaydırma eylemi (Swipe Left) -> Seçilmemiş mekanlar listesine ekleme
        await tester.drag(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
          const Offset(-240, 0),
        );
        await tester.pumpAndSettle();

        expect(viewModel.dismissedDeckPlaces.length, 1);
        expect(viewModel.dismissedDeckPlaces.first.name, 'Tower Bridge');
        expect(
          find.byKey(
            const ValueKey<String>(
              'swipe-side-mini-card-dismissed-gb-london-tower-bridge',
            ),
          ),
          findsOneWidget,
        );

        // 8. Sol Alt "Önceki işlemi geri al" (Undo) butonu -> Sola kaydırılan Tower Bridge geri gelir
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-undo-button')),
        );
        await tester.pumpAndSettle();
        expect(viewModel.dismissedDeckPlaces, isEmpty);
        expect(find.text('Tower Bridge'), findsOneWidget);

        // Tekrar Undo -> Sağa kaydırılan Big Ben geri gelir
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-undo-button')),
        );
        await tester.pumpAndSettle();
        expect(viewModel.selectedDeckPlaces, isEmpty);
        expect(find.text('Big Ben'), findsOneWidget);

        // Big Ben'i tekrar sağa, Tower Bridge'i sola kaydıralım
        await tester.drag(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
          const Offset(240, 0),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
          const Offset(-240, 0),
        );
        await tester.pumpAndSettle();
        expect(viewModel.selectedDeckPlaces.length, 1);
        expect(viewModel.dismissedDeckPlaces.length, 1);

        // 9. Sol Orta "Seçilmemiş Mekanlar" çekmecesini aç ve Tower Bridge'i Seçili Listeye al
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-dismissed-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-dismissed-sheet')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'dismissed-to-selected-gb-london-tower-bridge',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(viewModel.dismissedDeckPlaces, isEmpty);
        expect(viewModel.selectedDeckPlaces.length, 2);
        Navigator.of(
          tester.element(
            find.byKey(const ValueKey<String>('swipe-deck-dismissed-sheet')),
          ),
        ).pop();
        await tester.pumpAndSettle();

        // 10. Sağ Üst "Elle Mekan Arama" çekmecesini aç, "Efes" ara ve seçili listeye ekle
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-manual-search-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-manual-search-sheet')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('manual-place-search-input')),
          'Efes',
        );
        await tester.pumpAndSettle();
        expect(find.text('Efes Antik Kenti'), findsOneWidget);

        await tester.tap(
          find.byKey(
            const ValueKey<String>('manual-search-add-tr-izmir-efes'),
          ),
        );
        await tester.pumpAndSettle();
        expect(viewModel.selectedDeckPlaces.length, 3);
        Navigator.of(
          tester.element(
            find.byKey(
              const ValueKey<String>('swipe-deck-manual-search-sheet'),
            ),
          ),
        ).pop();
        await tester.pumpAndSettle();

        // 11. Sol Üst "Kategori, Gezgin, Tur Şirketi Seçimi" çoklu filtre çekmecesini aç
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-filter-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-filter-sheet')),
          findsOneWidget,
        );

        // Gezgin Rotaları'nı da çoklu olarak seçelim + bir kategori seçelim
        await tester.tap(
          find.byKey(const ValueKey<String>('filter-source-traveler')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('filter-category-Tarihi Yapı')),
        );
        await tester.pumpAndSettle();
        expect(
          viewModel.activeDeckSourceModes.contains(
            RouteDeckSourceMode.originalRoute,
          ),
          isTrue,
        );
        expect(
          viewModel.activeDeckSourceModes.contains(
            RouteDeckSourceMode.travelerRoutes,
          ),
          isTrue,
        );
        expect(viewModel.activeDeckCategories.contains('Tarihi Yapı'), isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('filter-sheet-apply-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Özgün Rota + Gezgin Rotaları • 1 Kategori'),
          findsOneWidget,
        );

        // 12. Sağ Alt "Rota Önizlemesi (Sonraki Adım)" çekmecesini aç
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-preview-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-route-preview-sheet')),
          findsOneWidget,
        );
        expect(find.text('Rota Önizlemesi (Sonraki Adım)'), findsOneWidget);
        expect(find.text('Rotadaki Seçili Duraklar (3)'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('route-preview-confirm-button')),
        );
        await tester.pumpAndSettle();

        // 13. Filtre içinden "Özel Turlar (Tur Şirketleri) ↗" seçildiğinde özel yönlendirme ekranına geçilmeli
        await tester.tap(
          find.byKey(const ValueKey<String>('swipe-deck-filter-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('filter-source-private-tours')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('private-tours-redirect-view')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Dar ekran (375x667) Dark & Light temada 3\'lü Mod Seçimi ve Swipe & Pick ekranı sıfır overflow verir',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          BeenHereThemeController.instance.setDark();
        });

        for (final isDark in [true, false]) {
          if (isDark) {
            BeenHereThemeController.instance.setDark();
          } else {
            BeenHereThemeController.instance.setLight();
          }

          final viewModel = RouteBuilderViewModel();
          viewModel.toggleCountrySelection(findCountryByCode('ES'));
          viewModel.goToStep(RouteWizardStep.travelers);
          viewModel.enterRouteCreationFlow();

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark
                  ? BeenHereTheme.darkTheme
                  : BeenHereTheme.lightTheme,
              home: Scaffold(
                body: RouteBuilderScreen(viewModel: viewModel),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Gezgin Rotaları ile Swipe & Pick ekranına geç
          await tester.tap(
            find.byKey(const ValueKey<String>('route-mode-card-traveler')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('swipe-deck-stage-card')),
            findsOneWidget,
          );

          viewModel.dispose();
        }
      },
    );

    testWidgets(
      'Swipe & Pick: Tinder tarzı tutup çekme, alttan sıradaki mekanın gözükmesi, çekimde seçilenler/geçilenler dahil butonların gizlenmesi, sağ üst yeşil tik / sol üst kırmızı X ikonu, yanlardan boşluksuz tam genişlik ve sadece alt menü kısmının buzlu olması',
      (WidgetTester tester) async {
        final viewModel = RouteBuilderViewModel();
        viewModel.toggleCountrySelection(findCountryByCode('GB'));
        viewModel.goToStep(RouteWizardStep.travelers);
        viewModel.enterRouteCreationFlow();
        viewModel.openOriginalRouteSwipeDeck();

        await tester.pumpWidget(
          MaterialApp(
            theme: BeenHereTheme.darkTheme,
            home: Scaffold(
              body: RouteBuilderScreen(viewModel: viewModel),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stageViewFinder = find.byKey(
          const ValueKey<String>('swipe-deck-stage-view'),
        );
        final cardFinder = find.byKey(
          const ValueKey<String>('swipe-deck-stage-card'),
        );
        final rotationFinder = find.byKey(
          const ValueKey<String>('swipe-deck-card-rotation'),
        );
        final surfaceFinder = find.byKey(
          const ValueKey<String>('swipe-deck-card-surface'),
        );
        final fadeFinder = find.byKey(
          const ValueKey<String>('swipe-deck-card-fade'),
        );
        final bottomMenuFrostFinder = find.byKey(
          const ValueKey<String>('swipe-deck-bottom-menu-frost'),
        );
        final filterOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-filter-controls-opacity'),
        );
        final searchOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-search-button-opacity'),
        );
        final selectedOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-selected-button-opacity'),
        );
        final dismissedOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-dismissed-button-opacity'),
        );
        final undoOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-undo-button-opacity'),
        );
        final previewOpacityFinder = find.byKey(
          const ValueKey<String>('swipe-deck-preview-button-opacity'),
        );

        const double expectedGentleTiltRadians = 6.0 * math.pi / 180.0;

        // 0. Kart yanlardan boşluksuz (left: 0, right: tam ekran) ve en alta (alt menüye) kadar genişler;
        //    sadece alttaki menü şeridi buzlu (swipe-deck-bottom-menu-frost) gözükür.
        final stageRect = tester.getRect(stageViewFinder);
        final cardRect = tester.getRect(cardFinder);
        expect(cardRect.left, closeTo(0.0, 0.01));
        expect(cardRect.right, closeTo(stageRect.right, 0.01));
        expect(cardRect.bottom, closeTo(stageRect.bottom, 0.01));

        expect(bottomMenuFrostFinder, findsOneWidget);
        final frostRect = tester.getRect(bottomMenuFrostFinder);
        expect(frostRect.bottom, closeTo(stageRect.bottom, 0.01));
        final shaderMaskFinder = find.descendant(
          of: bottomMenuFrostFinder,
          matching: find.byType(ShaderMask),
        );
        expect(shaderMaskFinder, findsOneWidget);
        expect(
          tester.widget<ShaderMask>(shaderMaskFinder).blendMode,
          BlendMode.dstIn,
        );
        expect(
          find.descendant(
            of: bottomMenuFrostFinder,
            matching: find.byType(ImageFiltered),
          ),
          findsOneWidget,
        );

        // Mekan başlığı/kategorileri ve alt butonlar alttaki menü alanının üstünde yer alır
        final categoriesRect = tester.getRect(
          find.byKey(const ValueKey<String>('swipe-card-place-categories')),
        );
        expect(categoriesRect.bottom, lessThanOrEqualTo(stageRect.bottom - 68.0));

        // Başlangıçta ilk kart (Big Ben) 1.0 opasitede ve tüm çevre butonları görünür (1.0)
        expect(find.text('Big Ben'), findsOneWidget);
        expect(
          tester.widget<FadeTransition>(fadeFinder).opacity.value,
          closeTo(1.0, 0.001),
        );
        expect(
          tester.widget<AnimatedOpacity>(filterOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(searchOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(selectedOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(dismissedOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(undoOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(previewOpacityFinder).opacity,
          1.0,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-card-right-check-icon')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-card-left-x-icon')),
          findsNothing,
        );

        // =====================================================================
        // 1. SAĞA TUTUP ÇEKME:
        //    - Dik 30°/45° eğim yok, Tinder tarzı hafif çekim (±6°)
        //    - Alttan sıradaki mekan (Tower Bridge - swipe-deck-next-card) gözükür
        //    - Kartın sağ üst köşesinde yeşil tik ikonu (swipe-card-right-check-icon) çıkar
        //    - Seçilenler ve Geçilenler dahil tüm çevre butonları gizlenir (opacity: 0.0)
        // =====================================================================
        final rightGesture = await tester.startGesture(
          tester.getCenter(cardFinder),
        );
        await rightGesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await rightGesture.moveBy(const Offset(160, 0));
        await tester.pump();

        // A) Tinder tarzı hafif çekim açısı (+6°), dik açı devrilmesi yok
        final rightRotationMatrix =
            tester.widget<Transform>(rotationFinder).transform;
        final rightAngleRadians = math.atan2(
          rightRotationMatrix.entry(1, 0),
          rightRotationMatrix.entry(0, 0),
        );
        expect(rightAngleRadians, closeTo(expectedGentleTiltRadians, 0.001));

        // B) Alttan sıradaki mekan kartı (Tower Bridge) gözükür
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-next-card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-next-card-place-title')),
          findsOneWidget,
        );
        expect(find.text('Tower Bridge'), findsOneWidget);

        // C) Sağa çekilirken kartın SOL ÜSTÜNDE arka plansız/bordersız büyük yeşil tik ikonu
        //    ve Tailwind animate-ping tarzı sonsuz yankı animasyonu çıkar (X ikonu çıkmaz)
        final rightCheckFinder = find.byKey(
          const ValueKey<String>('swipe-card-right-check-icon'),
        );
        expect(rightCheckFinder, findsOneWidget);
        expect(
          tester.getCenter(rightCheckFinder).dx,
          lessThan(tester.getCenter(surfaceFinder).dx),
        );
        // Arka plan/border kutusu (Container/DecoratedBox) yoktur, sadece büyük ikonlar vardır
        expect(
          find.descendant(
            of: rightCheckFinder,
            matching: find.byType(Container),
          ),
          findsNothing,
        );
        final primaryCheckIcon = tester.widget<Icon>(
          find.descendant(
            of: find.descendant(
              of: rightCheckFinder,
              matching: find.byKey(
                const ValueKey<String>('swipe-card-primary-action-icon'),
              ),
            ),
            matching: find.byType(Icon),
          ),
        );
        expect(primaryCheckIcon.size, 56.0);
        expect(primaryCheckIcon.color, BeenHereColors.verifiedEmerald);

        // Tailwind animate-ping sonsuz animasyonu zaman ilerledikçe büyür ve sönümlenir
        await tester.pump(const Duration(milliseconds: 300));
        final pingTransform = tester.widget<Transform>(
          find.descendant(
            of: rightCheckFinder,
            matching: find.byKey(
              const ValueKey<String>('swipe-card-ping-echo'),
            ),
          ),
        );
        final pingOpacity = tester.widget<Opacity>(
          find.descendant(
            of: rightCheckFinder,
            matching: find.byKey(
              const ValueKey<String>('swipe-card-ping-echo-opacity'),
            ),
          ),
        );
        expect(pingTransform.transform.getMaxScaleOnAxis(), greaterThan(1.2));
        expect(pingOpacity.opacity, greaterThan(0.0));
        expect(pingOpacity.opacity, lessThan(0.75));

        expect(
          find.byKey(const ValueKey<String>('swipe-card-left-x-icon')),
          findsNothing,
        );

        // D) Yeşil (BeenHereColors.verifiedEmerald) BoxShadow aktif
        final rightDecoration =
            tester.widget<Container>(surfaceFinder).decoration! as BoxDecoration;
        final rightPrimaryShadow = rightDecoration.boxShadow!.first;
        expect(
          rightPrimaryShadow.color.r,
          closeTo(BeenHereColors.verifiedEmerald.r, 0.01),
        );
        expect(
          rightPrimaryShadow.color.g,
          closeTo(BeenHereColors.verifiedEmerald.g, 0.01),
        );
        expect(
          rightPrimaryShadow.color.b,
          closeTo(BeenHereColors.verifiedEmerald.b, 0.01),
        );

        // E) Seçilenler ve Geçilenler dahil TÜM çevre butonları gizlenir (opacity: 0.0)
        expect(
          tester.widget<AnimatedOpacity>(filterOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(searchOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(selectedOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(dismissedOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(undoOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(previewOpacityFinder).opacity,
          0.0,
        );

        // F) Parmağı bırak -> kart kayarak çıkar, alttaki mekan (Tower Bridge) 0 -> 1 opasiteyle aktifleşir
        await rightGesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 210));
        expect(find.text('Tower Bridge'), findsOneWidget);
        final opacityAtNewCardStart =
            tester.widget<FadeTransition>(fadeFinder).opacity.value;
        expect(opacityAtNewCardStart, lessThan(0.25));

        await tester.pump(const Duration(milliseconds: 120));
        final opacityMidFadeIn =
            tester.widget<FadeTransition>(fadeFinder).opacity.value;
        expect(opacityMidFadeIn, greaterThan(opacityAtNewCardStart));
        expect(opacityMidFadeIn, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(
          tester.widget<FadeTransition>(fadeFinder).opacity.value,
          closeTo(1.0, 0.001),
        );
        expect(
          tester.widget<AnimatedOpacity>(selectedOpacityFinder).opacity,
          1.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(dismissedOpacityFinder).opacity,
          1.0,
        );

        // =====================================================================
        // 2. SOLA TUTUP ÇEKME:
        //    - Kartın sol üst köşesinde kırmızı X ikonu (swipe-card-left-x-icon) çıkar
        //    - Alttan sıradaki mekan kartı gözükür
        //    - Seçilenler ve Geçilenler dahil tüm çevre butonları gizlenir
        // =====================================================================
        final leftGesture = await tester.startGesture(
          tester.getCenter(cardFinder),
        );
        await leftGesture.moveBy(const Offset(-20, 0));
        await tester.pump();
        await leftGesture.moveBy(const Offset(-160, 0));
        await tester.pump();

        // A) Tinder tarzı hafif sola çekim açısı (-6°)
        final leftRotationMatrix =
            tester.widget<Transform>(rotationFinder).transform;
        final leftAngleRadians = math.atan2(
          leftRotationMatrix.entry(1, 0),
          leftRotationMatrix.entry(0, 0),
        );
        expect(leftAngleRadians, closeTo(-expectedGentleTiltRadians, 0.001));

        // B) Alttan sıradaki 3. mekan kartı gözükür
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-next-card')),
          findsOneWidget,
        );

        // C) Sola çekilirken kartın SAĞ ÜSTÜNDE arka plansız/bordersız büyük kırmızı X ikonu çıkar
        final leftXFinder = find.byKey(
          const ValueKey<String>('swipe-card-left-x-icon'),
        );
        expect(leftXFinder, findsOneWidget);
        expect(
          tester.getCenter(leftXFinder).dx,
          greaterThan(tester.getCenter(surfaceFinder).dx),
        );
        expect(
          find.descendant(
            of: leftXFinder,
            matching: find.byType(Container),
          ),
          findsNothing,
        );
        final primaryXIcon = tester.widget<Icon>(
          find.descendant(
            of: find.descendant(
              of: leftXFinder,
              matching: find.byKey(
                const ValueKey<String>('swipe-card-primary-action-icon'),
              ),
            ),
            matching: find.byType(Icon),
          ),
        );
        expect(primaryXIcon.size, 56.0);
        expect(primaryXIcon.color, const Color(0xFFE53935));
        expect(
          find.byKey(const ValueKey<String>('swipe-card-right-check-icon')),
          findsNothing,
        );

        // D) Kırmızı (Color(0xFFE53935)) BoxShadow aktif
        const expectedRedShadowColor = Color(0xFFE53935);
        final leftDecoration =
            tester.widget<Container>(surfaceFinder).decoration! as BoxDecoration;
        final leftPrimaryShadow = leftDecoration.boxShadow!.first;
        expect(
          leftPrimaryShadow.color.r,
          closeTo(expectedRedShadowColor.r, 0.01),
        );
        expect(
          leftPrimaryShadow.color.g,
          closeTo(expectedRedShadowColor.g, 0.01),
        );
        expect(
          leftPrimaryShadow.color.b,
          closeTo(expectedRedShadowColor.b, 0.01),
        );

        // E) Seçilenler ve Geçilenler dahil tüm çevre butonları gizlenir (opacity: 0.0)
        expect(
          tester.widget<AnimatedOpacity>(filterOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(searchOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(selectedOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(dismissedOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(undoOpacityFinder).opacity,
          0.0,
        );
        expect(
          tester.widget<AnimatedOpacity>(previewOpacityFinder).opacity,
          0.0,
        );

        // F) Parmağı bırak -> sola kayarak çıkış ve sonraki kartın 0 -> 1 opasite geçişi
        await leftGesture.up();
        await tester.pumpAndSettle();
        expect(
          tester.widget<FadeTransition>(fadeFinder).opacity.value,
          closeTo(1.0, 0.001),
        );
        expect(viewModel.selectedDeckPlaces.length, 1);
        expect(viewModel.dismissedDeckPlaces.length, 1);

        // =====================================================================
        // 3. SEÇİLENLER & GEÇİLENLER KENAR LİSTESİ:
        //    Border ve sayı olmadan yalnızca birbirinin üstüne binen maks. 5 küçük mekan resim kartı
        // =====================================================================
        final selectedFirstCardFinder = find.byKey(
          const ValueKey<String>(
            'swipe-side-mini-card-selected-gb-london-big-ben',
          ),
        );
        final dismissedFirstCardFinder = find.byKey(
          const ValueKey<String>(
            'swipe-side-mini-card-dismissed-gb-london-tower-bridge',
          ),
        );
        expect(selectedFirstCardFinder, findsOneWidget);
        expect(dismissedFirstCardFinder, findsOneWidget);

        // Her iki taraftaki küçük kartlarda border olmamalı ve sayı indikatörleri bulunmamalı
        final selectedMiniDecoration = tester
            .widget<Container>(selectedFirstCardFinder)
            .decoration! as BoxDecoration;
        final dismissedMiniDecoration = tester
            .widget<Container>(dismissedFirstCardFinder)
            .decoration! as BoxDecoration;
        expect(selectedMiniDecoration.border, isNull);
        expect(dismissedMiniDecoration.border, isNull);
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-selected-count')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('swipe-deck-dismissed-count')),
          findsNothing,
        );

        // Toplam 6 seçili mekan olacak şekilde 5 mekan daha ekleyelim ->
        // Sağ kenarda yukarıdan aşağıya maksimum 5 küçük resim kartı olmalı
        for (int i = 0; i < 5; i++) {
          viewModel.swipeCurrentPlaceRight();
        }
        await tester.pumpAndSettle();

        expect(viewModel.selectedDeckPlaces.length, 6);
        final selectedMiniCardsFinder = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>)
                  .value
                  .startsWith('swipe-side-mini-card-selected-'),
        );
        expect(selectedMiniCardsFinder, findsNWidgets(5));

        // Küçük kartların yukarıdan aşağıya birbirinin üstüne binerek (overlapping) sıralandığını doğrula
        final firstMiniRect = tester.getRect(selectedMiniCardsFinder.at(0));
        final secondMiniRect = tester.getRect(selectedMiniCardsFinder.at(1));
        expect(firstMiniRect.top, lessThan(secondMiniRect.top));
        // İkinci kart, birinci kartın alt kenarından daha yukarıdan başlar (üst üste biner)
        expect(secondMiniRect.top, lessThan(firstMiniRect.bottom));
        expect(
          secondMiniRect.top - firstMiniRect.top,
          closeTo(22.0, 0.1),
        );
      },
    );
  });
}
