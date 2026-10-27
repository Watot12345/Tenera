import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (from theme.md)
  static const Color primary = Color(0xFF0E6B63);
  static const Color primaryDeep = Color(0xFF0A4A45);
  static const Color accent = Color(0xFFF2A33A);
  static const Color ink = Color(0xFF12302D);
  static const Color inkMuted = Color(0xFF4B6662);
  static const Color background = Color(0xFFF4F7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE6E4);

  // Status Colors
  static const Color statusPaid = Color(0xFF1E7A46);
  static const Color statusPaidBg = Color(0xFFE3F4EA);
  static const Color statusDueSoon = Color(0xFF7A4F00);
  static const Color statusDueSoonBg = Color(0xFFFFF1D6);
  static const Color statusOverdue = Color(0xFFB3261E);
  static const Color statusOverdueBg = Color(0xFFFBE5E3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: ink,
        error: statusOverdue,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
