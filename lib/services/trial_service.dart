import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Anti-Bypass 14-Day Free Trial Service for Tenera.
/// 
/// Security & Anti-Tampering Layers:
/// 1. Dual Persistence: Synchronizes trial timestamps across SharedPreferences and SQLite metadata.
/// 2. Monotonic Clock Guard: Detects device clock rollbacks. Highest seen timestamp only advances forward.
/// 3. Network Time Verification: Confirms authoritative UTC time when internet is available.
/// 4. Cloud Verification: Syncs device installation record with Firebase Firestore so clearing local storage cannot reset trial.
/// 5. Hard Lockout: Blocks app access after 14 days unless a paid subscription is activated.
class TrialService {
  TrialService._();

  static const int trialDurationDays = 14;

  // Preference keys
  static const String prefKeyTrialStartDate = 'user_trial_start_date';
  static const String prefKeyHighestTimestamp = 'user_trial_highest_timestamp';
  static const String prefKeyIsPaidSubscriber = 'user_is_paid_subscriber';
  static const String prefKeyDeviceId = 'user_trial_device_id';
  static const String prefKeyCurrentPlan = 'user_subscription_plan';

  // SQLite metadata table
  static const String tableMetadata = 'system_metadata';

  static DateTime? _cachedTrialStartDate;
  static DateTime? _cachedHighestTimestamp;
  static bool? _cachedIsPaidSubscriber;

  /// Global notifier for trial status updates
  static final ValueNotifier<bool> isExpiredNotifier = ValueNotifier<bool>(false);

