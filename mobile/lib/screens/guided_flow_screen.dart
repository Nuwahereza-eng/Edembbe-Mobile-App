import 'package:flutter/material.dart';

import '../config/languages.dart';
import '../config/situations.dart';
import '../services/api_client.dart';
import 'result_screen.dart';

class GuidedFlowScreen extends StatefulWidget {
  const GuidedFlowScreen({
    super.key,
    required this.situation,
    required this.language,
    required this.apiClient,
  });

  final SituationOption situation;
  final LanguageOption language;
  final ApiClient apiClient;

  @override
  State<GuidedFlowScreen> createState() => _GuidedFlowScreenState();
}

class _GuidedFlowScreenState extends State<GuidedFlowScreen> {
  final Map<int, String> _answers = {};
  bool _busy = false;

  Future<void> _finish() async {
    final selected = widget.situation.steps
        .asMap()
        .entries
        .map((entry) {
          final answer = _answers[entry.key];
          return answer == null ? null : '${entry.value.prompt}: $answer';
        })
        .whereType<String>()
        .join(' | ');

    final question = selected.isEmpty
        ? 'Help with ${widget.situation.title}'
        : 'I need help with ${widget.situation.title}. $selected';

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
        SnackBar(content: Text('Could not reach the API: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.situation.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.situation.title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.situation.steps.length,
                  itemBuilder: (context, index) {
                    final step = widget.situation.steps[index];
                    final selected = _answers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.prompt,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: step.choices.map((choice) {
                                final chosen = selected == choice;
                                return ChoiceChip(
                                  label: Text(choice),
                                  selected: chosen,
                                  onSelected: (_) {
                                    setState(() {
                                      _answers[index] = choice;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _finish,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_busy ? 'Checking the law...' : 'Get answer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
