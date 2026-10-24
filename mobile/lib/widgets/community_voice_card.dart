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

  Future<void> _answer(String barrier) async {
    final app = context.read<AppState>();
    try {
      await app.communityVoice.submit(
        barrier: barrier,
        situation: widget.situationId,
        district: _shareDistrict ? _district.text : null,
        language: app.language.code,
      );
      setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t('Could not send. Please try again.'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Thank you. Here is what people have told us so far:'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const CommunityVoiceTotals(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(context.tr('Community Voice'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<AppState>().communityVoice.skip();
                          setState(() => _hidden = true);
                        },
                        child: Text(context.tr('Skip')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(context.tr('What makes it hardest for people in your community to get help?'),
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(context.tr('Anonymous. We only count answers; nobody sees yours.'),
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (code, label) in barriers)
                        ActionChip(
                          label: Text(context.tr(label)),
                          onPressed: () => _answer(code),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _shareDistrict,
                    onChanged: (v) => setState(() => _shareDistrict = v ?? false),
                    title: Text(context.tr('Also share my district'), style: const TextStyle(fontSize: 14)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_shareDistrict)
                    TextField(
                      controller: _district,
                      decoration: InputDecoration(
                        labelText: context.tr('District'),
                        border: const OutlineInputBorder(),
                      ),
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
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, int>>(
      future: _totals,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
        if (snap.hasError) {
          return Text(context.tr('The totals are not available right now.'), style: const TextStyle(fontSize: 14));
        }
        final totals = snap.data!;
        final sum = totals.values.fold<int>(0, (a, b) => a + b);
        final max = totals.values.fold<int>(1, (a, b) => b > a ? b : a);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (code, label) in barriers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(context.tr(label), style: const TextStyle(fontSize: 14))),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 18,
                            width: c.maxWidth * ((totals[code] ?? 0) / max),
                            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('${totals[code] ?? 0}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            Text('${context.tr('Answers so far')}: $sum', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        );
      },
    );
  }
}
