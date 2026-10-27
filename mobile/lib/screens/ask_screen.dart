import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/layout.dart';
import '../widgets/message_composer.dart';
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

/// Suggestions at the top, and a chat-style message bar (text, mic, send) at the bottom.
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
    _controller.clear();
    _heard = null;
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
    final language = context.watch<AppState>().language;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ask')), actions: const [AppBarActions()]),
      // The app shell already moves everything above the keyboard.
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: PageBody(
              children: [
                PageIntro(
                  title: context.tr('Ask about your rights'),
                  subtitle: '${context.tr('Housing, work, land, or information from government.')} (${language.name})',
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
          ),
          MessageComposer(
            controller: _controller,
            hintText: 'Type your question...',
            sendTooltip: 'Ask Eddembe',
            onSend: _ask,
            onTranscribed: (text) => _heard = text,
          ),
        ],
      ),
    );
  }
}
