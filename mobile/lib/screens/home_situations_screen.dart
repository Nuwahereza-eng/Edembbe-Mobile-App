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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const _BrandTitle(),
        actions: const [AppBarActions()],
      ),
      body: PageBody(
        maxWidth: 1040,
        children: [
          PageIntro(
            title: context.tr('What is happening?'),
            subtitle: context.tr("Choose what best describes your situation. We'll guide you through the next steps."),
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
                  SizedBox(width: width, child: _SituationCard(situation: situation)),
              ],
            );
          }),
          SectionTitle(context.tr('More ways to get help')),
          const GetHelpCard(),
          const SizedBox(height: 12),
          const UssdCard(),
        ],
      ),
    );
  }
}

/// The Eddembe mark and name, start-aligned in the top app bar. Wider screens already show the mark
/// at the top of the navigation rail, so there only the name is shown.
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (windowClassOf(context) == WindowClass.compact) ...[
          ExcludeSemantics(child: Icon(Icons.balance, color: theme.colorScheme.primary)),
          const SizedBox(width: 8),
        ],
        Text(
          'Eddembe',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
        ),
      ],
    );
  }
}

/// One situation: topic, title and a short description, as one whole-card button.
class _SituationCard extends StatelessWidget {
  const _SituationCard({required this.situation});

  final SituationOption situation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TappableCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedFlowScreen(situation: situation))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            LeadingTile(size: 44, child: Icon(situation.icon)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(situation.category), style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                  const SizedBox(height: 2),
                  Text(context.tr(situation.title),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(context.tr(situation.description),
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
