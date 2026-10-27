import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/env.dart';
import '../config/languages.dart';
import '../services/app_state.dart';
import '../widgets/community_voice_card.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/language_list.dart';
import '../widgets/layout.dart';
import '../widgets/tr.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final language = app.language;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: PageBody(
        maxWidth: 720,
        children: [
          SectionTitle(context.tr('Language')),
          Card.outlined(
            child: ListTile(
              leading: const LeadingTile(child: Icon(Icons.translate)),
              title: Text(language.name),
              subtitle: Text([
                language.canSpeak ? context.tr('You can ask by voice.') : context.tr(voiceInputUnavailable),
                if (language.canListen) context.tr('Answers can be played aloud.'),
              ].join(' ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLanguageSheet(context),
            ),
          ),
          SectionTitle(context.tr('Appearance')),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(context.tr('Light'))),
              ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(context.tr('Dark'))),
              ButtonSegment(
                  value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(context.tr('System'))),
            ],
            selected: {app.themeMode},
            onSelectionChanged: (s) => context.read<AppState>().setThemeMode(s.first),
          ),
          SectionTitle(context.tr('Your account')),
          Card.outlined(
            child: ListTile(
              leading: LeadingTile(child: Icon(app.auth.available ? Icons.cloud_done_outlined : Icons.phone_android)),
              title: Text(context.tr(app.auth.available ? 'Signed in without a name' : 'Not signed in')),
              subtitle: Text(context.tr(app.auth.available
                  ? 'Your letters and help requests are saved to your private Eddembe account.'
                  : 'Letters are saved on this device only. Help requests and Community Voice need sign-in.')),
            ),
          ),
          if (app.auth.available) ...[
            SectionTitle(context.tr('Community Voice')),
            Text(context.tr('What makes it hardest for people in your community to get help?'), style: muted),
            const SizedBox(height: 12),
            const Card.outlined(child: Padding(padding: EdgeInsets.all(16), child: CommunityVoiceTotals())),
          ],
          SectionTitle(context.tr('About')),
          Text(
            context.tr('Eddembe explains Ugandan law in simple words. Answers come only from the laws in our '
                'library and always show the law and section they rely on. Built by Team TechGenz.'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Gemma 4 via the Gemini API, Sunbird AI for Ugandan languages, Firebase and Flutter. '
            'Some ideas were inspired by the Sauti-Yo project.',
            style: muted,
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('On a phone without the app, dial')} $ussdCode. ${context.tr('The answer comes by SMS.')}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text('API: $apiBaseUrl', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
