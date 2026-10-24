import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/env.dart';
import '../config/languages.dart';
import '../services/app_state.dart';
import '../widgets/community_voice_card.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/tr.dart';
import 'language_picker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final language = app.language;
    const heading = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(context.tr('Language'), style: heading),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              child: ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.translate),
                title: Text(language.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([
                  language.canSpeak ? context.tr('You can ask by voice.') : context.tr(voiceInputUnavailable),
                  if (language.canListen) context.tr('Answers can be read aloud.'),
                ].join(' ')),
                trailing: Text(context.tr('Change')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePickerScreen())),
              ),
            ),
            const SizedBox(height: 20),
            const DisclaimerFooter(),
            const SizedBox(height: 20),
            Text(context.tr('Your account'), style: heading),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              child: ListTile(
                leading: Icon(app.auth.available ? Icons.cloud_done_outlined : Icons.phone_android),
                title: Text(context.tr(app.auth.available ? 'Signed in without a name' : 'Not signed in')),
                subtitle: Text(context.tr(app.auth.available
                    ? 'Your letters and help requests are saved to your private Eddembe account.'
                    : 'Letters are saved on this phone only. Help requests and Community Voice need sign-in.')),
              ),
            ),
            if (app.auth.available) ...[
              const SizedBox(height: 20),
              Text(context.tr('Community Voice'), style: heading),
              const SizedBox(height: 4),
              Text(context.tr('What makes it hardest for people in your community to get help?'),
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 12),
              const Card(color: Colors.white, child: Padding(padding: EdgeInsets.all(16), child: CommunityVoiceTotals())),
            ],
            const SizedBox(height: 20),
            Text(context.tr('About'), style: heading),
            const SizedBox(height: 8),
            Text(
              context.tr('Eddembe explains Ugandan law in simple words. Answers come only from the laws in our '
                  'library and always show the law and section they rely on. Built by Team TechGenz.'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gemma 4 via the Gemini API, Sunbird AI for Ugandan languages, Firebase and Flutter. '
              'Some ideas were inspired by the Sauti-Yo project.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text('API: $apiBaseUrl', style: const TextStyle(fontSize: 14, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
