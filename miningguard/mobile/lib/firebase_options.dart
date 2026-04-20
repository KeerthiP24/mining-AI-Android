// PLACEHOLDER — Replace this file by running:
// flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// Prerequisites:
// 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. Install Firebase CLI: npm install -g firebase-tools
// 3. Login: firebase login
// 4. Run: flutterfire configure --project=YOUR_PROJECT_ID

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run: flutterfire configure --project=YOUR_PROJECT_ID',
        );
    }
  }

  // REPLACE ALL VALUES BELOW with output from: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'REPLACE_WITH_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );
}
