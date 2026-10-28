import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  static const String _prefKeyDeviceId = 'tenera_device_id';
  bool _isInitialized = false;
  String? _deviceId;

  bool get isInitialized => _isInitialized;
  String? get deviceId => _deviceId;

  /// Safe initialization of Firebase with options from DefaultFirebaseOptions
  Future<bool> initialize() async {
    // 1. Ensure persistent Landlord / Device ID
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_prefKeyDeviceId);
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = 'landlord_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 10000)}';
      await prefs.setString(_prefKeyDeviceId, _deviceId!);
    }

    // 2. Safe Firebase initialization
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      return true;
    } catch (_) {
      // Firebase configuration not present or offline
      _isInitialized = false;
      return false;
    }
  }

  /// Get Firestore instance if Firebase is active
  FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }
}
