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

  // Status Colors (Light)
  static const Color statusPaid = Color(0xFF1E7A46);
  static const Color statusPaidBg = Color(0xFFE3F4EA);
  static const Color statusDueSoon = Color(0xFF7A4F00);
  static const Color statusDueSoonBg = Color(0xFFFFF1D6);
  static const Color statusOverdue = Color(0xFFB3261E);
  static const Color statusOverdueBg = Color(0xFFFBE5E3);

  // Dark Theme Palette (Warm Slate-Teal — No Plain Black)
  static const Color darkBackground = Color(0xFF141E1C);        // Warm, deep slate canvas (Never plain black)
  static const Color darkSurface = Color(0xFF1D2C29);           // Elevation 1: Card & container surface
  static const Color darkSurfaceElevated = Color(0xFF243633);   // Elevation 2: Modals, dialogs, popups
  static const Color darkBorder = Color(0xFF304642);            // Clean, soft structural borders
  static const Color darkInk = Color(0xFFEDF5F3);               // Primary high-contrast readable text
  static const Color darkInkMuted = Color(0xFFA0B7B3);          // Secondary descriptive text
  static const Color darkPrimary = Color(0xFF26B3A4);           // Perfectly saturated sage-emerald accent
  static const Color darkPrimaryDeep = Color(0xFF1B4E48);       // Supporting deep teal
  static const Color darkAccent = Color(0xFFF3AF47);            // Warm golden honey accent

  // Dark Status Colors (Tuned for readability and high aesthetic contrast)
  static const Color darkStatusPaidText = Color(0xFF4ADE80);
  static const Color darkStatusPaidBg = Color(0xFF193B28);
  static const Color darkStatusDueSoonText = Color(0xFFFBBF24);
  static const Color darkStatusDueSoonBg = Color(0xFF3B2C13);
  static const Color darkStatusOverdueText = Color(0xFFF87171);
  static const Color darkStatusOverdueBg = Color(0xFF3D1C1B);

  /// Helper to determine if current context is resolving in Dark Mode
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Dynamic Surface Color (white in light mode, slate-teal in dark mode)
  static Color getSurfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  /// Dynamic Elevated Surface Color (for dialogs, sheets, popups)
  static Color getSurfaceElevatedColor(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : surface;

  /// Dynamic Canvas / Background Color
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

  /// Dynamic Primary Brand Accent
  static Color getPrimaryColor(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  /// Dynamic Hero Banner Card Color
  static Color getHeroCardColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A4741) : primary;

  /// Dynamic Status Badge Backgrounds
  static Color getStatusPaidBg(BuildContext context) =>
      isDark(context) ? darkStatusPaidBg : statusPaidBg;

  static Color getStatusDueSoonBg(BuildContext context) =>
      isDark(context) ? darkStatusDueSoonBg : statusDueSoonBg;

  static Color getStatusOverdueBg(BuildContext context) =>
      isDark(context) ? darkStatusOverdueBg : statusOverdueBg;

  /// Dynamic Status Badge Text Colors
  static Color getStatusPaidText(BuildContext context) =>
      isDark(context) ? darkStatusPaidText : statusPaid;

  static Color getStatusDueSoonText(BuildContext context) =>
      isDark(context) ? darkStatusDueSoonText : statusDueSoon;

  static Color getStatusOverdueText(BuildContext context) =>
      isDark(context) ? darkStatusOverdueText : statusOverdue;

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
        onPrimary: Color(0xFF0F2623),
        secondary: darkAccent,
        onSecondary: Color(0xFF2C1E0A),
        error: darkStatusOverdueText,
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
        backgroundColor: darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: darkBorder,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF0F2623),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
