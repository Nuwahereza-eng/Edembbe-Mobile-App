import 'package:flutter/material.dart';

import 'tr.dart';

const String disclaimerText =
    'Eddembe gives legal information, not legal advice. For advice on your case, talk to a lawyer or a legal aid clinic.';

/// Shown on every answer, every letter, and in Settings. Small, but never hidden.
class DisclaimerFooter extends StatelessWidget {
  const DisclaimerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(Icons.info_outline, size: 16, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr(disclaimerText), style: theme.textTheme.bodySmall?.copyWith(color: color))),
        ],
      ),
    );
  }
}