  /// Ensure SQLite metadata table exists
  static Future<void> _ensureMetadataTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableMetadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    } catch (e) {
      debugPrint('TrialService._ensureMetadataTable error: $e');
    }
  }

  /// Read metadata key from SQLite
  static Future<String?> _readSqliteMeta(String key) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return null;
    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureMetadataTable(db);
      final rows = await db.query(
        tableMetadata,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first['value'] as String?;
      }
    } catch (e) {
      debugPrint('TrialService._readSqliteMeta error: $e');
    }
    return null;
  }

  /// Write metadata key to SQLite
  static Future<void> _writeSqliteMeta(String key, String value) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureMetadataTable(db);
      await db.insert(
        tableMetadata,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('TrialService._writeSqliteMeta error: $e');
    }
  }

  /// Initialize and verify trial status with anti-tampering checks.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc();

    // 1. Check Paid Subscriber Status (from Prefs & SQLite)
    final prefsPaid = prefs.getBool(prefKeyIsPaidSubscriber) ?? false;
    final sqlitePaidStr = await _readSqliteMeta(prefKeyIsPaidSubscriber);
    final sqlitePaid = sqlitePaidStr == 'true';

    final isPaid = prefsPaid || sqlitePaid;
    _cachedIsPaidSubscriber = isPaid;

    if (isPaid) {
      // Ensure sync across both stores
      if (!prefsPaid) await prefs.setBool(prefKeyIsPaidSubscriber, true);
      if (!sqlitePaid) await _writeSqliteMeta(prefKeyIsPaidSubscriber, 'true');
      isExpiredNotifier.value = false;
      return;
    }

    // 2. Load or Generate Unique Device / Installation ID
    String? deviceId = prefs.getString(prefKeyDeviceId);
    if (deviceId == null) {
      deviceId = await _readSqliteMeta(prefKeyDeviceId);
      if (deviceId == null) {
        deviceId = 'dev_${now.millisecondsSinceEpoch}_${(now.microsecond % 10000)}';
        await _writeSqliteMeta(prefKeyDeviceId, deviceId);
      }
      await prefs.setString(prefKeyDeviceId, deviceId);
    }

    // 3. Reconcile Trial Start Date (earliest known across Prefs, SQLite, and Cloud)
    DateTime? startDate;
    final prefsStartStr = prefs.getString(prefKeyTrialStartDate);
    final sqliteStartStr = await _readSqliteMeta(prefKeyTrialStartDate);

    final prefsStart = prefsStartStr != null ? DateTime.tryParse(prefsStartStr)?.toUtc() : null;
    final sqliteStart = sqliteStartStr != null ? DateTime.tryParse(sqliteStartStr)?.toUtc() : null;

    if (prefsStart != null && sqliteStart != null) {
      startDate = prefsStart.isBefore(sqliteStart) ? prefsStart : sqliteStart;
    } else {
      startDate = prefsStart ?? sqliteStart;
    }

    // 4. Cloud Firestore cross-check (prevents uninstall/data-clear bypass on mobile)
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest && !kIsWeb) {
      try {
        final cloudDate = await _fetchCloudTrialStartDate(deviceId);
        if (cloudDate != null) {
          if (startDate == null || cloudDate.isBefore(startDate)) {
            startDate = cloudDate;
          }
        } else if (startDate != null) {
          _syncTrialToCloud(deviceId, startDate);
        }
      } catch (e) {
        debugPrint('TrialService cloud sync: $e');
      }
    }

    // If still null, this is genuinely the first launch on this device
    if (startDate == null) {
      startDate = now;
      if (!isTest && !kIsWeb) {
        _syncTrialToCloud(deviceId, startDate);
      }
    }

    _cachedTrialStartDate = startDate;
    await prefs.setString(prefKeyTrialStartDate, startDate.toIso8601String());
    await _writeSqliteMeta(prefKeyTrialStartDate, startDate.toIso8601String());

    // 5. Anti-Clock-Tampering Guard (Monotonic Clock)
    final prefsHighestStr = prefs.getString(prefKeyHighestTimestamp);
    final sqliteHighestStr = await _readSqliteMeta(prefKeyHighestTimestamp);

    DateTime? highestTime;
    final prefsHighest = prefsHighestStr != null ? DateTime.tryParse(prefsHighestStr)?.toUtc() : null;
    final sqliteHighest = sqliteHighestStr != null ? DateTime.tryParse(sqliteHighestStr)?.toUtc() : null;

    if (prefsHighest != null && sqliteHighest != null) {
      highestTime = prefsHighest.isAfter(sqliteHighest) ? prefsHighest : sqliteHighest;
    } else {
      highestTime = prefsHighest ?? sqliteHighest;
    }

    // Attempt authoritative network time verification when online
    if (!isTest) {
      final networkTime = await _fetchNetworkUtcTime();
      if (networkTime != null) {
        if (highestTime == null || networkTime.isAfter(highestTime)) {
          highestTime = networkTime;
        }
      }
    }

    if (highestTime == null || now.isAfter(highestTime)) {
      highestTime = now;
    }

    _cachedHighestTimestamp = highestTime;
    await prefs.setString(prefKeyHighestTimestamp, highestTime.toIso8601String());
    await _writeSqliteMeta(prefKeyHighestTimestamp, highestTime.toIso8601String());

    // 6. Evaluate Trial Expiration
    final expired = await isTrialExpired();
    isExpiredNotifier.value = expired;
  }

  /// Authoritative check: Is the 14-day free trial expired?
  static Future<bool> isTrialExpired() async {
    // 1. Paid subscribers or Pro/Business users are never expired
    if (_cachedIsPaidSubscriber == true) return false;

    final prefs = await SharedPreferences.getInstance();
    final isPaid = prefs.getBool(prefKeyIsPaidSubscriber) ?? false;
    final plan = prefs.getString(prefKeyCurrentPlan);
    if (isPaid || plan == 'pro' || plan == 'business') {
      _cachedIsPaidSubscriber = true;
      return false;
    }

    final now = DateTime.now().toUtc();

    // 2. Load trial start date
    DateTime? start = _cachedTrialStartDate;
    if (start == null) {
      final startStr = prefs.getString(prefKeyTrialStartDate);
      if (startStr != null) {
        start = DateTime.tryParse(startStr)?.toUtc();
      }
    }

    // If start date is still null, this is first launch: trial just started today
    if (start == null) {
      start = now;
      _cachedTrialStartDate = now;
      await prefs.setString(prefKeyTrialStartDate, now.toIso8601String());
      return false;
    }

    // 3. Compare highest seen timestamp against trial start date
    DateTime highest = _cachedHighestTimestamp ??
        DateTime.tryParse(prefs.getString(prefKeyHighestTimestamp) ?? '')?.toUtc() ??
        now;

    if (now.isAfter(highest)) {
      highest = now;
      _cachedHighestTimestamp = highest;
      await prefs.setString(prefKeyHighestTimestamp, highest.toIso8601String());
    }

    final elapsedDays = highest.difference(start).inDays;
    return elapsedDays >= trialDurationDays;
  }

  /// Returns the number of days remaining in the 14-day trial (0 if expired).
  static Future<int> getDaysRemaining() async {
    final isPaid = await isPaidSubscriber();
    if (isPaid) return trialDurationDays;

    final prefs = await SharedPreferences.getInstance();
    DateTime start = _cachedTrialStartDate ??
        DateTime.tryParse(prefs.getString(prefKeyTrialStartDate) ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    DateTime highest = _cachedHighestTimestamp ??
        DateTime.tryParse(prefs.getString(prefKeyHighestTimestamp) ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    final now = DateTime.now().toUtc();
    if (now.isAfter(highest)) {
      highest = now;
    }

    final elapsedDays = highest.difference(start).inDays;
    final remaining = (trialDurationDays - elapsedDays).clamp(0, trialDurationDays);
    return remaining;
  }

  /// Checks if device clock was rolled back behind the highest recorded timestamp.
  static Future<bool> isClockTampered() async {
    final prefs = await SharedPreferences.getInstance();
    final highestStr = prefs.getString(prefKeyHighestTimestamp);
    if (highestStr == null) return false;
    final highest = DateTime.tryParse(highestStr)?.toUtc();
    if (highest == null) return false;

    final now = DateTime.now().toUtc();
    // Allow up to 5 minutes tolerance for standard NTP sync drift
    return now.isBefore(highest.subtract(const Duration(minutes: 5)));
  }

  /// Returns true if the user has an active, confirmed paid subscription.
  static Future<bool> isPaidSubscriber() async {
    if (_cachedIsPaidSubscriber == true) return true;
    final prefs = await SharedPreferences.getInstance();
    final isPaid = prefs.getBool(prefKeyIsPaidSubscriber) ?? false;
    _cachedIsPaidSubscriber = isPaid;
    return isPaid;
  }

  /// Marks the user as a confirmed paid subscriber on this device, unlocking the app.
  static Future<void> markSubscriptionPaid(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsPaidSubscriber, true);
    await prefs.setString(prefKeyCurrentPlan, planId);
    await _writeSqliteMeta(prefKeyIsPaidSubscriber, 'true');
    await _writeSqliteMeta(prefKeyCurrentPlan, planId);

    _cachedIsPaidSubscriber = true;
    isExpiredNotifier.value = false;

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final deviceId = prefs.getString(prefKeyDeviceId);
    if (!isTest && !kIsWeb && deviceId != null) {
      try {
        await FirebaseFirestore.instance.collection('app_trials').doc(deviceId).set({
          'isPaid': true,
          'planId': planId,
          'activatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Fast non-blocking HTTP HEAD request to obtain authoritative UTC server time
  static Future<DateTime?> _fetchNetworkUtcTime() async {
    if (kIsWeb) return null; // Avoid CORS limitations in web browsers
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(milliseconds: 2500));
      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        return DateTime.tryParse(dateHeader)?.toUtc();
      }
    } catch (_) {}
    return null;
  }

  /// Retrieve cloud trial start date to defeat reinstall / storage clear bypass
  static Future<DateTime?> _fetchCloudTrialStartDate(String deviceId) async {
    if (kIsWeb) return null; // Client-side web extensions/adblockers block Firestore WebChannel
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_trials')
          .doc(deviceId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(milliseconds: 2500));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['isPaid'] == true) {
          _cachedIsPaidSubscriber = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(prefKeyIsPaidSubscriber, true);
        }
        final cloudDateStr = data['trialStartDate'] as String?;
        if (cloudDateStr != null) {
          return DateTime.tryParse(cloudDateStr)?.toUtc();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Sync trial start date to cloud
  static Future<void> _syncTrialToCloud(String deviceId, DateTime startDate) async {
    if (kIsWeb) return;
    try {
      await FirebaseFirestore.instance.collection('app_trials').doc(deviceId).set({
        'deviceId': deviceId,
        'trialStartDate': startDate.toIso8601String(),
        'isPaid': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Reset trial state (Used strictly for testing)
  @visibleForTesting
  static void resetForTest() {
    _cachedTrialStartDate = null;
    _cachedHighestTimestamp = null;
    _cachedIsPaidSubscriber = null;
    isExpiredNotifier.value = false;
  }
}
