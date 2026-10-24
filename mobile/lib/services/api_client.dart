import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> askQuestion(
    String question, {
    required String language,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'language': language}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Ask request failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> submitDocument({
    required String question,
    required String language,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/document'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'language': language,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Document request failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  Future<String> translateText(String text, {required String target}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'texts': [text],
        'target': target,
      }),
    );

    if (response.statusCode >= 400) {
      return text;
    }

    final data = jsonDecode(response.body);
    final list = data['texts'] as List? ?? [text];
    return list.first?.toString() ?? text;
  }

  static String get defaultBaseUrl => apiBaseUrl;
}
