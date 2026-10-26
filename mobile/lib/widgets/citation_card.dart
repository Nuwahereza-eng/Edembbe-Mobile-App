import 'package:flutter/material.dart';

import '../models/results.dart';

/// A law section: law name, the section as a small chip, and a short real excerpt.
/// Law names, numbers and excerpts are shown exactly as the server returned them, never translated.
class CitationCard extends StatelessWidget {
  const CitationCard({super.key, required this.citation, this.explanation});

  final Citation citation;

  /// Why this section matters here (from a document scan), in the person's language.
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.gavel, size: 20, color: scheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: Text(citation.lawName, style: theme.textTheme.titleSmall)),
              ],
            ),
            if (citation.sectionNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text('${citation.unit} ${citation.sectionNumber}'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
            if (explanation != null && explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(explanation!, style: theme.textTheme.bodyMedium),
            ],
            if (citation.excerpt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${citation.excerpt}"',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
