import 'package:flutter/material.dart';

import '../config/languages.dart';
import '../services/api_client.dart';
import '../widgets/disclaimer_footer.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({
    super.key,
    required this.language,
    required this.apiClient,
    this.onLanguageChanged,
  });

  final LanguageOption language;
  final ApiClient apiClient;
  final Future<void> Function(String languageCode)? onLanguageChanged;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a question first.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await widget.apiClient.askQuestion(
        question,
        language: widget.language.code,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            language: widget.language,
            result: result,
            question: question,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get an answer: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    language: widget.language,
                    onLanguageChanged: widget.onLanguageChanged ?? (_) async {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ask about your rights',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You are asking in ${widget.language.name}.',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: 'Type your question about housing, work, land or government information...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy ? null : _ask,
                                icon: const Icon(Icons.send),
                                label: Text(_busy ? 'Checking...' : 'Ask Eddembe'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voice input is not wired yet in this scaffold.')),
                                );
                              },
                              icon: const Icon(Icons.mic_none),
                              tooltip: 'Voice input',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const DisclaimerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
