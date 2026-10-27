// Firebase settings for the Eddembe project (eddembe-legal-ug), in the format `flutterfire configure`
// writes. These are public client identifiers, not secrets; access is controlled by firestore.rules.
// To regenerate: flutterfire configure --project=eddembe-legal-ug --platforms=android,web
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Eddembe is set up for Firebase on Android and the web only.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMuYZ-L3nBQh_l6EGtCcvD6JdREbwNgMM',
    appId: '1:1095422973598:web:e0cc9c4bd6528e2532cd8f',
    messagingSenderId: '1095422973598',
    projectId: 'eddembe-legal-ug',
    authDomain: 'eddembe-legal-ug.firebaseapp.com',
    storageBucket: 'eddembe-legal-ug.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJ5co-X3HDyTV_9BdytJ2zbdZ6v1Lggzg',
    appId: '1:1095422973598:android:e5637d0d26154c2e32cd8f',
    messagingSenderId: '1095422973598',
    projectId: 'eddembe-legal-ug',
    storageBucket: 'eddembe-legal-ug.firebasestorage.app',
  );
}
