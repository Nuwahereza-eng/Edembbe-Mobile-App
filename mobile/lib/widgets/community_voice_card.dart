import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'tr.dart';

/// Barrier codes and their labels. Keep the codes in step with BARRIERS in
/// server/src/routes/communityVoice.ts.
const List<(String, String)> barriers = [
  ('cost', 'Cost'),
  ('distance', 'Distance'),
  ('fear', 'Fear'),
  ('not_knowing_where', 'Not knowing where to go'),
  ('language', 'Language'),
  ('other', 'Other'),
];

/// One optional, anonymous question after an answer. Skippable, and asked at most once per session.
class CommunityVoiceCard extends StatefulWidget {
  const CommunityVoiceCard({super.key, this.situationId});

  final String? situationId;

  @override
  State<CommunityVoiceCard> createState() => _CommunityVoiceCardState();
}

class _CommunityVoiceCardState extends State<CommunityVoiceCard> {
  bool _hidden = false;
  bool _sent = false;
  bool _sending = false;
  String? _choice;
  bool _shareDistrict = false;
  final _district = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hidden = !context.read<AppState>().communityVoice.shouldAsk;
  }

  @override
  void dispose() {
    _district.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await app.communityVoice.submit(
        barrier: _choice!,
        situation: widget.situationId,
        district: _shareDistrict ? _district.text : null,
        language: app.language.code,
      );
      setState(() => _sent = true);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(app.t('Could not send. Please try again.'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Thank you. Here is what people have told us so far:'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  const CommunityVoiceTotals(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(child: Icon(Icons.groups_outlined, color: theme.colorScheme.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.tr('Community Voice'), style: theme.textTheme.titleMedium)),
                      TextButton(
                        onPressed: () {
                          context.read<AppState>().communityVoice.skip();
                          setState(() => _hidden = true);
                        },
                        child: Text(context.tr('Skip')),
                      ),
                    ],
                  ),
                  Text(context.tr('What makes it hardest for people in your community to get help?'),
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(context.tr('Anonymous. We only count answers; nobody sees yours.'),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _shareDistrict,
                    onChanged: (v) => setState(() => _shareDistrict = v ?? false),
                    title: Text(context.tr('Also share my district')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_shareDistrict)
                    TextField(controller: _district, decoration: InputDecoration(labelText: context.tr('District'))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (code, label) in barriers)
                        ChoiceChip(
                          label: Text(context.tr(label)),
                          selected: _choice == code,
                          // One tap sends the answer (tick "share my district" first if wanted).
                          onSelected: _sending
                              ? null
                              : (_) {
                                  setState(() => _choice = code);
                                  _send();
                                },
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// A simple bar chart of the totals per barrier, from the server. Only counts, never single answers.
class CommunityVoiceTotals extends StatefulWidget {
  const CommunityVoiceTotals({super.key});

  @override
  State<CommunityVoiceTotals> createState() => _CommunityVoiceTotalsState();
}

class _CommunityVoiceTotalsState extends State<CommunityVoiceTotals> {
  late Future<Map<String, int>> _totals;

  @override
  void initState() {
    super.initState();
    _totals = context.read<AppState>().communityVoice.totals();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FutureBuilder<Map<String, int>>(
      future: _totals,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
        if (snap.hasError) {
          return Text(context.tr('The totals are not available right now.'), style: theme.textTheme.bodyMedium);
        }
        final totals = snap.data!;
        final sum = totals.values.fold<int>(0, (a, b) => a + b);
        final max = totals.values.fold<int>(1, (a, b) => b > a ? b : a);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (code, label) in barriers)
              Semantics(
                label: '${context.tr(label)}: ${totals[code] ?? 0}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(context.tr(label), style: theme.textTheme.bodyMedium)),
                          Text('${totals[code] ?? 0}', style: theme.textTheme.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (totals[code] ?? 0) / max,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ),
            Text('${context.tr('Answers so far')}: $sum',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        );
      },
    );
  }
}
