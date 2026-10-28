import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'plan_guard_service.dart';

/// Centralized service for Google AdMob in Tenera.
/// - Starter plan: Ads are enabled (ad-supported free tier).
/// - Pro & Business plans: 100% Ad-Free experience (all ads disabled).
class AdService {
  AdService._();

  static bool _initialized = false;

  /// Global notifier for ad-free state.
  /// Pro and Business users = true (No ads).
  /// Starter users = false (Ads enabled).
  static final ValueNotifier<bool> isAdFreeNotifier = ValueNotifier<bool>(false);

  /// Check whether the current platform supports Google Mobile Ads and is not running in widget tests.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Official Google AdMob Test Banner Unit IDs.
  /// Replace these with your live AdMob Banner Unit IDs before publishing to production.
  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Google Android Banner Test Ad Unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Google iOS Banner Test Ad Unit ID
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// Initializes the Google Mobile Ads SDK safely on supported mobile platforms.
  static Future<void> initialize() async {
    await refreshAdStatus();
    if (!isSupportedPlatform || _initialized) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdService.initialize error: $e');
    }
  }

  /// Refreshes the ad-free state from the current subscription plan.
  static Future<void> refreshAdStatus() async {
    final adFree = await PlanGuardService.isAdFree();
    isAdFreeNotifier.value = adFree;
  }
}
