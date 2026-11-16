import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'services/ad_service.dart';
import 'services/firebase_service.dart';
import 'services/theme_service.dart';
import 'services/trial_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Fast, safe theme load before first frame (never block runApp on slow/failing I/O)
  try {
    await ThemeService.initialize().timeout(const Duration(milliseconds: 500));
  } catch (e) {
    debugPrint('ThemeService.initialize fallback: $e');
  }

  // Render the Flutter UI immediately so Android never hangs on LaunchTheme
  runApp(const TeneraApp());

  // Initialize background services asynchronously after first frame
  unawaited(_initializeServicesInBackground());
}

Future<void> _initializeServicesInBackground() async {
  try {
    await FirebaseService.instance
        .initialize()
        .timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('FirebaseService.initialize skipped: $e');
  }

  try {
    await TrialService.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('TrialService.initialize fallback: $e');
  }

  try {
    await AdService.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('AdService.initialize skipped: $e');
  }
}

class TeneraApp extends StatelessWidget {
  const TeneraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Tenera',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
