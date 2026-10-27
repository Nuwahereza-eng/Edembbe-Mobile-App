import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/records.dart';
import '../services/app_state.dart';
import '../widgets/layout.dart';
import '../widgets/tr.dart';

/// Sends a help request to a verified organisation. The person picks exactly what to share, then
/// confirms consent in a dialog; nothing is sent without it, and only the chosen fields are saved.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key, required this.organisation, this.situationId, this.summary});

  final SupportOrganisation organisation;
  final String? situationId;
  final String? summary;

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late bool _shareSituation = situationById(widget.situationId) != null;
  bool _shareSummary = false;
  bool _sharePhone = false;
  bool _sending = false;
  late final _summary = TextEditingController(text: widget.summary ?? '');
  final _phone = TextEditingController();

  @override
  void dispose() {
    _summary.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _sharesSomething =>
      _shareSituation || (_shareSummary && _summary.text.trim().isNotEmpty) || (_sharePhone && _phone.text.trim().isNotEmpty);

  /// Plain words for each thing that will be shared, for the consent dialog.
  List<String> _sharedItems(AppState app) => [
        if (_shareSituation && situationById(widget.situationId) != null)
          '${app.t('My situation')}: ${app.t(situationById(widget.situationId)!.title)}',
        if (_shareSummary && _summary.text.trim().isNotEmpty) app.t('A short summary'),
        if (_sharePhone && _phone.text.trim().isNotEmpty) '${app.t('My phone number')}: ${_phone.text.trim()}',
      ];

  Future<void> _confirmAndSend() async {
    final app = context.read<AppState>();
    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConsentDialog(organisation: widget.organisation.name, items: _sharedItems(app)),
    );
    if (agreed == true) await _send();
  }

  Future<void> _send() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    try {
      await app.referrals.send(
        organisation: widget.organisation,
        situation: _shareSituation ? widget.situationId : null,
        summary: _shareSummary ? _summary.text : null,
        phone: _sharePhone ? _phone.text : null,
      );
      app.casesChanged();
      messenger.showSnackBar(SnackBar(content: Text(app.t('Request sent. You can follow it in My cases.'))));
      navigator.pop();
    } catch (e) {
      debugPrint('Referral failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(app.t('Could not send the request. Please try again.'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final situation = situationById(widget.situationId);
    final signedIn = app.auth.available;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Request help'))),
      body: PageBody(
        maxWidth: 640,
        children: [
          Text(widget.organisation.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(context.tr('Choose what to share. Only what you tick is sent.'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: kGap),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (situation != null)
                    CheckboxListTile(
                      value: _shareSituation,
                      onChanged: (v) => setState(() => _shareSituation = v ?? false),
                      title: Text(context.tr('My situation')),
                      subtitle: Text(context.tr(situation.title)),
                    ),
                  CheckboxListTile(
                    value: _shareSummary,
                    onChanged: (v) => setState(() => _shareSummary = v ?? false),
                    title: Text(context.tr('A short summary')),
                  ),
                  if (_shareSummary)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _summary,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 1000,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: context.tr('Summary')),
                      ),
                    ),
                  CheckboxListTile(
                    value: _sharePhone,
                    onChanged: (v) => setState(() => _sharePhone = v ?? false),
                    title: Text(context.tr('My phone number, so they can call me')),
                  ),
                  if (_sharePhone)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: context.tr('Phone number')),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!signedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: kGap),
              child: Text(context.tr('Help requests need sign-in, which is not available right now.'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: signedIn && _sharesSomething && !_sending ? _confirmAndSend : null,
              icon: _sending
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(context.tr('Send request')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lists exactly what will be shared and asks the person to tick that they agree.
class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog({required this.organisation, required this.items});

  final String organisation;
  final List<String> items;

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.privacy_tip_outlined),
      title: Text(context.tr('Share with this organisation?')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.tr('We will send this to')} ${widget.organisation}:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(child: Icon(Icons.check, size: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: Text(context.tr('I agree to share this information.')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        FilledButton(
          onPressed: _agreed ? () => Navigator.pop(context, true) : null,
          child: Text(context.tr('Send request')),
        ),
      ],
    );
  }
}
