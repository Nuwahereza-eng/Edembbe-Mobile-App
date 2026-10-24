import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/languages.dart';
import '../services/app_state.dart';

/// Picks the language for questions and answers. Shown once on first launch and from Settings.
/// Names stay as they are (each person looks for their own language's name).
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key, this.firstLaunch = false});

  final bool firstLaunch;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppState>().chosenLanguage?.code;
    return Scaffold(
      appBar: firstLaunch ? null : AppBar(title: const Text('Language')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          children: [
            if (firstLaunch) ...[
              Icon(Icons.balance, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Eddembe', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Know your rights under Ugandan law.', style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 24),
            ],
            const Text('Choose your language', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mic, size: 18, color: Colors.black54),
                  Text(' you can speak', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up, size: 18, color: Colors.black54),
                  Text(' answers read aloud', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            for (final language in languageOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: language.code == current ? Theme.of(context).colorScheme.primary : Colors.black12,
                      width: language.code == current ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    minTileHeight: 56,
                    title: Text(language.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (language.canSpeak) const Icon(Icons.mic, size: 20, color: Colors.black54),
                        if (language.canListen) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.volume_up, size: 20, color: Colors.black54),
                        ],
                        if (language.code == current) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                        ],
                      ],
                    ),
                    onTap: () async {
                      await context.read<AppState>().setLanguage(language.code);
                      if (!firstLaunch && context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
