import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/layout.dart';
import '../widgets/mic_button.dart';
import '../widgets/tr.dart';
import 'result_screen.dart';

/// A few tap questions for one situation, one per step, then an optional note typed or spoken.
/// The answers become a plain English question for the Ask endpoint; the answer comes back in the
/// person's language.
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
  int _step = 0;

  SituationOption get _situation => widget.situation;
  bool get _freeTextOnly => _situation.steps.isEmpty;

  /// The tap questions, then one last step for the note.
  int get _stepCount => _situation.steps.length + 1;
  bool get _onNoteStep => _step == _situation.steps.length;

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

  void _next() => _onNoteStep ? _submit() : setState(() => _step++);
  void _back() => _step == 0 ? Navigator.pop(context) : setState(() => _step--);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(_situation.title)),
          bottom: _freeTextOnly
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: Semantics(
                    label: '${context.tr('Step')} ${_step + 1} / $_stepCount',
                    child: LinearProgressIndicator(value: (_step + 1) / _stepCount),
                  ),
                ),
        ),
        body: PageBody(
          maxWidth: 640,
          children: [
            const SizedBox(height: 8),
            if (!_freeTextOnly)
              Text('${context.tr('Step')} ${_step + 1} / $_stepCount',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (_onNoteStep) ..._noteStep(context) else ..._questionStep(context, _step),
            const SizedBox(height: 32),
            Row(
              children: [
                if (!_freeTextOnly)
                  TextButton.icon(onPressed: _back, icon: const Icon(Icons.arrow_back), label: Text(context.tr('Back'))),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _next,
                  icon: Icon(_onNoteStep ? Icons.gavel : Icons.arrow_forward),
                  label: Text(context.tr(_onNoteStep ? 'Check the law' : 'Next')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _questionStep(BuildContext context, int index) {
    final step = _situation.steps[index];
    return [
      Semantics(
        header: true,
        child: Text(context.tr(step.prompt), style: Theme.of(context).textTheme.headlineSmall),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in step.choices)
            ChoiceChip(
              label: Text(context.tr(choice.label)),
              selected: _answers[index] == choice,
              onSelected: (_) => setState(() => _answers[index] = choice),
            ),
        ],
      ),
    ];
  }

  List<Widget> _noteStep(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Semantics(
        header: true,
        child: Text(
          context.tr(_freeTextOnly ? 'Tell us what is happening' : 'Anything else? (optional)'),
          style: theme.textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _note,
        minLines: 3,
        maxLines: 6,
        maxLength: 1000,
        decoration: InputDecoration(hintText: context.tr('Write in your own words...')),
      ),
      if (_heard != null && _heard == _note.text)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(context.tr('We heard this. You can correct it before you continue.'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      MicButton(
        onText: (text) => setState(() {
          _heard = text;
          _note.text = text;
        }),
      ),
    ];
  }
}
