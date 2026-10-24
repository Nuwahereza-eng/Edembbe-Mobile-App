import 'package:cloud_firestore/cloud_firestore.dart';

import 'api_client.dart';
import 'auth_service.dart';

/// The anonymous Community Voice question. Each answer stores only the barrier, the situation, the
/// district if the person chose to share it, the language and the date: no user ID, name, phone or
/// free text. The app may create answers but not read them; totals come from the server.
class CommunityVoiceService {
  CommunityVoiceService(this.auth, this.api);

  final AuthService auth;
  final ApiClient api;

  /// Asked at most once per app session, answered or skipped.
  bool _done = false;

  bool get shouldAsk => auth.available && !_done;

  void skip() => _done = true;

  Future<void> submit({required String barrier, String? situation, String? district, required String language}) async {
    _done = true;
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('community_voice').add({
      'barrier': barrier,
      'situation': situation ?? 'unknown',
      if (district != null && district.trim().isNotEmpty) 'district': district.trim(),
      'language': language,
      // The day only, so an answer cannot be matched to a moment someone used the app.
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    });
  }

  Future<Map<String, int>> totals() => api.communityVoiceTotals();
}
