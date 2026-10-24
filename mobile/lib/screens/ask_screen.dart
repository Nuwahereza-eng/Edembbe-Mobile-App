import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/results.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/mic_button.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'result_screen.dart';

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
    final language = context.watch<AppState>().language;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ask')), actions: const [SettingsAction()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(context.tr('Ask about your rights'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${context.tr('Housing, work, land, or information from government.')} (${language.name})',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: context.tr('For example: My landlord gave me 7 days to leave. Is that allowed?'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_heard != null && _heard == _controller.text)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(context.tr('We heard this. You can correct it before you ask.'),
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ),
            MicButton(
              onText: (text) => setState(() {
                _heard = text;
                _controller.text = text;
              }),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _ask, icon: const Icon(Icons.send), label: Text(context.tr('Ask Eddembe'))),
            const SizedBox(height: 20),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}
