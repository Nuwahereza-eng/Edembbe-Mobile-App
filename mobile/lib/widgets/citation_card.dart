import 'package:flutter/material.dart';

class CitationCard extends StatelessWidget {
  const CitationCard({super.key, required this.citation});

  final Map<String, dynamic> citation;

  @override
  Widget build(BuildContext context) {
    final lawName = citation['law_name']?.toString() ?? 'Unknown law';
    final sectionNumber = citation['section_number']?.toString() ?? '';
    final excerpt = citation['excerpt']?.toString() ?? 'No excerpt available.';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lawName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (sectionNumber.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Section $sectionNumber'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(excerpt),
          ],
        ),
      ),
    );
  }
}
