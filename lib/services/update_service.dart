import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tenera/theme/app_theme.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.releaseUrl,
    this.apkDownloadUrl,
    this.publishedAt,
  });

  factory AppUpdateInfo.noUpdate(String currentVersion) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseTitle: '',
      releaseNotes: '',
      releaseUrl: 'https://github.com/Watot12345/Tenera/releases',
    );
  }
}

class UpdateService {
  static const String repoOwner = 'Watot12345';
  static const String repoName = 'Tenera';
  static const String fallbackVersion = '1.0.0';

  static final UpdateService instance = UpdateService._();
  UpdateService._();

  /// Fetches the current app version from package_info_plus
  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : fallbackVersion;
    } catch (_) {
      return fallbackVersion;
    }
  }

  /// Checks GitHub Releases API for newer version tags
  Future<AppUpdateInfo> checkForUpdates({http.Client? client}) async {
    final currentVer = await getCurrentVersion();
    final httpClient = client ?? http.Client();

    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await httpClient.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Tenera-App-Updater',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return AppUpdateInfo.noUpdate(currentVer);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final latestVer = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;

      if (latestVer.isEmpty) {
        return AppUpdateInfo.noUpdate(currentVer);
      }

      final isNewer = _isVersionNewer(latestVer, currentVer);
      if (!isNewer) {
        return AppUpdateInfo.noUpdate(currentVer);
      }

      final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$repoOwner/$repoName/releases';
      final title = data['name'] as String? ?? 'Update $rawTag';
      final body = data['body'] as String? ?? 'A new release of Tenera is available with improvements and fixes.';
      final publishedStr = data['published_at'] as String?;
      final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;

      // Locate APK asset in release if available
      String? apkUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final assetName = (asset['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      return AppUpdateInfo(
        hasUpdate: true,
        currentVersion: currentVer,
        latestVersion: latestVer,
        releaseTitle: title,
        releaseNotes: body,
        releaseUrl: htmlUrl,
        apkDownloadUrl: apkUrl ?? htmlUrl,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return AppUpdateInfo.noUpdate(currentVer);
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Compares semantic versions: returns true if latest > current
  bool _isVersionNewer(String latest, String current) {
    try {
      final lParts = latest.split('.').map((p) => int.tryParse(p.split('+')[0]) ?? 0).toList();
      final cParts = current.split('.').map((p) => int.tryParse(p.split('+')[0]) ?? 0).toList();

      final maxLen = lParts.length > cParts.length ? lParts.length : cParts.length;
      for (int i = 0; i < maxLen; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Launch download URL in browser / system downloader
  Future<bool> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Checks for update and displays dialog or feedback SnackBar
  Future<void> checkAndPrompt(BuildContext context, {bool isManual = false}) async {
    final info = await checkForUpdates();

    if (!context.mounted) return;

    if (info.hasUpdate) {
      showUpdateDialog(context, info);
    } else if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryDeep,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tenera is up to date (v${info.currentVersion})',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Displays senior-friendly update prompt modal
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppTheme.primary, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Update Available',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink),
                    ),
                    Text(
                      'GitHub Release',
                      style: TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Version Transition Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Installed: v${info.currentVersion}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.inkMuted),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                      Text(
                        'Latest: v${info.latestVersion}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.statusPaid),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Release Title
                if (info.releaseTitle.isNotEmpty)
                  Text(
                    info.releaseTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink),
                  ),
                const SizedBox(height: 6),

                // Release Notes
                const Text(
                  'What\'s New:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes.isNotEmpty ? info.releaseNotes : 'Performance improvements and bug fixes.',
                      style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final targetUrl = info.apkDownloadUrl ?? info.releaseUrl;
                launchDownload(targetUrl);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download APK', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }
}
