import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/layout.dart';
import '../widgets/mic_button.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'result_screen.dart';

/// Example questions, one for each area the laws cover: a short chip label and the question it fills in.
/// They only fill in the box; the answer comes from the server like any other question.
const List<(String, String)> _suggestions = [
  ('Given 7 days to leave', 'My landlord gave me 7 days to leave. Is that allowed?'),
  ('Not paid at work', 'My employer has not paid me for two months. What can I do?'),
  ('Someone claims my land', 'Someone says the land I live on is theirs. What are my rights?'),
  ('Ask government for a document', 'How do I ask a government office for a public document?'),
];

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _controller = TextEditingController();
  String? _heard;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final app = context.read<AppState>();
    final question = _controller.text.trim();
    if (question.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t('Please type or say your question first.'))));
      return;
    }
    final heard = _heard == question ? _heard : null;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          firstRequest: () async =>
              Turn.ask(question: question, ask: await app.api.ask(question, language: app.language.code), heard: heard),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = context.watch<AppState>().language;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ask')), actions: const [AppBarActions()]),
      body: PageBody(
        maxWidth: 720,
        children: [
          Text(context.tr('Ask about your rights'), style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${context.tr('Housing, work, land, or information from government.')} (${language.name})',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 10,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: context.tr('Your question'),
              hintText: context.tr('Write your question in your own words...'),
              alignLabelWithHint: true,
            ),
          ),
          if (_heard != null && _heard == _controller.text)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(context.tr('We heard this. You can correct it before you ask.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          MicButton(
            onText: (text) => setState(() {
              _heard = text;
              _controller.text = text;
            }),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(onPressed: _ask, icon: const Icon(Icons.send), label: Text(context.tr('Ask Eddembe'))),
          ),
          SectionTitle(context.tr('Try one of these')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, question) in _suggestions)
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline),
                  label: Text(context.tr(label)),
                  onPressed: () => setState(() {
                    _heard = null;
                    _controller.text = context.read<AppState>().t(question);
                  }),
                ),
            ],
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
