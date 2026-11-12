import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:been_here_mobile/ui/features/route_builder/view_models/route_builder_view_model.dart';
import 'package:been_here_mobile/ui/features/route_builder/views/route_builder_screen.dart';

void main() {
  testWidgets(
    'RouteBuilderScreen: Airbnb arama çubuğu, dismissible filtre çipleri ve ülke/şehir akışı testi',
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

      // 2. Stepper'ın hemen altında Airbnb tarzı arama çubuğu
      expect(find.text('Ülke veya şehir ara...'), findsOneWidget);

      // 3. Arama kutucuğunun altında aktif filtre çipleri (Varsayılan: Avrupa ve Batı Avrupa)
      expect(find.text('Avrupa'), findsOneWidget);
      expect(find.text('Batı Avrupa'), findsOneWidget);

      // 4. Aktif filtre çipine basarak filtreyi hızlıca kaldırma testi:
      // "Batı Avrupa" çipine tıklandığında alt bölge filtresi temizlenir
      await tester.tap(find.text('Batı Avrupa'));
      await tester.pumpAndSettle();

      expect(viewModel.activeSubRegionId, isNull);
      expect(find.text('Batı Avrupa'), findsNothing);

      // "Avrupa" çipine tıklandığında kıta filtresi de temizlenir (tüm dünya listelenir)
      await tester.tap(find.text('Avrupa'));
      await tester.pumpAndSettle();

      expect(viewModel.activeContinentId, isNull);
      expect(find.text('Avrupa'), findsNothing);

      // 5. Arama çubuğundaki filtre slider butonuna basarak Liquid Glass çipler panelini açma
      final filterButton = find.byTooltip('Kıta ve Bölge Filtreleri');
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Çipler panelinde kıtalar görünür olmalı
      expect(find.text('Tüm Kıtalar'), findsOneWidget);
      expect(find.text('Avrupa'), findsOneWidget);
      expect(find.text('Asya'), findsOneWidget);

      // Avrupa çipine tıklayarak Avrupa kıtasını yeniden aktif hale getirelim
      await tester.tap(find.text('Avrupa'));
      await tester.pumpAndSettle();
      expect(viewModel.activeContinentId, equals('europe'));

      // 6. Ülke Banner'ı ve Şehirler Slider'ı
      expect(find.text('İspanya'), findsOneWidget);
      expect(find.text('Sevilla'), findsOneWidget);
      expect(find.text('Cadiz'), findsOneWidget);
      expect(find.text('Madrid'), findsOneWidget);

      // 7. Şehir seçimi testi: "Sevilla" kartına tıkla
      await tester.tap(find.text('Sevilla'));
      await tester.pumpAndSettle();

      // Sevilla seçilince bağlı olduğu ülke (ES) otomatik seçilmiş olur
      expect(viewModel.selectedCityKeys.contains('ES:Sevilla'), isTrue);
      expect(viewModel.isCountrySelected('ES'), isTrue);
      expect(find.text('Sevilla Seçili'), findsOneWidget);
      expect(find.text('İspanya -> Sevilla'), findsOneWidget);

      // 8. Ülke Banner kartına tıkla -> Toggle davranışı ile İspanya ve alt şehirleri temizlenir
      await tester.tap(find.text('İspanya'));
      await tester.pumpAndSettle();

      expect(viewModel.isCountrySelected('ES'), isFalse);
      expect(viewModel.selectedCityKeys.contains('ES:Sevilla'), isFalse);

      // 9. Tekrar Ülke Banner kartına tıkla -> İspanya yeniden seçilir
      await tester.tap(find.text('İspanya'));
      await tester.pumpAndSettle();

      expect(viewModel.isCountrySelected('ES'), isTrue);
      expect(find.text('İspanya Seçili'), findsOneWidget);
    },
  );
}
