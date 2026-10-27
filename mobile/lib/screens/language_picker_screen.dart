import 'package:flutter/material.dart';

import '../widgets/layout.dart';
import '../widgets/language_list.dart';

/// First launch: pick the language for questions and answers. Changed later from the top bar or Settings.
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LanguageList(
              // Choosing a language rebuilds the app into the main screens.
              onChosen: () {},
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.balance, size: 48, color: theme.colorScheme.primary, semanticLabel: 'Eddembe'),
                    const SizedBox(height: kGap),
                    Text('Eddembe', style: theme.textTheme.displaySmall),
                    const SizedBox(height: 4),
                    Text('Know your rights under Ugandan law.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    Text('Choose your language', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
