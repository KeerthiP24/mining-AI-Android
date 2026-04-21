import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCvWt_EHDsHoL9SHWvtsxWbUzwZD4SoUIM',
    authDomain: 'mininggaurd.firebaseapp.com',
    projectId: 'mininggaurd',
    storageBucket: 'mininggaurd.firebasestorage.app',
    messagingSenderId: '728205489401',
    appId: '1:728205489401:web:48c3191166e743f6869e28',
  );

  // Add Android app in Firebase Console → Project Settings → Add app → Android
  // then replace these values with the ones from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvWt_EHDsHoL9SHWvtsxWbUzwZD4SoUIM',
    appId: '1:728205489401:android:0000000000000000000000',
    messagingSenderId: '728205489401',
    projectId: 'mininggaurd',
    storageBucket: 'mininggaurd.firebasestorage.app',
  );

  // Add iOS app in Firebase Console → Project Settings → Add app → iOS
  // then replace these values with the ones from GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvWt_EHDsHoL9SHWvtsxWbUzwZD4SoUIM',
    appId: '1:728205489401:ios:0000000000000000000000',
    messagingSenderId: '728205489401',
    projectId: 'mininggaurd',
    storageBucket: 'mininggaurd.firebasestorage.app',
    iosBundleId: 'com.miningguard.miningguard',
  );
}
