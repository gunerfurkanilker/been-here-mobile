import 'package:flutter/material.dart';

/// ColorHunt esintili Koyu Tema Paleti (Kömür Arduvaz & Adaçayı Teal)
/// Palet: #222831, #31363F, #76ABAE, #EEEEEE
class BeenHereDarkColors {
  BeenHereDarkColors._();

  /// Derin kömür-arduvaz taban arka plan (#222831)
  static const Color background = Color(0xFF222831);

  /// Kartlar & paneller için koyu gunmetal yüzey (#31363F)
  static const Color surface = Color(0xFF31363F);

  /// Yükseltilmiş yüzeyler ve kart içi konteynerlar (#3B414B)
  static const Color surfaceElevated = Color(0xFF3B414B);

  /// Adaçayı / mat teal birincil pusula & rota vurgusu (#76ABAE)
  static const Color primaryCompass = Color(0xFF76ABAE);

  /// Açık adaçayı-buzul ikincil vurgu & parlayan göstergeler (#9ECBCE)
  static const Color secondaryAmber = Color(0xFF9ECBCE);

  /// Doğrulanmış rozetler ve onaylar için adaçayı teal (#76ABAE)
  static const Color verifiedEmerald = Color(0xFF76ABAE);

  /// Gezgin ligleri ve madalyalar için açık adaçayı-gümüş vurgu (#9ECBCE)
  static const Color goldLeague = Color(0xFF9ECBCE);

  /// Birincil net gövde ve başlık metinleri (#EEEEEE)
  static const Color textPrimary = Color(0xFFEEEEEE);

  /// İkincil soluk arduvaz-gri açıklama metinleri (#A8B1BC)
  static const Color textSecondary = Color(0xFFA8B1BC);

  /// Kart kenarlıkları ve ince bölücüler (#454C58)
  static const Color borderSubtle = Color(0xFF454C58);
}

/// ColorHunt esintili Aydınlık Tema Paleti (Kuzey Çelik Mavisi & Sıcak Krem)
/// Palet: #81A6C6, #AACDDC, #F3E3D0, #D2C4B4
class BeenHereLightColors {
  BeenHereLightColors._();

  /// Sıcak krem / kum taban arka plan (#F3E3D0)
  static const Color background = Color(0xFFF3E3D0);

  /// Kartlar & paneller için hafifçe yükseltilmiş sıcak fildişi yüzey (#FAF3EA)
  static const Color surface = Color(0xFFFAF3EA);

  /// Yükseltilmiş yüzeyler ve kart içi taş rengi konteynerlar (#E7DAC9)
  static const Color surfaceElevated = Color(0xFFE7DAC9);

  /// Kuzey çelik mavisi birincil pusula & rota vurgusu (#81A6C6)
  static const Color primaryCompass = Color(0xFF81A6C6);

  /// Yumuşak gök mavisi cam vurgusu ve ikincil konteyner tonu (#AACDDC)
  static const Color softSky = Color(0xFFAACDDC);

  /// Açık yüzeylerde yüksek okunurluk için derinleştirilmiş çelik/gök vurgu (#426A8C)
  static const Color secondaryAmber = Color(0xFF426A8C);

  /// Doğrulanmış rozetler ve onaylar için derin kuzey deniz-teal tonu (#2B6675)
  static const Color verifiedEmerald = Color(0xFF2B6675);

  /// Gezgin ligleri ve madalyalar için sıcak kum-bronz vurgu (#7C5A34)
  static const Color goldLeague = Color(0xFF7C5A34);

  /// Birincil net gövde ve başlık metinleri için derin arduvaz lacivert (#1E2D3B)
  static const Color textPrimary = Color(0xFF1E2D3B);

  /// İkincil açıklama metinleri için yumuşak arduvaz-taupe (#506273)
  static const Color textSecondary = Color(0xFF506273);

  /// Kart kenarlıkları ve ince bölücüler için sıcak taupe (#D2C4B4)
  static const Color borderSubtle = Color(0xFFD2C4B4);
}

/// Uygulama Genelinde Reaktif Tema Kontrolcüsü
class BeenHereThemeController extends ChangeNotifier {
  BeenHereThemeController._();

  static final BeenHereThemeController instance = BeenHereThemeController._();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark() {
    if (_themeMode != ThemeMode.dark) {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  void setLight() {
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }
}

/// Projedeki tüm widget'ların geriye dönük tam uyumla çalışmasını sağlayan
/// ve aktif temaya göre dinamik renk dönen arayüz.
class BeenHereColors {
  BeenHereColors._();

  static Color get background => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.background
      : BeenHereLightColors.background;

  static Color get surface => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.surface
      : BeenHereLightColors.surface;

  static Color get surfaceElevated => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.surfaceElevated
      : BeenHereLightColors.surfaceElevated;

  static Color get primaryCompass => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.primaryCompass
      : BeenHereLightColors.primaryCompass;

  static Color get secondaryAmber => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.secondaryAmber
      : BeenHereLightColors.secondaryAmber;

  static Color get verifiedEmerald => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.verifiedEmerald
      : BeenHereLightColors.verifiedEmerald;

  static Color get goldLeague => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.goldLeague
      : BeenHereLightColors.goldLeague;

  static Color get textPrimary => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.textPrimary
      : BeenHereLightColors.textPrimary;

  static Color get textSecondary => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.textSecondary
      : BeenHereLightColors.textSecondary;

  static Color get borderSubtle => BeenHereThemeController.instance.isDark
      ? BeenHereDarkColors.borderSubtle
      : BeenHereLightColors.borderSubtle;
}

class BeenHereTheme {
  BeenHereTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BeenHereDarkColors.background,
      colorScheme: const ColorScheme.dark(
        primary: BeenHereDarkColors.primaryCompass,
        secondary: BeenHereDarkColors.verifiedEmerald,
        tertiary: BeenHereDarkColors.goldLeague,
        surface: BeenHereDarkColors.surface,
        surfaceContainerHighest: BeenHereDarkColors.surfaceElevated,
        onPrimary: BeenHereDarkColors.background,
        onSecondary: BeenHereDarkColors.background,
        onTertiary: BeenHereDarkColors.background,
        onSurface: BeenHereDarkColors.textPrimary,
        onSurfaceVariant: BeenHereDarkColors.textSecondary,
        outline: BeenHereDarkColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BeenHereDarkColors.background,
        foregroundColor: BeenHereDarkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BeenHereDarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: BeenHereDarkColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      dividerColor: BeenHereDarkColors.borderSubtle,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BeenHereLightColors.background,
      colorScheme: const ColorScheme.light(
        primary: BeenHereLightColors.primaryCompass,
        primaryContainer: BeenHereLightColors.softSky,
        onPrimaryContainer: BeenHereLightColors.textPrimary,
        secondary: BeenHereLightColors.verifiedEmerald,
        secondaryContainer: BeenHereLightColors.surfaceElevated,
        onSecondaryContainer: BeenHereLightColors.textPrimary,
        tertiary: BeenHereLightColors.goldLeague,
        surface: BeenHereLightColors.surface,
        surfaceContainerHighest: BeenHereLightColors.surfaceElevated,
        onPrimary: BeenHereLightColors.textPrimary,
        onSecondary: Colors.white,
        onSurface: BeenHereLightColors.textPrimary,
        onSurfaceVariant: BeenHereLightColors.textSecondary,
        outline: BeenHereLightColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BeenHereLightColors.background,
        foregroundColor: BeenHereLightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BeenHereLightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: BeenHereLightColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      dividerColor: BeenHereLightColors.borderSubtle,
    );
  }
}
