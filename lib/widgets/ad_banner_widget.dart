import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../screens/subscription_plans_screen.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// Renders a Google AdMob Banner Ad for Starter (free) plan users.
/// Completely hidden and zero-height for Pro & Business (Ad-Free) users.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    AdService.isAdFreeNotifier.addListener(_onAdFreeChanged);
    _checkAndLoadAd();
  }

  @override
  void dispose() {
    AdService.isAdFreeNotifier.removeListener(_onAdFreeChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onAdFreeChanged() {
    if (AdService.isAdFreeNotifier.value) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
      }
    } else {
      _checkAndLoadAd();
    }
  }

  void _checkAndLoadAd() {
    if (AdService.isAdFreeNotifier.value || !AdService.isSupportedPlatform) {
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdBannerWidget failed to load: ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.isAdFreeNotifier,
      builder: (context, isAdFree, _) {
        // If user has Pro or Business, absolutely NO ads are rendered or loaded.
        if (isAdFree || !AdService.isSupportedPlatform || !_isAdLoaded || _bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          key: const Key('ad_banner_container'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle bar with Ad label and Upgrade to remove ads hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPlansScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 12, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Remove ads with Pro',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // The Google AdMob Native Platform Ad
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ],
          ),
        );
      },
    );
  }
}
