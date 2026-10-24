import 'package:flutter/material.dart';

import '../config/languages.dart';
import '../widgets/disclaimer_footer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.language, required this.onLanguageChanged});

  final LanguageOption language;
  final Future<void> Function(String languageCode) onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            children: [
              const Text(
                'Language',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languageOptions.map((item) {
                  final selected = item.code == language.code;
                  return ChoiceChip(
                    label: Text('${item.flag} ${item.name}'),
                    selected: selected,
                    onSelected: (_) async {
                      await onLanguageChanged(item.code);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const DisclaimerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
