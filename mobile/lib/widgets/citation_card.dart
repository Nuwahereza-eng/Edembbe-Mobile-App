import 'package:flutter/material.dart';

import '../models/results.dart';

/// A law section: law name in bold, section number as a chip, short real excerpt.
/// Law names, numbers and excerpts are shown exactly as the server returned them, never translated.
class CitationCard extends StatelessWidget {
  const CitationCard({super.key, required this.citation, this.explanation});

  final Citation citation;

  /// Why this section matters here (from a document scan), in the person's language.
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(citation.lawName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                if (citation.sectionNumber.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${citation.unit} ${citation.sectionNumber}'),
                    labelStyle: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                    backgroundColor: scheme.primaryContainer,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (explanation != null && explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(explanation!, style: const TextStyle(fontSize: 15)),
            ],
            if (citation.excerpt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.primary, width: 3))),
                child: Text(
                  '"${citation.excerpt}"',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
