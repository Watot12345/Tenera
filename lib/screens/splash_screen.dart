import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';
import 'home_screen.dart';
import 'privacy_policy_screen.dart';
import 'trial_expired_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _buildController;
  late Animation<double> _buildAnimation;

  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  Timer? _failSafeTimer;
  bool _hasNavigated = false;
  String _loadingStatus = 'Starting Tenera...';

  @override
  void initState() {
    super.initState();

    // 1. Logo stroke building animation (1.6s)
    _buildController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _buildAnimation = CurvedAnimation(
      parent: _buildController,
      curve: Curves.easeInOutCubic,
    );

    // 2. Text fade and slide in as logo finishes building (600ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 3. Absolute fail-safe: Ensure the screen NEVER gets stuck
    _failSafeTimer = Timer(const Duration(milliseconds: 3800), () {
      _navigateTo(const PrivacyPolicyScreen());
    });

    _startAppSequence();
  }

  void _navigateTo(Widget destination) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _failSafeTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _startAppSequence() async {
    // Start building the logo
    _buildController.forward();

    // Trigger text entrance around 70% of logo build
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || _hasNavigated) return;
    _textController.forward();

    // Safely check SharedPreferences with timeout & fallback
    bool hasAcceptedPrivacy = false;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 1500),
      );
      hasAcceptedPrivacy =
          prefs.getBool(PrivacyPolicyScreen.prefKeyAccepted) ?? false;
    } catch (e) {
      debugPrint('SharedPreferences read fallback: $e');
      hasAcceptedPrivacy = false;
    }

    if (!mounted || _hasNavigated) return;
    setState(() {
      _loadingStatus = hasAcceptedPrivacy
          ? 'Loading offline ledger...'
          : 'First-time setup...';
    });

    // Short pause to appreciate the completed logo
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _hasNavigated) return;

    setState(() {
      _loadingStatus = 'Ready';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _hasNavigated) return;

    // Check whether the 14-day free trial has expired without a paid subscription
    final isTrialExpired = await TrialService.isTrialExpired();

    // Navigate to destination
    final Widget destination;
    if (!hasAcceptedPrivacy) {
      destination = const PrivacyPolicyScreen();
    } else if (isTrialExpired) {
      destination = const TrialExpiredScreen();
    } else {
      destination = const HomeScreen();
    }

    _navigateTo(destination);
  }

  @override
  void dispose() {
    _failSafeTimer?.cancel();
    _buildController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Animated Logo Building Container
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDeep.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _buildAnimation,
                  builder: (context, child) {
                    return RoofLedgerLogo(
                      size: 104,
                      isLight: true,
                      progress: _buildAnimation.value,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Animated Brand Typography & Tagline
            FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Tenera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tenant management, online or offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Loading indicator & status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _loadingStatus,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
