import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../config/languages.dart';
import 'api_client.dart';
import 'audio_service.dart';
import 'auth_service.dart';
import 'community_voice_service.dart';
import 'letters_repository.dart';
import 'referrals_repository.dart';
import 'support_repository.dart';

/// The chosen language and the services every screen uses.
///
/// It also translates the app's own words (button labels, guided questions) into the chosen language
/// through the server's translate endpoint, caching them on the phone. Until a translation arrives the
/// English text shows. Law names and section numbers are never passed through here.
class AppState extends ChangeNotifier {
  AppState._(this.auth)
      : api = ApiClient(baseUrl: apiBaseUrl, auth: auth),
        audio = AudioService() {
    letters = LettersRepository(auth);
    referrals = ReferralsRepository(auth);
    support = SupportRepository(auth);
    communityVoice = CommunityVoiceService(auth, api);
  }

  static const _languageKey = 'selected_language_code';
  static const _themeKey = 'theme_mode';

  final AuthService auth;
  final ApiClient api;
  final AudioService audio;
  late final LettersRepository letters;
  late final ReferralsRepository referrals;
  late final SupportRepository support;
  late final CommunityVoiceService communityVoice;

  LanguageOption? _language;
  LanguageOption? get chosenLanguage => _language;
  LanguageOption get language => _language ?? languageOptions.first;

  static Future<AppState> load() async {
    final auth = AuthService();
    await auth.init();
    final state = AppState._(auth);
    final prefs = await SharedPreferences.getInstance();
    state._language = findLanguage(prefs.getString(_languageKey));
    state._themeMode = ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ?? ThemeMode.system;
    await state._loadCache();
    return state;
  }

  Future<void> setLanguage(String code) async {
    _language = languageForCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language!.code);
    _pending.clear();
    await _loadCache();
    notifyListeners();
  }

  /// Light, dark, or follow the phone's setting (the default). Chosen in Settings.
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// Bumped when letters or referrals change, so My cases reloads.
  int casesVersion = 0;

  void casesChanged() {
    casesVersion++;
    notifyListeners();
  }

  // UI translation ---------------------------------------------------------------------------------

  Map<String, String> _cache = {};
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  Timer? _batchTimer;

  String get _cacheKey => 'ui_translations_${language.code}';

  Future<void> _loadCache() async {
    _cache = {};
    if (language.isEnglish) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) _cache = Map<String, String>.from(jsonDecode(raw) as Map);
  }

  /// [english] in the chosen language, or [english] itself while the translation loads.
  String t(String english) {
    if (language.isEnglish || english.trim().isEmpty) return english;
    final hit = _cache[english];
    if (hit != null) return hit;
    if (!_failed.contains(english) && _pending.add(english)) {
      _batchTimer ??= Timer(const Duration(milliseconds: 80), _fetchPending);
    }
    return english;
  }

  Future<void> _fetchPending() async {
    _batchTimer = null;
    final code = language.code;
    final batch = _pending.take(50).toList();
    if (batch.isEmpty) return;
    try {
      final out = await api.translate(batch, target: code);
      if (code != language.code) return;
      for (var i = 0; i < batch.length; i++) {
        _cache[batch[i]] = i < out.length && out[i].trim().isNotEmpty ? out[i] : batch[i];
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_cache));
    } catch (error) {
      // Show English for these rather than retrying on every rebuild.
      debugPrint('UI translation failed: $error');
      _failed.addAll(batch);
    } finally {
      _pending.removeAll(batch);
    }
    notifyListeners();
    if (_pending.isNotEmpty) _batchTimer ??= Timer(const Duration(milliseconds: 80), _fetchPending);
  }

  @override
  void dispose() {
    _batchTimer?.cancel();
    audio.dispose();
    super.dispose();
  }
}
