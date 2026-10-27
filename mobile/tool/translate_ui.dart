// Translates the app's own words (buttons, headings, guided questions) into the given languages and saves
// them in assets/i18n/<code>.json, which ship with the app. With them, picking a language costs no
// Sunbird requests, so Sunbird's rate limit stays free for translating answers.
//
// Usage (from mobile/):  dart run tool/translate_ui.dart lug nyn ach teo
// Optional: --api=https://...  (defaults to the live API); --list prints the strings found and stops. Only strings not yet translated are sent,
// so re-running after adding text is quick. Law text never goes through here.
import 'dart:convert';
import 'dart:io';

const defaultApi = 'https://eddembe-legal-assistant-x3nd.vercel.app';

// Sunbird allows 50 translations a minute and our API 300 requests per 10 minutes, so send
// 10 strings at a time every 15 seconds (40 a minute).
const batchSize = 10;
const pause = Duration(seconds: 15);

Future<void> main(List<String> args) async {
  final api = args.firstWhere((a) => a.startsWith('--api='), orElse: () => '--api=$defaultApi').substring(6);
  final languages = args.where((a) => !a.startsWith('--')).toList();
  if (args.contains('--list')) {
    collectStrings(Directory('lib')).forEach(stdout.writeln);
    return;
  }
  if (languages.isEmpty) {
    stderr.writeln('Usage: dart run tool/translate_ui.dart lug nyn ach teo');
    exit(64);
  }
  final strings = collectStrings(Directory('lib'));
  stdout.writeln('${strings.length} app strings found in lib/');

  for (final code in languages) {
    final file = File('assets/i18n/$code.json');
    final existing = file.existsSync()
        ? Map<String, String>.from(jsonDecode(file.readAsStringSync()) as Map)
        : <String, String>{};
    final todo = strings.where((s) => !existing.containsKey(s)).toList();
    stdout.writeln('[$code] ${todo.length} to translate');

    for (var i = 0; i < todo.length; i += batchSize) {
      final batch = todo.sublist(i, i + batchSize > todo.length ? todo.length : i + batchSize);
      try {
        final out = await translate(api, batch, code);
        for (var j = 0; j < batch.length; j++) {
          // The API returns the English text when Sunbird fails; keep only real translations.
          if (j < out.length && out[j].trim().isNotEmpty && out[j] != batch[j]) existing[batch[j]] = out[j].trim();
        }
        stdout.writeln('[$code] ${i + batch.length}/${todo.length}');
      } catch (e) {
        stderr.writeln('[$code] batch at $i failed, will retry next run: $e');
      }
      _save(file, strings, existing);
      if (i + batchSize < todo.length) await Future<void>.delayed(pause);
    }
    _save(file, strings, existing);
    stdout.writeln('[$code] saved ${existing.length} translations to ${file.path}');
  }
}

/// Keeps only strings the app still uses, sorted for clean diffs. Sunbird often ends a short label with
/// a full stop ("Check the law" -> "Kebera amateeka."), so one is dropped where the English has none.
void _save(File file, List<String> strings, Map<String, String> existing) {
  file.parent.createSync(recursive: true);
  String tidy(String en, String tr) => !en.endsWith('.') && tr.endsWith('.') && !tr.endsWith('...')
      ? tr.substring(0, tr.length - 1)
      : tr;
  final out = {
    for (final s in strings)
      if (existing[s] != null) s: tidy(s, existing[s]!),
  };
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
}

Future<List<String>> translate(String api, List<String> texts, String target) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse('$api/api/translate'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'texts': texts, 'target': target}));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}: $body');
    return (jsonDecode(body)['texts'] as List).map((e) => e.toString()).toList();
  } finally {
    client.close();
  }
}

/// Every English sentence or label written as a string literal in the app's code.
List<String> collectStrings(Directory lib) {
  final found = <String>{};
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    // Language names stay in their own spelling, and Firebase settings are not text.
    if (entity.path.endsWith('languages.dart') || entity.path.endsWith('firebase_options.dart')) continue;
    var src = entity.readAsStringSync();
    // Imports, and the English-only parts of guided questions (sent to the server, never shown).
    src = src.replaceAll(RegExp(r"^(import|export) .*$", multiLine: true), '');
    src = src.replaceAllMapped(
      RegExp(r"FlowChoice\(\s*('(?:[^'\\]|\\.)*')\s*,\s*'(?:[^'\\]|\\.)*'\s*\)"),
      (m) => 'FlowChoice(${m[1]})',
    );
    src = src.replaceAll(RegExp(r"\b(intro|ask):\s*'(?:[^'\\]|\\.)*'\s*,"), '');
    // Adjacent literals ('a' 'b') are one string in Dart.
    src = src.replaceAllMapped(RegExp(r"'((?:[^'\\]|\\.)*)'\s+'"), (m) => "'${m[1]}");
    for (final m in RegExp(r"'((?:[^'\\\n]|\\.)*)'").allMatches(src)) {
      final s = m[1]!.replaceAll(r"\'", "'");
      if (_isUiText(s)) found.add(s);
    }
  }
  return found.toList()..sort();
}

bool _isUiText(String s) {
  if (s.trim().length < 2 || !RegExp('[A-Za-z]').hasMatch(s)) return false;
  if (s.contains(r'$') || s.contains('/') || s.contains('\\') || s.contains('_')) return false; // code, paths, keys
  if (RegExp(r'^[a-z0-9.\-]+$').hasMatch(s)) return false; // codes and ids like 'eng', 'landlord'
  if (RegExp(r'^[A-Z][a-zA-Z]*$').hasMatch(s) && s.length > 24) return false;
  // Names, HTTP headers, and law names the code matches on (law names are never translated).
  if (const {
    'Eddembe',
    'Roboto',
    'API',
    'Gemma',
    'Authorization',
    'Content-Type',
    'POST',
    'Section',
    'Article',
    'Constitution',
    'Employment',
    'Landlord and Tenant',
    'Access to Information',
  }.contains(s)) {
    return false;
  }
  if (s.startsWith('Firebase ') || s.startsWith('Could not get an ID token') || s.contains('failed:')) return false;
  return true;
}
