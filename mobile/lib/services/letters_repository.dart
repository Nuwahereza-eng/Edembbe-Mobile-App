import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/records.dart';
import 'auth_service.dart';

/// Saved letters. With Firebase they live in Firestore at users/{uid}/letters and sync across sign-ins
/// on this phone; without Firebase they are kept on the phone only.
class LettersRepository {
  LettersRepository(this.auth);

  final AuthService auth;
  static const _localKey = 'saved_letters';

  bool get syncs => auth.uid != null;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('letters');

  Future<List<SavedLetter>> list() async {
    final uid = auth.uid;
    if (uid != null) {
      final snap = await _col(uid).orderBy('updated_at', descending: true).get();
      return snap.docs.map((d) => SavedLetter.fromJson(d.id, d.data())).toList();
    }
    final local = await _readLocal();
    return local..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Saves a new letter (empty [SavedLetter.id]) or updates one. Returns the saved letter.
  Future<SavedLetter> save(SavedLetter letter) async {
    final now = DateTime.now();
    final uid = auth.uid;
    if (uid != null) {
      final doc = letter.id.isEmpty ? _col(uid).doc() : _col(uid).doc(letter.id);
      await doc.set({...letter.toJson(), 'updated_at': Timestamp.fromDate(now)});
      return SavedLetter.fromJson(doc.id, {...letter.toJson(), 'updated_at': now.toIso8601String()});
    }
    final all = await _readLocal();
    final saved = SavedLetter.fromJson(
      letter.id.isEmpty ? 'local_${now.microsecondsSinceEpoch}' : letter.id,
      {...letter.toJson(), 'updated_at': now.toIso8601String()},
    );
    all.removeWhere((l) => l.id == saved.id);
    all.add(saved);
    await _writeLocal(all);
    return saved;
  }

  Future<void> delete(String id) async {
    final uid = auth.uid;
    if (uid != null) return _col(uid).doc(id).delete();
    final all = await _readLocal()
      ..removeWhere((l) => l.id == id);
    await _writeLocal(all);
  }

  Future<List<SavedLetter>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map.entries.map((e) => SavedLetter.fromJson(e.key, Map<String, dynamic>.from(e.value as Map))).toList();
  }

  Future<void> _writeLocal(List<SavedLetter> letters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode({for (final l in letters) l.id: l.toJson()}));
  }
}
