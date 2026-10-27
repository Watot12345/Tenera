import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Syncs unsynced SQLite records up to Firestore
  Future<SyncResult> syncToFirebase() async {
    final firebase = FirebaseService.instance;
    final firestore = firebase.firestore;
    final deviceId = firebase.deviceId ?? 'default_landlord';

    if (firestore == null) {
      final pending = await getPendingSyncCount();
      return SyncResult(
        status: SyncStatus.unconfigured,
        message: 'Firebase is not yet configured. Local SQLite is active with $pending pending change${pending == 1 ? "" : "s"}.',
        uploadedCount: 0,
      );
    }

    try {
      final db = DatabaseHelper.instance;
      int uploaded = 0;

      // 1. Sync Properties
      final unsyncedProps = await db.getUnsynced('properties');
      for (final p in unsyncedProps) {
        final id = p['id'] as String;
        await firestore
            .collection('landlords')
            .doc(deviceId)
            .collection('properties')
            .doc(id)
            .set(Map<String, dynamic>.from(p)..remove('is_synced'), SetOptions(merge: true));
        await db.markSynced('properties', id);
        uploaded++;
      }

      // 2. Sync Rooms
      final unsyncedRooms = await db.getUnsynced('rooms');
      for (final r in unsyncedRooms) {
        final id = r['id'] as String;
        await firestore
            .collection('landlords')
            .doc(deviceId)
            .collection('rooms')
            .doc(id)
            .set(Map<String, dynamic>.from(r)..remove('is_synced'), SetOptions(merge: true));
        await db.markSynced('rooms', id);
        uploaded++;
      }

      // 3. Sync Tenants
      final unsyncedTenants = await db.getUnsynced('tenants');
      for (final t in unsyncedTenants) {
        final id = t['id'] as String;
        await firestore
            .collection('landlords')
            .doc(deviceId)
            .collection('tenants')
            .doc(id)
            .set(Map<String, dynamic>.from(t)..remove('is_synced'), SetOptions(merge: true));
        await db.markSynced('tenants', id);
        uploaded++;
      }

      // 4. Sync Payments
      final unsyncedPayments = await db.getUnsynced('payments');
      for (final pay in unsyncedPayments) {
        final id = pay['id'] as String;
        await firestore
            .collection('landlords')
            .doc(deviceId)
            .collection('payments')
            .doc(id)
            .set(Map<String, dynamic>.from(pay)..remove('is_synced'), SetOptions(merge: true));
        await db.markSynced('payments', id);
        uploaded++;
      }

      _lastSyncTime = DateTime.now();

      return SyncResult(
        status: SyncStatus.success,
        message: uploaded > 0
            ? 'Successfully synced $uploaded record${uploaded == 1 ? "" : "s"} to Firebase Cloud.'
            : 'All records are up to date with Firebase Cloud.',
        uploadedCount: uploaded,
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync error: ${e.toString()}',
        uploadedCount: 0,
      );
    }
  }
}
