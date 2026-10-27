import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../services/app_state.dart';
import 'tr.dart';

/// Tells people how to reach Eddembe from a phone without the app: dial the USSD code, answer a few
/// numbered questions, and the answer comes by SMS.
class UssdCard extends StatelessWidget {
  const UssdCard({super.key});

  // "#" must be encoded in a tel: link, or the dialer drops everything from it onwards.
  Future<void> _dial() => launchUrl(Uri.parse('tel:${ussdCode.replaceAll('#', '%23')}'));

  void _share(BuildContext context) {
    final app = context.read<AppState>();
    final text = '${app.t('No smartphone? Get help with your rights from Eddembe on any phone.')} '
        '${app.t('Dial')} $ussdCode. '
        '${app.t('The answer comes by SMS in English, Luganda or Runyankole.')}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.dialpad, color: scheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(context.tr('No smartphone? Use any phone'), style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Dial the code below, answer a few questions by number, and the answer comes by SMS.'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // The code itself, large and easy to copy down. Spoken by screen readers digit by digit.
            Semantics(
              label: '${context.tr('USSD code')} ${ussdCode.split('').join(' ')}',
              excludeSemantics: true,
              child: SelectableText(
                ussdCode,
                style: theme.textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('English, Luganda or Runyankole. Works without internet.'),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _dial,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(context.tr('Dial')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(context.tr('Share with family')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
