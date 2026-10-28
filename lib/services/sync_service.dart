import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tenera/services/database_helper.dart';
import 'package:tenera/services/firebase_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  unconfigured,
  error,
}

class SyncResult {
  final SyncStatus status;
  final String message;
  final int uploadedCount;
  final DateTime timestamp;

  SyncResult({
    required this.status,
    required this.message,
    required this.uploadedCount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Counts total unsynced records across SQLite tables
  Future<int> getPendingSyncCount() async {
    try {
      final db = DatabaseHelper.instance;
      final unsyncedProps = await db.getUnsynced('properties');
      final unsyncedRooms = await db.getUnsynced('rooms');
      final unsyncedTenants = await db.getUnsynced('tenants');
      final unsyncedPayments = await db.getUnsynced('payments');

      return unsyncedProps.length +
          unsyncedRooms.length +
          unsyncedTenants.length +
          unsyncedPayments.length;
    } catch (_) {
      return 0;
    }
  }

  /// Syncs unsynced SQLite records up to Firebase Realtime Database
  Future<SyncResult> syncToFirebase({http.Client? client}) async {
    final firebase = FirebaseService.instance;
    final deviceId = firebase.deviceId ?? 'default_landlord';
    final baseUrl = firebase.realtimeDatabaseUrl;

    if (baseUrl.isEmpty) {
      final pending = await getPendingSyncCount();
      return SyncResult(
        status: SyncStatus.unconfigured,
        message: 'Firebase is not yet configured. Local SQLite is active with $pending pending change${pending == 1 ? "" : "s"}.',
        uploadedCount: 0,
      );
    }

    final httpClient = client ?? http.Client();
    final bool isInternalClient = (client == null);

    try {
      final db = DatabaseHelper.instance;
      int uploaded = 0;

      // 1. Sync Properties
      final unsyncedProps = await db.getUnsynced('properties');
      for (final p in unsyncedProps) {
        final id = p['id'] as String;
        final data = Map<String, dynamic>.from(p)..remove('is_synced');
        final res = await httpClient.put(
          Uri.parse('$baseUrl/landlords/$deviceId/properties/$id.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await db.markSynced('properties', id);
          uploaded++;
        }
      }

      // 2. Sync Rooms
      final unsyncedRooms = await db.getUnsynced('rooms');
      for (final r in unsyncedRooms) {
        final id = r['id'] as String;
        final data = Map<String, dynamic>.from(r)..remove('is_synced');
        final res = await httpClient.put(
          Uri.parse('$baseUrl/landlords/$deviceId/rooms/$id.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await db.markSynced('rooms', id);
          uploaded++;
        }
      }

      // 3. Sync Tenants
      final unsyncedTenants = await db.getUnsynced('tenants');
      for (final t in unsyncedTenants) {
        final id = t['id'] as String;
        final data = Map<String, dynamic>.from(t)..remove('is_synced');
        final res = await httpClient.put(
          Uri.parse('$baseUrl/landlords/$deviceId/tenants/$id.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await db.markSynced('tenants', id);
          uploaded++;
        }
      }

      // 4. Sync Payments
      final unsyncedPayments = await db.getUnsynced('payments');
      for (final pay in unsyncedPayments) {
        final id = pay['id'] as String;
        final data = Map<String, dynamic>.from(pay)..remove('is_synced');
        final res = await httpClient.put(
          Uri.parse('$baseUrl/landlords/$deviceId/payments/$id.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await db.markSynced('payments', id);
          uploaded++;
        }
      }

      _lastSyncTime = DateTime.now();

      return SyncResult(
        status: SyncStatus.success,
        message: uploaded > 0
            ? 'Successfully synced $uploaded record${uploaded == 1 ? "" : "s"} to Firebase Realtime Database.'
            : 'All records are up to date with Firebase Realtime Database.',
        uploadedCount: uploaded,
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync error: ${e.toString()}',
        uploadedCount: 0,
      );
    } finally {
      if (isInternalClient) {
        httpClient.close();
      }
    }
  }
}
