import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/mic_button.dart';
import '../widgets/tr.dart';
import 'result_screen.dart';

/// A few tap questions for one situation, plus an optional note typed or spoken. The answers become a
/// plain English question for the Ask endpoint; the answer comes back in the person's language.
class GuidedFlowScreen extends StatefulWidget {
  const GuidedFlowScreen({super.key, required this.situation});

  final SituationOption situation;

  @override
  State<GuidedFlowScreen> createState() => _GuidedFlowScreenState();
}

class _GuidedFlowScreenState extends State<GuidedFlowScreen> {
  final Map<int, FlowChoice> _answers = {};
  final _note = TextEditingController();
  String? _heard;

  SituationOption get _situation => widget.situation;
  bool get _freeTextOnly => _situation.steps.isEmpty;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final app = context.read<AppState>();
    final note = _note.text.trim();
    if (_freeTextOnly && note.length < 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(app.t('Please tell us what is happening, in a few words.'))));
      return;
    }

    // What the person sees as their question: their taps and note, in their language.
    final shown = [
      app.t(_situation.title),
      for (var i = 0; i < _situation.steps.length; i++)
        if (_answers[i] != null) app.t(_answers[i]!.label),
      if (note.isNotEmpty) note,
    ].join(' · ');

    Future<Turn> request() async {
      if (_freeTextOnly) {
        // "Something else" is just the person's own words, answered by the server from the law
        // (which points to legal aid when the law does not cover it).
        final result = await app.api.ask(note, language: app.language.code);
        return Turn.ask(question: note, ask: result, heard: _heard == note ? _heard : null);
      }
      final noteEnglish = note.isEmpty || app.language.isEnglish
          ? note
          : (await app.api.translate([note], target: 'eng', source: app.language.code)).first;
      final question = _situation.buildQuestion(_answers, noteEnglish: noteEnglish);
      final result = await app.api.ask(question, language: app.language.code, inputLanguage: 'eng');
      return Turn.ask(question: shown, ask: result, questionEn: question);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(firstRequest: request, situationId: _situation.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(_situation.title))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            for (var i = 0; i < _situation.steps.length; i++) ...[
              Text('${i + 1}. ${context.tr(_situation.steps[i].prompt)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _situation.steps[i].choices)
                    ChoiceChip(
                      label: Text(context.tr(choice.label)),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      selected: _answers[i] == choice,
                      onSelected: (_) => setState(() => _answers[i] = choice),
                    ),
                ],
              ),
              const SizedBox(height: 22),
            ],
            Text(
              context.tr(_freeTextOnly ? 'Tell us what is happening' : 'Anything else? (optional)'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: context.tr('Write in your own words...'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_heard != null && _heard == _note.text)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(context.tr('We heard this. You can correct it before you continue.'),
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ),
            MicButton(
              onText: (text) => setState(() {
                _heard = text;
                _note.text = text;
              }),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.gavel),
              label: Text(context.tr('Check the law')),
            ),
          ],
        ),
      ),
    );
  }
}
