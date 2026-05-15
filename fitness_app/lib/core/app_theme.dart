import 'package:flutter/material.dart';

class AppColors {
  static const background  = Color(0xFF0D0D14);
  static const card        = Color(0xFF1A1A2E);
  static const cardBorder  = Color(0xFF2A2A4A);
  static const purple      = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFA855F7);
  static const text        = Color(0xFFE2E2F0);
  static const subtext     = Color(0xFF5A5A8A);
  static const subtextMid  = Color(0xFF7070A0);
  static const green       = Color(0xFF22C55E);
  static const amber       = Color(0xFFF59E0B);
  static const red         = Color(0xFFEF4444);
  static const blue        = Color(0xFF3B82F6);
  static const inputBg     = Color(0xFF13131E);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.purpleLight,
      surface: AppColors.card,
      onSurface: AppColors.text,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.text,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
      titleLarge:   TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium:  TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
      bodyMedium:   TextStyle(color: AppColors.subtextMid, fontSize: 13),
      labelSmall:   TextStyle(color: AppColors.subtext, fontSize: 11, letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.subtext, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF13131E),
      selectedItemColor: AppColors.purpleLight,
      unselectedItemColor: AppColors.subtext,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    dividerColor: AppColors.cardBorder,
    useMaterial3: true,
  );
}
