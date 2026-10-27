import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  FirebaseService.instance.initialize();
  runApp(const TeneraApp());
}

class TeneraApp extends StatelessWidget {
  const TeneraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
