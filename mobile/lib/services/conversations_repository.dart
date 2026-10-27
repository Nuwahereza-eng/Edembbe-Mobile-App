import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/records.dart';
import 'auth_service.dart';

/// Past chats (questions, scans and their answers). With Firebase they live in Firestore at
/// users/{uid}/conversations, readable only by that person; without Firebase, on the device only.
class ConversationsRepository {
  ConversationsRepository(this.auth);

  final AuthService auth;
  static const _localKey = 'saved_conversations';

  /// A chat keeps at most this many turns, well inside Firestore's 1 MB document limit.
  static const maxTurns = 20;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('conversations');

  Future<List<SavedConversation>> list() async {
    final uid = auth.uid;
    if (uid != null) {
      final snap = await _col(uid).orderBy('updated_at', descending: true).limit(100).get();
      return snap.docs.map((d) => SavedConversation.fromJson(d.id, d.data())).toList();
    }
    return (await _readLocal())..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Saves a new chat (empty [SavedConversation.id]) or updates one. Returns its id.
  Future<String> save(SavedConversation c) async {
    final now = DateTime.now();
    final turns = c.turns.length > maxTurns ? c.turns.sublist(c.turns.length - maxTurns) : c.turns;
    final data = SavedConversation(
      id: c.id,
      title: c.title,
      isScan: c.isScan,
      situationId: c.situationId,
      turns: turns,
      updatedAt: now,
    ).toJson();
    final uid = auth.uid;
    if (uid != null) {
      final doc = c.id.isEmpty ? _col(uid).doc() : _col(uid).doc(c.id);
      await doc.set({...data, 'updated_at': Timestamp.fromDate(now)});
      return doc.id;
    }
    final all = await _readLocal();
    final id = c.id.isEmpty ? 'local_${now.microsecondsSinceEpoch}' : c.id;
    all.removeWhere((x) => x.id == id);
    all.add(SavedConversation.fromJson(id, data));
    await _writeLocal(all);
    return id;
  }

  Future<void> delete(String id) async {
    final uid = auth.uid;
    if (uid != null) return _col(uid).doc(id).delete();
    final all = await _readLocal()
      ..removeWhere((c) => c.id == id);
    await _writeLocal(all);
  }

  Future<List<SavedConversation>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map.entries
        .map((e) => SavedConversation.fromJson(e.key, Map<String, dynamic>.from(e.value as Map)))
        .toList();
  }

  Future<void> _writeLocal(List<SavedConversation> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode({for (final c in all) c.id: c.toJson()}));
  }
}
