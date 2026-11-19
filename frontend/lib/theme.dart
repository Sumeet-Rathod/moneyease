import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette (Calm Blue/Teal & Sage Green)
  static const Color primaryBlue = Color(0xFF0F4C81); // Classic Navy Blue
  static const Color primaryTeal = Color(0xFF028090); // Deep Calm Teal
  static const Color sageGreen = Color(0xFF00A896);   // Growth Green
  static const Color mintLight = Color(0xFFE8F5E9);   // Soft Mint Background
  static const Color warmAmber = Color(0xFFF4A261);   // Accent Highlight
  static const Color accentGold = Color(0xFFD97706);  // Accent Gold
  static const Color secondaryCoral = Color(0xFFEF4444); // Risk/Aggressive Coral
  static const Color errorRed = Color(0xFFD32F2F);

  // Card & Container Border Radius
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: sageGreen,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1E293B),
      error: errorRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primaryTeal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryTeal,
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: primaryTeal,
        overlayColor: primaryTeal.withOpacity(0.12),
        valueIndicatorColor: primaryBlue,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: const Color(0xFF14B8A6), // Brighter teal for dark mode
      onPrimary: Colors.black,
      secondary: sageGreen,
      onSecondary: Colors.black,
      surface: const Color(0xFF1E293B),
      onSurface: const Color(0xFFF1F5F9),
      error: const Color(0xFFEF4444),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        color: const Color(0xFF1E293B),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
