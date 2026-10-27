import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/records.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/layout.dart';
import '../widgets/loading_panel.dart';
import '../widgets/tr.dart';

/// Letter types the server can draft (server/src/prompts/letter.ts).
const Map<String, String> letterTypes = {
  'landlord_reply': 'Reply to a landlord',
  'employer_complaint': 'Complaint to an employer',
  'access_to_information': 'Access to Information request',
};

/// Drafts a letter with the server (from the law, with its citation check), then lets the person edit,
/// copy, share and save it. Opening a saved letter goes straight to the editor.
class LetterEditorScreen extends StatefulWidget {
  const LetterEditorScreen({super.key, this.letterType, this.facts, this.saved});

  final String? letterType;
  final String? facts;
  final SavedLetter? saved;

  @override
  State<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends State<LetterEditorScreen> {
  final _facts = TextEditingController();
  final _recipient = TextEditingController();
  final _sender = TextEditingController();
  final _letter = TextEditingController();
  late String _type;
  SavedLetter? _saved;
  List<String> _citations = [];
  List<String> _unverified = [];
  bool _drafting = false;
  bool _saving = false;
  String? _error;

  bool get _hasLetter => _letter.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _saved = widget.saved;
    _type = widget.saved?.letterType ?? widget.letterType ?? letterTypes.keys.first;
    if (!letterTypes.containsKey(_type)) _type = letterTypes.keys.first;
    _facts.text = widget.facts ?? '';
    _letter.text = widget.saved?.content ?? '';
    _citations = widget.saved?.citations ?? [];
  }

  @override
  void dispose() {
    for (final c in [_facts, _recipient, _sender, _letter]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _draft() async {
    final app = context.read<AppState>();
    if (_facts.text.trim().length < 10 || _recipient.text.trim().length < 2 || _sender.text.trim().length < 2) {
      setState(() => _error = 'Please fill in every field. Describe what happened in a few sentences.');
      return;
    }
    setState(() {
      _drafting = true;
      _error = null;
    });
    try {
      final result = await app.api.letter(
        letterType: _type,
        facts: _facts.text.trim(),
        recipient: _recipient.text.trim(),
        senderName: _sender.text.trim(),
      );
      setState(() {
        _letter.text = result.letter;
        _citations = result.citations;
        _unverified = result.unverified;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      _saved = await app.letters.save(SavedLetter(
        id: _saved?.id ?? '',
        letterType: _type,
        title: _saved?.title ?? '${letterTypes[_type]} · ${_recipient.text.trim()}'.trim(),
        content: _letter.text,
        updatedAt: DateTime.now(),
        citations: _citations,
      ));
      app.casesChanged();
      messenger.showSnackBar(SnackBar(
        content: Text(app.t(app.letters.syncs ? 'Saved to My cases' : 'Saved on this device, in My cases')),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(app.t('Could not save. Please try again.'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(_hasLetter ? 'Your letter' : 'Write a letter'))),
      body: PageBody(maxWidth: 720, children: _hasLetter ? _editor(context) : _form(context)),
    );
  }

  List<Widget> _form(BuildContext context) {
    final theme = Theme.of(context);
    InputDecoration field(String label, [String? hint]) =>
        InputDecoration(labelText: context.tr(label), hintText: hint == null ? null : context.tr(hint));
    return [
      Text(context.tr('Letters are written in English, which offices use.'),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(
        initialValue: _type,
        decoration: field('Type of letter'),
        items: [
          for (final e in letterTypes.entries) DropdownMenuItem(value: e.key, child: Text(context.tr(e.value))),
        ],
        onChanged: _drafting ? null : (v) => setState(() => _type = v ?? _type),
      ),
      const SizedBox(height: kGap),
      TextField(controller: _recipient, decoration: field('To', 'For example: Mr. Okello, the landlord')),
      const SizedBox(height: kGap),
      TextField(controller: _sender, decoration: field('Your name')),
      const SizedBox(height: kGap),
      TextField(
        controller: _facts,
        minLines: 4,
        maxLines: 10,
        maxLength: 4000,
        decoration: field('What happened', 'A few sentences about what happened and what you want.'),
      ),
      if (_error != null)
        Text(context.tr(_error!), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
      const SizedBox(height: kGap),
      if (_drafting)
        const LoadingPanel(messages: ['Checking the law...', 'Writing your letter...', 'Checking the sections it cites...'])
      else
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _draft,
            icon: const Icon(Icons.edit_document),
            label: Text(context.tr('Generate letter')),
          ),
        ),
      const DisclaimerFooter(),
    ];
  }

  List<Widget> _editor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      if (_unverified.isNotEmpty)
        Card.filled(
          color: scheme.errorContainer,
          shape: kTintedCardShape,
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            textColor: scheme.onErrorContainer,
            title: Text(context.tr('Please check these references before sending; we could not confirm them:')),
            subtitle: Text(_unverified.join(', ')),
          ),
        ),
      const SizedBox(height: 8),
      TextField(
        controller: _letter,
        minLines: 12,
        maxLines: null,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(labelText: context.tr('Your letter (you can edit it)'), alignLabelWithHint: true),
      ),
      if (_citations.isNotEmpty) ...[
        SectionTitle(context.tr('Law cited in this letter')),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final c in _citations) Chip(label: Text(c))]),
      ],
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.copy),
            label: Text(context.tr('Copy')),
            onPressed: () async {
              final app = context.read<AppState>();
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: _letter.text));
              messenger.showSnackBar(SnackBar(content: Text(app.t('Copied'))));
            },
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.share),
            label: Text(context.tr('Share')),
            onPressed: () => SharePlus.instance.share(ShareParams(text: _letter.text, subject: letterTypes[_type])),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(context.tr('Save to My cases')),
          ),
        ],
      ),
      const DisclaimerFooter(),
    ];
  }
}
