import 'package:flutter/material.dart';

import '../config/situations.dart';
import '../widgets/layout.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import '../widgets/ussd_card.dart';
import 'get_help_screen.dart';
import 'guided_flow_screen.dart';

class HomeSituationsScreen extends StatelessWidget {
  const HomeSituationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = windowClassOf(context) == WindowClass.compact;
    return Scaffold(
      appBar: AppBar(
        centerTitle: compact,
        title: const Text('Eddembe'),
        actions: const [AppBarActions()],
      ),
      body: PageBody(
        maxWidth: 1040,
        children: [
          Text(context.tr('What is happening?'), style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            context.tr('Choose what is closest to your situation. We will ask a few simple questions.'),
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final situation in situationOptions)
                  SizedBox(width: width, child: _SituationTile(situation: situation)),
              ],
            );
          }),
          const SizedBox(height: 24),
          const GetHelpCard(),
          const SizedBox(height: 12),
          const UssdCard(),
        ],
      ),
    );
  }
}

class _SituationTile extends StatelessWidget {
  const _SituationTile({required this.situation});

  final SituationOption situation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedFlowScreen(situation: situation))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(situation.icon),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(situation.title), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(context.tr(situation.description),
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const ExcludeSemantics(child: Icon(Icons.chevron_right)),
            ],
          ),
        ),
      ),
    );
  }
}
