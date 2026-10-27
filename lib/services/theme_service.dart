import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const String prefKeyThemeMode = 'app_theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Initializes the stored theme preference on app startup
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(prefKeyThemeMode);
    if (modeStr == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else if (modeStr == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  /// Sets and saves the chosen ThemeMode
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyThemeMode, mode.name);
  }

  /// Returns true if currently resolving to Dark brightness
  static bool isDark(BuildContext context) {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
  }
}
