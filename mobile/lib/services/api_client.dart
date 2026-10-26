import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/records.dart';
import '../models/results.dart';
import 'auth_service.dart';

/// A plain message the person can read, from the server's `error` field or written here.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the Eddembe API. The law, Gemma and Sunbird all stay on the server; the app never holds
/// their keys. Every request carries the Firebase ID token when the person is signed in.
class ApiClient {
  ApiClient({required this.baseUrl, required this.auth});

  final String baseUrl;
  final AuthService auth;

  // Answers can take 10 to 90 seconds, and a scan longer. The server allows up to 300.
  static const _aiTimeout = Duration(seconds: 240);
  static const _shortTimeout = Duration(seconds: 45);

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await auth.idToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> _guard<T>(Future<T> Function() send) async {
    try {
      return await send();
    } on TimeoutException {
      throw ApiException('This is taking too long. Please check your connection and try again.');
    } on SocketException {
      throw ApiException('No internet connection. Please connect and try again.');
    } on http.ClientException {
      throw ApiException('Could not reach Eddembe. Please check your connection and try again.');
    }
  }

  void _check(int status, List<int> body) {
    if (status < 400) return;
    String? message;
    try {
      final decoded = jsonDecode(utf8.decode(body));
      if (decoded is Map && decoded['error'] is String) message = decoded['error'] as String;
    } catch (_) {}
    if (status == 413) message = 'This file is too large. Please take a smaller photo.';
    throw ApiException(message ?? 'Something went wrong. Please try again.');
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body, Duration timeout) {
    return _guard(() async {
      final res = await http
          .post(_uri(path), headers: await _headers(json: true), body: jsonEncode(body))
          .timeout(timeout);
      _check(res.statusCode, res.bodyBytes);
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)) as Map);
    });
  }

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> query) {
    return _guard(() async {
      final res = await http.get(_uri(path, query), headers: await _headers()).timeout(_shortTimeout);
      _check(res.statusCode, res.bodyBytes);
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)) as Map);
    });
  }

  Future<Map<String, dynamic>> _postForm(http.MultipartRequest request, Duration timeout) {
    return _guard(() async {
      request.headers.addAll(await _headers());
      final streamed = await request.send().timeout(timeout);
      final body = await streamed.stream.toBytes().timeout(timeout);
      _check(streamed.statusCode, body);
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(body)) as Map);
    });
  }

  /// POST /api/ask. [history] holds up to five earlier turns in English, for follow-up questions.
  /// [inputLanguage] is set when the question is in a different language from the answer.
  Future<AskResult> ask(
    String question, {
    required String language,
    String? inputLanguage,
    List<Map<String, String>> history = const [],
  }) async {
    final data = await _postJson('/api/ask', {
      'question': question,
      'language': language,
      if (inputLanguage != null) 'input_language': inputLanguage,
      if (history.isNotEmpty) 'history': history.length > 5 ? history.sublist(history.length - 5) : history,
    }, _aiTimeout);
    return AskResult.fromJson(data);
  }

  /// POST /api/analyze: a document with an optional typed or spoken question, read against the law.
  /// The file is sent as bytes, which works the same on a phone and in a browser.
  Future<AnalyzeResult> analyze({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String language,
    String? question,
    String? audioPath,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/analyze'))
      ..fields['language'] = language
      ..files.add(http.MultipartFile.fromBytes(
        mimeType.startsWith('image/') ? 'image' : 'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));
    if (question != null && question.trim().isNotEmpty) request.fields['question'] = question.trim();
    if (audioPath != null) request.files.add(await _audioPart(audioPath));
    return AnalyzeResult.fromJson(await _postForm(request, _aiTimeout));
  }

  /// POST /api/speech/stt. Returns what Sunbird heard.
  Future<String> transcribe(String audioPath, {required String language}) async {
    final request = http.MultipartRequest('POST', _uri('/api/speech/stt'))
      ..fields['language'] = language
      ..files.add(await _audioPart(audioPath));
    final data = await _postForm(request, _shortTimeout * 2);
    return data['text']?.toString() ?? '';
  }

  // On a phone the recording is an .m4a file; in a browser it is a WebM blob URL. XFile reads both.
  Future<http.MultipartFile> _audioPart(String path) async => http.MultipartFile.fromBytes(
        'audio',
        await XFile(path).readAsBytes(),
        contentType: kIsWeb ? MediaType('audio', 'webm') : MediaType('audio', 'mp4'),
        filename: kIsWeb ? 'question.webm' : 'question.m4a',
      );

  /// POST /api/speech/tts. Returns audio bytes (WAV).
  Future<Uint8List> speak(String text, {required String language}) {
    return _guard(() async {
      final res = await http
          .post(_uri('/api/speech/tts'),
              headers: await _headers(json: true),
              body: jsonEncode({'text': text.length > 2000 ? text.substring(0, 2000) : text, 'language': language}))
          .timeout(_shortTimeout * 2);
      _check(res.statusCode, res.bodyBytes);
      return res.bodyBytes;
    });
  }

  /// POST /api/translate. English to [target], or [source] to English when target is "eng".
  Future<List<String>> translate(List<String> texts, {required String target, String? source}) async {
    final data = await _postJson('/api/translate', {
      'texts': texts,
      'target': target,
      if (source != null) 'source': source,
    }, _shortTimeout);
    return (data['texts'] as List? ?? texts).map((e) => e.toString()).toList();
  }

  /// POST /api/letter. Returns the letter text and the sections it cites.
  Future<({String letter, List<String> citations, List<String> unverified})> letter({
    required String letterType,
    required String facts,
    required String recipient,
    required String senderName,
  }) async {
    final data = await _postJson('/api/letter', {
      'letter_type': letterType,
      'facts': facts,
      'recipient': recipient,
      'sender_name': senderName,
    }, _aiTimeout);
    final cited = (data['citations'] as List? ?? const [])
        .map((c) => Citation.fromJson(Map<String, dynamic>.from(c as Map)))
        .map((c) => '${c.lawName}, ${c.unit} ${c.sectionNumber}')
        .toList();
    return (
      letter: data['letter']?.toString() ?? '',
      citations: cited,
      unverified: (data['unverified_citations'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }

  /// GET /api/places: live Google Places results for legal aid near a point.
  Future<List<NearbyPlace>> nearbyLegalAid(double lat, double lng) async {
    final data = await _getJson('/api/places', {'lat': '$lat', 'lng': '$lng'});
    return (data['places'] as List? ?? const [])
        .map((p) => NearbyPlace.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  /// GET /api/community-voice/totals: counts per barrier, never single answers.
  Future<Map<String, int>> communityVoiceTotals() async {
    final data = await _getJson('/api/community-voice/totals', const {});
    final totals = Map<String, dynamic>.from(data['totals'] as Map? ?? const {});
    return totals.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}
