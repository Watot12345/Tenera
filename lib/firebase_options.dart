import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for project test-9a579.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8OSwyfbCjgobpiASCjgGjnjN__irRPpQ',
    appId: '1:221306847798:android:a7498b5009a5a276384e97',
    messagingSenderId: '221306847798',
    projectId: 'test-9a579',
    storageBucket: 'test-9a579.firebasestorage.app',
    databaseURL: 'https://test-9a579-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8OSwyfbCjgobpiASCjgGjnjN__irRPpQ',
    appId: '1:221306847798:android:a7498b5009a5a276384e97',
    messagingSenderId: '221306847798',
    projectId: 'test-9a579',
    storageBucket: 'test-9a579.firebasestorage.app',
    databaseURL: 'https://test-9a579-default-rtdb.firebaseio.com',
  );
}
