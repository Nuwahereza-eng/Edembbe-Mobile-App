import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Firebase set-up and sign-in. The demo uses anonymous sign-in: no name, phone or email is asked for.
///
/// The project settings are in firebase_options.dart (project eddembe-legal-ug). If Firebase cannot
/// start (no network on first launch, or a platform without settings), the app still works:
/// questions, scans and letters go to the API, letters are kept on the device only, and the features
/// that need Firestore (referrals, Community Voice, verified organisations) say so.
class AuthService {
  bool _available = false;

  bool get available => _available;
  String? get uid => _available ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously();
      _available = true;
    } catch (error) {
      debugPrint('Firebase is not available: $error');
      _available = false;
    }
  }

  /// A fresh Firebase ID token for the API, or null when Firebase is not set up.
  Future<String?> idToken() async {
    if (!_available) return null;
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (error) {
      debugPrint('Could not get an ID token: $error');
      return null;
    }
  }
}
