import 'package:flutter/material.dart';

class BeenHereColors {
  BeenHereColors._();

  static const Color background = Color(0xFF0B1320);
  static const Color surface = Color(0xFF152238);
  static const Color surfaceElevated = Color(0xFF1E304B);
  static const Color primaryCompass = Color(0xFFFF6B4A);
  static const Color secondaryAmber = Color(0xFFF4A261);
  static const Color verifiedEmerald = Color(0xFF2A9D8F);
  static const Color goldLeague = Color(0xFFE9C46A);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderSubtle = Color(0xFF283B5B);
}

class BeenHereTheme {
  BeenHereTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BeenHereColors.background,
      colorScheme: const ColorScheme.dark(
        primary: BeenHereColors.primaryCompass,
        secondary: BeenHereColors.verifiedEmerald,
        tertiary: BeenHereColors.goldLeague,
        surface: BeenHereColors.surface,
        onPrimary: Colors.white,
        onSurface: BeenHereColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BeenHereColors.background,
        foregroundColor: BeenHereColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BeenHereColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: BeenHereColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
    );
  }
}
