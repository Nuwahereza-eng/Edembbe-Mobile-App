import 'package:flutter/material.dart';

import '../config/languages.dart';
import '../widgets/citation_card.dart';
import '../widgets/disclaimer_footer.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.language,
    required this.result,
    required this.question,
  });

  final LanguageOption language;
  final Map<String, dynamic> result;
  final String question;

  @override
  Widget build(BuildContext context) {
    final answer = result['answer']?.toString() ?? 'No answer returned.';
    final citations = (result['citations'] as List?) ?? const [];
    final nextSteps = (result['next_steps'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Answer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(question),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Answer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(answer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (citations.isNotEmpty) ...[
                Text(
                  'Citations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...citations.map((citation) => CitationCard(citation: citation)),
              ],
              if (nextSteps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Next steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...nextSteps.map((item) => ListTile(
                  leading: const Icon(Icons.arrow_right),
                  title: Text(item.toString()),
                )),
              ],
              const SizedBox(height: 16),
              const DisclaimerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
