import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../config/situations.dart';
import '../models/records.dart';
import '../services/app_state.dart';
import '../widgets/layout.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'get_help_screen.dart';
import 'letter_editor_screen.dart';
import 'result_screen.dart';

/// Saved letters and help requests (referrals) with their status.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key, required this.visible});

  /// Reloads when the tab is opened, so a letter saved elsewhere shows up.
  final bool visible;

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  Future<(List<SavedConversation>, List<SavedLetter>, List<Referral>)>? _data;
  int _seenVersion = -1;

  Future<(List<SavedConversation>, List<SavedLetter>, List<Referral>)> _load() async {
    // Called from build, where context.read is not allowed.
    final app = Provider.of<AppState>(context, listen: false);
    final results = await Future.wait([app.conversations.list(), app.letters.list(), app.referrals.mine()]);
    return (
      results[0] as List<SavedConversation>,
      results[1] as List<SavedLetter>,
      results[2] as List<Referral>,
    );
  }

  void _newLetter() => Navigator.push(context, MaterialPageRoute(builder: (_) => const LetterEditorScreen()));

  @override
  Widget build(BuildContext context) {
    final version = context.select<AppState, int>((s) => s.casesVersion);
    if (widget.visible && (_data == null || version != _seenVersion)) {
      _seenVersion = version;
      _data = _load();
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('My cases')),
          actions: const [AppBarActions()],
          bottom: TabBar(tabs: [
            Tab(text: context.tr('Chats')),
            Tab(text: context.tr('Letters')),
            Tab(text: context.tr('Help requests')),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-letter-fab',
          onPressed: _newLetter,
          icon: const Icon(Icons.add),
          label: Text(context.tr('New letter')),
        ),
        body: FutureBuilder<(List<SavedConversation>, List<SavedLetter>, List<Referral>)>(
          future: _data,
          builder: (context, snap) {
            // Nothing loads until the tab is first opened; no spinner running unseen in the background.
            if (snap.connectionState == ConnectionState.none) return const SizedBox.shrink();
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              return PageBody(children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: context.tr('We could not load your cases.'),
                  actionLabel: context.tr('Try again'),
                  onAction: () => setState(() => _data = _load()),
                ),
              ]);
            }
            final (chats, letters, referrals) = snap.data!;
            return TabBarView(
              children: [_chats(context, chats), _letters(context, letters), _referrals(context, referrals)],
            );
          },
        ),
      ),
    );
  }

  Widget _chats(BuildContext context, List<SavedConversation> chats) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _data = _load()),
      child: PageBody(
        maxWidth: 720,
        children: chats.isEmpty
            ? [
                EmptyState(
                  icon: Icons.chat_outlined,
                  message: context.tr('Your questions and scanned documents will appear here.'),
                  actionLabel: context.tr('Ask a question'),
                  onAction: () => MainShell.showTab(context, 1),
                ),
              ]
            : [
                const SizedBox(height: 8),
                for (final chat in chats)
                  Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: LeadingTile(child: Icon(chat.isScan ? Icons.document_scanner_outlined : Icons.chat_outlined)),
                      title: Text(chat.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          _day(chat.updatedAt),
                          if (chat.turns.length > 1) '${chat.turns.length} ${context.tr('answers')}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: context.tr('Delete chat'),
                        onPressed: () => _deleteChat(chat),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ResultScreen.reopen(saved: chat)),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
      ),
    );
  }

  Future<void> _deleteChat(SavedConversation chat) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(app.t('Delete this chat?')),
        content: Text(app.t('You cannot undo this.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('Keep chat'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await app.conversations.delete(chat.id);
    app.casesChanged();
    messenger.showSnackBar(SnackBar(content: Text(app.t('Chat deleted.'))));
  }

  Widget _letters(BuildContext context, List<SavedLetter> letters) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _data = _load()),
      child: PageBody(
        maxWidth: 720,
        children: letters.isEmpty
            ? [
                EmptyState(
                  icon: Icons.description_outlined,
                  message: context.tr('No saved letters yet.'),
                  actionLabel: context.tr('Write a letter'),
                  onAction: _newLetter,
                ),
              ]
            : [
                const SizedBox(height: 8),
                for (final letter in letters)
                  Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const LeadingTile(child: Icon(Icons.description_outlined)),
                      title: Text(letter.title),
                      subtitle: Text(_day(letter.updatedAt), style: theme.textTheme.bodySmall),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: context.tr('Delete letter'),
                        onPressed: () => _delete(letter),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LetterEditorScreen(saved: letter)),
                      ),
                    ),
                  ),
                const SizedBox(height: 80), // room for the New letter button
              ],
      ),
    );
  }

  Future<void> _delete(SavedLetter letter) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(app.t('Delete this letter?')),
        content: Text(app.t('You cannot undo this.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('Keep letter'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await app.letters.delete(letter.id);
    app.casesChanged();
    messenger.showSnackBar(SnackBar(content: Text(app.t('Letter deleted.'))));
  }

  Widget _referrals(BuildContext context, List<Referral> referrals) {
    final app = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _data = _load()),
      child: PageBody(
        maxWidth: 720,
        children: referrals.isEmpty
            ? [
                EmptyState(
                  icon: Icons.support_agent_outlined,
                  message: context.tr(app.auth.available
                      ? 'No help requests yet. You can send one to a verified organisation.'
                      : 'Help requests need sign-in, which is not available right now.'),
                  actionLabel: app.auth.available ? context.tr('Get help') : null,
                  onAction: app.auth.available
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GetHelpScreen()))
                      : null,
                ),
              ]
            : [
                const SizedBox(height: 8),
                for (final r in referrals)
                  Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const LeadingTile(child: Icon(Icons.support_agent_outlined)),
                      title: Text(r.organisationName),
                      subtitle: Text(
                        [
                          _day(r.createdAt),
                          if (situationById(r.situation) != null) context.tr(situationById(r.situation)!.title),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Chip(label: Text(context.tr(_statusLabel(r.status)))),
                    ),
                  ),
                const SizedBox(height: 80),
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
