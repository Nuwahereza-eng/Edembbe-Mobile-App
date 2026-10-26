import 'package:flutter/material.dart';

import '../models/results.dart';

/// A red flag found in a document, on the error container, with the law sections it is linked to.
class RedFlagTile extends StatelessWidget {
  const RedFlagTile({super.key, required this.text, this.sections = const []});

  final String text;
  final List<RelatedSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onErrorContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: on, semanticLabel: 'Red flag'),
          textColor: on,
          title: Text(text),
          subtitle: sections.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in sections) ...[
                      const SizedBox(height: 8),
                      Text('${s.lawName}, ${s.unit} ${s.sectionNumber}',
                          style: theme.textTheme.labelLarge?.copyWith(color: on)),
                      if (s.explanation.isNotEmpty) Text(s.explanation, style: theme.textTheme.bodyMedium?.copyWith(color: on)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Something a document like this normally has but this one does not.
class MissingItemTile extends StatelessWidget {
  const MissingItemTile({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.tertiary, semanticLabel: 'Missing'),
      title: Text(text),
    );
  }
}
