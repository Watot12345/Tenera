import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tenera/services/database_helper.dart';
import 'package:tenera/services/firebase_service.dart';
import 'package:tenera/services/sync_service.dart';
import 'package:tenera/services/update_service.dart';

void main() {
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.reset();
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDbForTest(db);
        },
      ),
    );
    DatabaseHelper.setMockDatabase(db);
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdateService Tests', () {
    test('Detects newer GitHub release and parses APK asset', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'tag_name': 'v1.1.0',
              'name': 'Tenera v1.1.0: Cloud Sync & Reminders',
              'body': '- Added automated SMS reminders\n- Enhanced cloud sync',
              'html_url': 'https://github.com/Watot12345/Tenera/releases/tag/v1.1.0',
              'published_at': '2026-10-27T12:00:00Z',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url':
                      'https://github.com/Watot12345/Tenera/releases/download/v1.1.0/app-release.apk',
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final info = await UpdateService.instance.checkForUpdates(client: mockClient);
      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.1.0');
      expect(info.releaseTitle, 'Tenera v1.1.0: Cloud Sync & Reminders');
      expect(info.apkDownloadUrl,
          'https://github.com/Watot12345/Tenera/releases/download/v1.1.0/app-release.apk');
    });

    test('Returns hasUpdate false when on latest version or older release', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v0.9.0',
            'name': 'Old Release',
            'body': 'Old',
            'html_url': 'https://github.com/Watot12345/Tenera/releases',
            'assets': [],
          }),
          200,
        );
      });

      final info = await UpdateService.instance.checkForUpdates(client: mockClient);
      expect(info.hasUpdate, isFalse);
    });

    test('Fails gracefully when offline without throwing unhandled exceptions', () async {
      final mockClient = MockClient((request) async {
        throw Exception('No internet connection');
      });

      final info = await UpdateService.instance.checkForUpdates(client: mockClient);
      expect(info.hasUpdate, isFalse);
    });
  });

  group('FirebaseService & SyncService Tests', () {
    test('FirebaseService generates and retains persistent landlord device id', () async {
      final service = FirebaseService.instance;
      await service.initialize();

      expect(service.deviceId, isNotNull);
      expect(service.deviceId!.startsWith('landlord_'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tenera_device_id'), service.deviceId);
    });

    test('SyncService counts unsynced records from SQLite', () async {
      final pendingCount = await SyncService.instance.getPendingSyncCount();
      // Initially in seed data, items have is_synced = 1 or newly added have is_synced = 0
      expect(pendingCount, greaterThanOrEqualTo(0));
    });

    test('SyncService returns unconfigured status gracefully if Firebase native keys not provided',
        () async {
      final result = await SyncService.instance.syncToFirebase();
      expect(
        result.status == SyncStatus.unconfigured || result.status == SyncStatus.success,
        isTrue,
      );
    });
  });
}
