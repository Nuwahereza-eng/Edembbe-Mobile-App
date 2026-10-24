import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/records.dart';
import '../services/app_state.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'letter_editor_screen.dart';

/// Saved letters and help requests (referrals) with their status.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key, required this.visible});

  /// Reloads when the tab is opened, so a letter saved elsewhere shows up.
  final bool visible;

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  Future<(List<SavedLetter>, List<Referral>)>? _data;
  int _seenVersion = -1;

  Future<(List<SavedLetter>, List<Referral>)> _load() async {
    // Called from build, where context.read is not allowed.
    final app = Provider.of<AppState>(context, listen: false);
    final results = await Future.wait([app.letters.list(), app.referrals.mine()]);
    return (results[0] as List<SavedLetter>, results[1] as List<Referral>);
  }

  @override
  Widget build(BuildContext context) {
    final version = context.select<AppState, int>((s) => s.casesVersion);
    if (widget.visible && (_data == null || version != _seenVersion)) {
      _seenVersion = version;
      _data = _load();
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('My cases')),
          actions: const [SettingsAction()],
          bottom: TabBar(tabs: [Tab(text: context.tr('Letters')), Tab(text: context.tr('Help requests'))]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LetterEditorScreen())),
          icon: const Icon(Icons.add),
          label: Text(context.tr('New letter')),
        ),
        body: FutureBuilder<(List<SavedLetter>, List<Referral>)>(
          future: _data,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _data = _load()),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('Could not load your cases. Try again')),
                ),
              );
            }
            final (letters, referrals) = snap.data!;
            return TabBarView(children: [_letters(context, letters), _referrals(context, referrals)]);
          },
        ),
      ),
    );
  }

  Widget _empty(String text) => ListView(
        padding: const EdgeInsets.all(32),
        children: [Text(context.tr(text), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))],
      );

  Widget _letters(BuildContext context, List<SavedLetter> letters) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _data = _load()),
      child: letters.isEmpty
          ? _empty('No saved letters yet. After an answer, tap "Write a letter".')
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              children: [
                for (final letter in letters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(letter.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_day(letter.updatedAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: context.tr('Delete'),
                          onPressed: () => _delete(letter),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LetterEditorScreen(saved: letter)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _delete(SavedLetter letter) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(app.t('Delete this letter?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await app.letters.delete(letter.id);
    app.casesChanged();
  }

  Widget _referrals(BuildContext context, List<Referral> referrals) {
    final app = Provider.of<AppState>(context, listen: false);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _data = _load()),
      child: referrals.isEmpty
          ? _empty(app.auth.available
              ? 'No help requests yet. You can send one to a verified organisation from Get help.'
              : 'Help requests need sign-in, which is not set up in this version of the app.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              children: [
                for (final r in referrals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text(r.organisationName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          _day(r.createdAt),
                          if (situationById(r.situation) != null) context.tr(situationById(r.situation)!.title),
                        ].join(' · ')),
                        trailing: Chip(label: Text(context.tr(_statusLabel(r.status)))),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'seen' => 'Seen',
        'contacted' => 'Contacted',
        'closed' => 'Closed',
        _ => 'Sent',
      };

  static String _day(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
