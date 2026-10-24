import 'package:flutter/material.dart';

class CommunityVoiceCard extends StatelessWidget {
  const CommunityVoiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final totals = [
      {'label': 'Cost', 'value': '31%'},
      {'label': 'Distance', 'value': '24%'},
      {'label': 'Fear', 'value': '18%'},
      {'label': 'Language', 'value': '12%'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Voice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('What makes it hardest for people in your community to get help?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: totals.map((item) {
                final label = item['label'] as String;
                final value = item['value'] as String;
                return Chip(label: Text('$label: $value'));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
