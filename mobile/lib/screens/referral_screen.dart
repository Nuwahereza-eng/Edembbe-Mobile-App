import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/records.dart';
import '../services/app_state.dart';
import '../widgets/tr.dart';

/// Sends a help request to a verified organisation. The person picks exactly what to share and must
/// tick consent; nothing is sent without it, and only the chosen fields are saved.
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
  bool _consent = false;
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
    final situation = situationById(widget.situationId);
    final signedIn = app.auth.available;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Request help'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(widget.organisation.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(context.tr('Choose what to share. Only what you tick is sent.'), style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            if (situation != null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _shareSituation,
                onChanged: (v) => setState(() => _shareSituation = v ?? false),
                title: Text(context.tr('My situation')),
                subtitle: Text(context.tr(situation.title)),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _shareSummary,
              onChanged: (v) => setState(() => _shareSummary = v ?? false),
              title: Text(context.tr('A short summary')),
            ),
            if (_shareSummary)
              TextField(
                controller: _summary,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _sharePhone,
              onChanged: (v) => setState(() => _sharePhone = v ?? false),
              title: Text(context.tr('My phone number, so they can call me')),
            ),
            if (_sharePhone)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: context.tr('Phone number'), border: const OutlineInputBorder()),
              ),
            const Divider(height: 32),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: Text(
                context.tr('I agree to share the information I ticked above with this organisation.'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            if (!signedIn)
              Text(context.tr('Help requests need sign-in, which is not set up in this version of the app.'),
                  style: const TextStyle(color: Color(0xFFB3261E))),
            FilledButton.icon(
              onPressed: signedIn && _consent && _sharesSomething && !_sending ? _send : null,
              icon: const Icon(Icons.send),
              label: Text(context.tr('Send request')),
            ),
          ],
        ),
      ),
    );
  }
}
