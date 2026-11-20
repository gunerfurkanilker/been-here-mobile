import 'package:flutter/material.dart';

/// ColorHunt esintili Koyu Tema Paleti (Gece Laciverti & Mint Adaçayı)
/// Palet: #202734, #36415A, #B7D894, #E0F8C7
class BeenHereDarkColors {
  BeenHereDarkColors._();

  /// Derin gece laciverti taban arka plan (#202734)
  static const Color background = Color(0xFF202734);

  /// Kartlar, arama çubukları & paneller için indigo-arduvaz yüzey (#36415A)
  static const Color surface = Color(0xFF36415A);

  /// Yükseltilmiş yüzeyler ve etiket/buton konteynerları (#414E6B)
  static const Color surfaceElevated = Color(0xFF414E6B);

  /// Adaçayı / fıstık yeşili birincil pusula & rota vurgusu (#B7D894)
  static const Color primaryCompass = Color(0xFFB7D894);

  /// Açık mint parıltısı ikincil vurgu & parlayan göstergeler (#E0F8C7)
  static const Color secondaryAmber = Color(0xFFE0F8C7);

  /// Doğrulanmış rozetler ve yeşil bayraklar için adaçayı/fıstık yeşili (#B7D894)
  static const Color verifiedEmerald = Color(0xFFB7D894);

  /// Puanlama yıldızı, gezgin ligleri ve madalyalar için açık mint vurgu (#E0F8C7)
  static const Color goldLeague = Color(0xFFE0F8C7);

  /// Gece laciverti yüzeylerde uzun okumalarda göz yormayan net açık kırık beyaz (#F1F5EE)
  static const Color textPrimary = Color(0xFFF1F5EE);

  /// Soğuk indigo-arduvazla uyumlu ikincil açıklama metinleri (#B3BED1)
  static const Color textSecondary = Color(0xFFB3BED1);

  /// Kart kenarlıkları ve ince bölücüler (#4B597A)
  static const Color borderSubtle = Color(0xFF4B597A);
}

/// ColorHunt esintili Aydınlık Tema Paleti (Fildişi Krem & Botanik Adaçayı)
/// Palet: #FFFDF6, #FAF6E9, #DDEB9D, #A0C878
class BeenHereLightColors {
  BeenHereLightColors._();

  /// Sıcak fildişi beyazı taban arka plan (#FFFDF6)
  static const Color background = Color(0xFFFFFDF6);

  /// Kartlar, arama çubukları ve modallar için sıcak krem yüzey (#FAF6E9)
  static const Color surface = Color(0xFFFAF6E9);

  /// Yükseltilmiş yüzeyler, etiket hapları ve kart içi sıcak kum-krem konteynerlar (#F1EEDB)
  static const Color surfaceElevated = Color(0xFFF1EEDB);

  /// Adaçayı / fıstık yeşili birincil pusula & rota vurgusu (#A0C878)
  static const Color primaryCompass = Color(0xFFA0C878);

  /// Açık limon-adaçayı cam vurgusu ve ikincil konteyner tonu (#DDEB9D)
  static const Color softSky = Color(0xFFDDEB9D);

  /// Açık yüzeylerde WCAG okunurluğu için derinleştirilmiş zeytin/adaçayı vurgu (#557C34)
  static const Color secondaryAmber = Color(0xFF557C34);

  /// Doğrulanmış rozetler ve yeşil bayraklar için yüksek kontrastlı botanik yeşil (#3E6B2C)
  static const Color verifiedEmerald = Color(0xFF3E6B2C);

  /// Puanlama yıldızı, gezgin ligleri ve madalyalar için sıcak bal-bronz altın tonu (#8C6D23)
  static const Color goldLeague = Color(0xFF8C6D23);

  /// Birincil net gövde ve başlık metinleri için koyu orman-kömür (#1F2B1B)
  static const Color textPrimary = Color(0xFF1F2B1B);

  /// İkincil açıklama metinleri için yumuşak adaçayı-arduvaz (#53614C)
  static const Color textSecondary = Color(0xFF53614C);

  /// Kart kenarlıkları ve ince bölücüler için paletle uyumlu sıcak krem-taş tonu (#E0DEC9)
  static const Color borderSubtle = Color(0xFFE0DEC9);
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

  /// Uygulama genelinde kullanılan birincil font ailesi.
  static const String fontFamily = 'Poppins';

  /// Koyu tema konfigürasyonu (Gece Laciverti & Mint Adaçayı paleti:
  /// #202734, #36415A, #B7D894, #E0F8C7)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
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

  /// Aydınlık tema konfigürasyonu (Fildişi Krem & Botanik Adaçayı paleti:
  /// #FFFDF6, #FAF6E9, #DDEB9D, #A0C878)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
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
