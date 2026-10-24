import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/records.dart';
import 'auth_service.dart';

/// Verified support organisations from Firestore `support_organisations`. The team fills this list
/// with organisations it has checked itself (server/scripts/import-orgs.ts); the app never adds any.
class SupportRepository {
  SupportRepository(this.auth);

  final AuthService auth;

  /// Organisations serving [situationId] first, then the rest. Empty until the team imports the list.
  Future<List<SupportOrganisation>> verified({String? situationId}) async {
    if (!auth.available) return [];
    final snap = await FirebaseFirestore.instance.collection('support_organisations').get();
    final all = snap.docs.map((d) => SupportOrganisation.fromFirestore(d.id, d.data())).toList();
    if (situationId == null) return all..sort((a, b) => a.name.compareTo(b.name));
    final serving = all.where((o) => o.situations.contains(situationId)).toList();
    final others = all.where((o) => !o.situations.contains(situationId)).toList();
    return [...serving, ...others];
  }
}
