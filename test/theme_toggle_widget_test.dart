import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:been_here_mobile/main.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/widgets/glowing_live_tracker_button.dart';

void main() {
  setUp(() {
    BeenHereThemeController.instance.setDark();
  });

  tearDown(() {
    BeenHereThemeController.instance.setDark();
  });

  test('BeenHereThemeController: Reaktif tema yönetimi ve dinamik renk eşleşmesi', () {
    final controller = BeenHereThemeController.instance;

    // Başlangıç: Karanlık Tema (ColorHunt: #202734, #36415A, #B7D894, #E0F8C7)
    controller.setDark();
    expect(controller.isDark, isTrue);
    expect(controller.themeMode, ThemeMode.dark);
    expect(BeenHereColors.background, const Color(0xFF202734));
    expect(BeenHereColors.surface, const Color(0xFF36415A));
    expect(BeenHereColors.surfaceElevated, const Color(0xFF414E6B));
    expect(BeenHereColors.primaryCompass, const Color(0xFFB7D894));
    expect(BeenHereColors.verifiedEmerald, const Color(0xFFB7D894));
    expect(BeenHereColors.secondaryAmber, const Color(0xFFE0F8C7));
    expect(BeenHereColors.goldLeague, const Color(0xFFE0F8C7));
    expect(BeenHereColors.textPrimary, const Color(0xFFF1F5EE));
    expect(BeenHereColors.textSecondary, const Color(0xFFB3BED1));
    expect(BeenHereColors.borderSubtle, const Color(0xFF4B597A));
    expect(
      BeenHereTheme.darkTheme.colorScheme.onPrimary,
      BeenHereDarkColors.background,
    );
    expect(BeenHereTheme.fontFamily, 'Poppins');
    expect(
      BeenHereTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
      'Poppins',
    );

    // Tema Değişimi: Aydınlık Tema (ColorHunt: #FFFDF6, #FAF6E9, #DDEB9D, #A0C878)
    controller.toggleTheme();
    expect(controller.isDark, isFalse);
    expect(controller.themeMode, ThemeMode.light);
    expect(BeenHereColors.background, const Color(0xFFFFFDF6));
    expect(BeenHereColors.surface, const Color(0xFFFAF6E9));
    expect(BeenHereColors.surfaceElevated, const Color(0xFFF1EEDB));
    expect(BeenHereColors.primaryCompass, const Color(0xFFA0C878));
    expect(BeenHereLightColors.softSky, const Color(0xFFDDEB9D));
    expect(BeenHereColors.secondaryAmber, const Color(0xFF557C34));
    expect(BeenHereColors.verifiedEmerald, const Color(0xFF3E6B2C));
    expect(BeenHereColors.goldLeague, const Color(0xFF8C6D23));
    expect(BeenHereColors.textPrimary, const Color(0xFF1F2B1B));
    expect(BeenHereColors.textSecondary, const Color(0xFF53614C));
    expect(BeenHereColors.borderSubtle, const Color(0xFFE0DEC9));
    expect(
      BeenHereTheme.lightTheme.colorScheme.onPrimary,
      BeenHereLightColors.textPrimary,
    );
    expect(
      BeenHereTheme.lightTheme.colorScheme.primaryContainer,
      const Color(0xFFDDEB9D),
    );
    expect(
      BeenHereTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
      'Poppins',
    );

    // setDark ve setLight doğrulamaları
    controller.setDark();
    expect(controller.isDark, isTrue);
    expect(BeenHereColors.background, BeenHereDarkColors.background);

    controller.setLight();
    expect(controller.isDark, isFalse);
    expect(BeenHereColors.background, BeenHereLightColors.background);
  });

  testWidgets(
    'Topbar: Geofence yanındaki Aydınlık / Karanlık Tema Değiştirme Butonu testi',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BeenHereApp());
      await tester.pump(const Duration(milliseconds: 300));

      final controller = BeenHereThemeController.instance;
      expect(controller.isDark, isTrue);

      // Başlangıçta Koyu Tema aktif: Güneş ikonu ve Aydınlık Temaya Geç tooltip'i
      final lightToggleFinder = find.byTooltip('Aydınlık Temaya Geç');
      expect(lightToggleFinder, findsOneWidget);
      expect(find.byKey(const ValueKey('sun_icon')), findsOneWidget);
      expect(find.text('Geofence / EXIF'), findsNothing);
      expect(find.byTooltip('Geofence / EXIF'), findsOneWidget);
      expect(find.byType(GlowingLiveTrackerButton), findsOneWidget);

      // Her iki üst bar butonunun bordersız (border == null) olduğunu doğrula
      final geofenceContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GlowingLiveTrackerButton),
          matching: find.byType(Container),
        ),
      );
      expect((geofenceContainer.decoration as BoxDecoration?)?.border, isNull);

      final themeToggleContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: lightToggleFinder,
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        (themeToggleContainer.decoration as BoxDecoration?)?.border,
        isNull,
      );

      // Butona tıkla -> Aydınlık Temaya geçmeli
      await tester.tap(lightToggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.isDark, isFalse);
      expect(find.byTooltip('Karanlık Temaya Geç'), findsOneWidget);
      expect(find.byKey(const ValueKey('moon_icon')), findsOneWidget);

      // Tekrar tıkla -> Tekrar Karanlık Temaya dönmeli
      final darkToggleFinder = find.byTooltip('Karanlık Temaya Geç');
      await tester.tap(darkToggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.isDark, isTrue);
      expect(find.byTooltip('Aydınlık Temaya Geç'), findsOneWidget);
      expect(find.byKey(const ValueKey('sun_icon')), findsOneWidget);
    },
  );
}
