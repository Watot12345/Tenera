import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Light)
  static const Color primary = Color(0xFF0E6B63);
  static const Color primaryDeep = Color(0xFF0A4A45);
  static const Color accent = Color(0xFFF2A33A);
  static const Color ink = Color(0xFF12302D);
  static const Color inkMuted = Color(0xFF4B6662);
  static const Color background = Color(0xFFF4F7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE6E4);

  // Status Colors (Light & Dark compatible)
  static const Color statusPaid = Color(0xFF1E7A46);
  static const Color statusPaidBg = Color(0xFFE3F4EA);
  static const Color statusDueSoon = Color(0xFF7A4F00);
  static const Color statusDueSoonBg = Color(0xFFFFF1D6);
  static const Color statusOverdue = Color(0xFFB3261E);
  static const Color statusOverdueBg = Color(0xFFFBE5E3);

  // Dark Theme Palette (Refined Slate-Emerald)
  static const Color darkBackground = Color(0xFF0E1716);
  static const Color darkSurface = Color(0xFF162422);
  static const Color darkSurfaceElevated = Color(0xFF1D312E);
  static const Color darkBorder = Color(0xFF253E3A);
  static const Color darkInk = Color(0xFFEBF4F2);
  static const Color darkInkMuted = Color(0xFF8EA9A4);
  static const Color darkPrimary = Color(0xFF1BA69A);
  static const Color darkPrimaryDeep = Color(0xFF10635C);
  static const Color darkAccent = Color(0xFFF6B557);

  // Dark Status Backgrounds
  static const Color darkStatusPaidBg = Color(0xFF133623);
  static const Color darkStatusDueSoonBg = Color(0xFF3B2D0E);
  static const Color darkStatusOverdueBg = Color(0xFF3D1714);

  /// Helper to determine if current context is resolving in Dark Mode
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Dynamic Surface Color (white in light mode, deep slate-teal in dark mode)
  static Color getSurfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  /// Dynamic Background Color
  static Color getBackgroundColor(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  /// Dynamic Primary Text Color
  static Color getInkColor(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  /// Dynamic Muted Text Color
  static Color getInkMutedColor(BuildContext context) =>
      isDark(context) ? darkInkMuted : inkMuted;

  /// Dynamic Border Color
  static Color getBorderColor(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  /// Dynamic Status Paid Badge Background
  static Color getStatusPaidBg(BuildContext context) =>
      isDark(context) ? darkStatusPaidBg : statusPaidBg;

  /// Dynamic Status Due Soon Badge Background
  static Color getStatusDueSoonBg(BuildContext context) =>
      isDark(context) ? darkStatusDueSoonBg : statusDueSoonBg;

  /// Dynamic Status Overdue Badge Background
  static Color getStatusOverdueBg(BuildContext context) =>
      isDark(context) ? darkStatusOverdueBg : statusOverdueBg;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: border,
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkAccent,
        onSecondary: Colors.black,
        error: Color(0xFFEF5350),
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkInk,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkInk,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: darkBorder,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
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
