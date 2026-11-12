import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
