import 'package:flutter/material.dart';

import '../models/results.dart';
import '../theme.dart';

/// A red flag found in a document, with the law sections it is linked to.
class RedFlagTile extends StatelessWidget {
  const RedFlagTile({super.key, required this.text, this.sections = const []});

  final String text;
  final List<RelatedSection> sections;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kRedFlag, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: kErrorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                for (final s in sections) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${s.lawName}, ${s.unit} ${s.sectionNumber}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kErrorRed),
                  ),
                  if (s.explanation.isNotEmpty) Text(s.explanation, style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
