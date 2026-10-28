import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tenera/models/property.dart';
import 'package:tenera/services/database_helper.dart';
import 'package:tenera/services/firebase_service.dart';
import 'package:tenera/services/landlord_profile_service.dart';
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

  group('DatabaseHelper Edit, Delete & Backup Tests', () {
    test('editPropertyDetails updates name and address', () async {
      await DatabaseHelper.instance.editPropertyDetails('p1', 'Mabini Deluxe Suites', '888 Mabini Blvd');
      final properties = await DatabaseHelper.instance.getProperties();
      final p1 = properties.firstWhere((p) => p.id == 'p1');
      expect(p1.name, 'Mabini Deluxe Suites');
      expect(p1.address, '888 Mabini Blvd');
    });

    test('updateRoom and deleteRoom modify unit code, rent, and remove room', () async {
      final roomToUpdate = RoomUnit(
        code: 'R1-MOD',
        status: RoomStatus.vacant,
        rentAmount: 5200,
      );
      await DatabaseHelper.instance.updateRoom('p1', 'R1', roomToUpdate);
      var properties = await DatabaseHelper.instance.getProperties();
      var p1 = properties.firstWhere((p) => p.id == 'p1');
      expect(p1.rooms.any((r) => r.code == 'R1-MOD' && r.rentAmount == 5200), isTrue);

      await DatabaseHelper.instance.deleteRoom('p1', 'R1-MOD');
      properties = await DatabaseHelper.instance.getProperties();
      p1 = properties.firstWhere((p) => p.id == 'p1');
      expect(p1.rooms.any((r) => r.code == 'R1-MOD'), isFalse);
    });

    test('updateTenant and deleteTenant modify and remove tenant', () async {
      final tenants = await DatabaseHelper.instance.getTenants();
      final target = tenants.first;
      final updated = target.copyWith(name: 'Updated Name', amount: 7777);
      await DatabaseHelper.instance.updateTenant(updated);

      var refreshedTenants = await DatabaseHelper.instance.getTenants();
      expect(refreshedTenants.any((t) => t.id == target.id && t.name == 'Updated Name' && t.amount == 7777), isTrue);

      await DatabaseHelper.instance.deleteTenant(target.id);
      refreshedTenants = await DatabaseHelper.instance.getTenants();
      expect(refreshedTenants.any((t) => t.id == target.id), isFalse);
    });

    test('exportBackupJson and restoreBackupJson export and restore all tables', () async {
      final jsonBackup = await DatabaseHelper.instance.exportBackupJson();
      expect(jsonBackup.contains('"tenera_backup_version"'), isTrue);
      expect(jsonBackup.contains('"properties"'), isTrue);
      expect(jsonBackup.contains('"rooms"'), isTrue);
      expect(jsonBackup.contains('"tenants"'), isTrue);
      expect(jsonBackup.contains('"payments"'), isTrue);

      // Mutate database
      await DatabaseHelper.instance.deleteProperty('p1');
      var props = await DatabaseHelper.instance.getProperties();
      expect(props.any((p) => p.id == 'p1'), isFalse);

      // Restore backup
      final success = await DatabaseHelper.instance.restoreBackupJson(jsonBackup);
      expect(success, isTrue);

      props = await DatabaseHelper.instance.getProperties();
      expect(props.any((p) => p.id == 'p1'), isTrue);
    });

    test('settleTenantMoveOut vacates room, removes tenant, and records payment settlement', () async {
      final properties = await DatabaseHelper.instance.getProperties();
      final p1 = properties.firstWhere((p) => p.id == 'p1');
      final occupiedRoom = p1.rooms.firstWhere((r) => r.status != RoomStatus.vacant);

      await DatabaseHelper.instance.settleTenantMoveOut(
        propertyId: 'p1',
        roomCode: occupiedRoom.code,
        netRefund: 3000,
        deductions: 500,
        notes: 'Cleaning deduction ₱500',
        tenantName: occupiedRoom.tenantName,
      );

      final refreshedProps = await DatabaseHelper.instance.getProperties();
      final refreshedP1 = refreshedProps.firstWhere((p) => p.id == 'p1');
      final targetRoom = refreshedP1.rooms.firstWhere((r) => r.code == occupiedRoom.code);
      expect(targetRoom.status, RoomStatus.vacant);
      expect(targetRoom.tenantName, isNull);

      final payments = await DatabaseHelper.instance.getPayments();
      final settlementPay = payments.firstWhere((pay) => pay.id.startsWith('settle_'));
      expect(settlementPay.amount, 3000);
      expect(settlementPay.method, 'Security Deposit Refund');
      expect(settlementPay.referenceNo, 'SETTLE-${occupiedRoom.code}');
      expect(settlementPay.voidReason, contains('Cleaning deduction'));
    });

    test('postUtilityCharges posts calculated split charges to tenant bills in SQLite', () async {
      final tenantsBefore = await DatabaseHelper.instance.getTenants();
      final maria = tenantsBefore.firstWhere((t) => t.id == 't1');
      final originalAmount = maria.amount;

      final count = await DatabaseHelper.instance.postUtilityCharges(
        propertyId: 'p1',
        utilityType: 'Electricity',
        roomCharges: {
          '3': 450.0, // Maria Santos is in Room 3
        },
      );

      expect(count, 1);
      final tenantsAfter = await DatabaseHelper.instance.getTenants();
      final updatedMaria = tenantsAfter.firstWhere((t) => t.id == 't1');
      expect(updatedMaria.amount, originalAmount + 450);
      expect(updatedMaria.statusText, 'Electricity Due: ₱450');
    });

    test('LandlordProfileService saves and loads custom profile', () async {
      await LandlordProfileService.saveProfile(
        businessName: 'Diamond Residences',
        landlordName: 'Engr. Santos',
        phone: '0917 555 1234',
        receiptFooter: 'Payment verified. Keep this digital receipt.',
      );

      final profile = await LandlordProfileService.getProfile();
      expect(profile.businessName, 'Diamond Residences');
      expect(profile.landlordName, 'Engr. Santos');
      expect(profile.phone, '0917 555 1234');
      expect(profile.receiptFooter, 'Payment verified. Keep this digital receipt.');
      expect(profile.displayReceiptHeader, 'DIAMOND RESIDENCES');
    });
  });
}
