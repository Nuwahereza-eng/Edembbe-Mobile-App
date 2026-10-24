import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/records.dart';
import 'auth_service.dart';

/// Referral requests to verified organisations, in Firestore `referrals`. Only the fields the person
/// chose to share are written. `uid` is the anonymous sign-in ID, so they can see their own requests
/// (and nobody else's, see firestore.rules).
class ReferralsRepository {
  ReferralsRepository(this.auth);

  final AuthService auth;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('referrals');

  Future<void> send({
    required SupportOrganisation organisation,
    String? situation,
    String? summary,
    String? phone,
  }) async {
    final uid = auth.uid;
    if (uid == null) throw StateError('Sign-in is not set up, so referrals cannot be sent yet.');
    await _col.add({
      'uid': uid,
      'organisation_id': organisation.id,
      'organisation_name': organisation.name,
      'status': 'sent',
      'created_at': FieldValue.serverTimestamp(),
      if (situation != null) 'situation': situation,
      if (summary != null && summary.trim().isNotEmpty) 'summary': summary.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
  }

  Future<List<Referral>> mine() async {
    final uid = auth.uid;
    if (uid == null) return [];
    final snap = await _col.where('uid', isEqualTo: uid).get();
    final list = snap.docs.map((d) => Referral.fromFirestore(d.id, d.data())).toList();
    // Sorted here rather than in the query, so no composite index is needed.
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
