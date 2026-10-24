import 'package:flutter/material.dart';

import '../config/languages.dart';

class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key, required this.onSelect});

  final Future<void> Function(String languageCode) onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Choose your language',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select the language you want to use in the app.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: languageOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final language = languageOptions[index];
                    return Card(
                      child: ListTile(
                        leading: Text(language.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(language.name),
                        subtitle: Text(
                          language.canTranslate
                              ? 'Translation, speech and legal answers available'
                              : 'Text only for now',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await onSelect(language.code);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
