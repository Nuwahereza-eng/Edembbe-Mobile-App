import 'package:flutter/material.dart';

import '../config/languages.dart';
import '../config/situations.dart';
import 'guided_flow_screen.dart';
import 'settings_screen.dart';

class HomeSituationsScreen extends StatelessWidget {
  const HomeSituationsScreen({
    super.key,
    required this.language,
    required this.apiClient,
    this.onLanguageChanged,
  });

  final LanguageOption language;
  final dynamic apiClient;
  final Future<void> Function(String languageCode)? onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eddembe'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    language: language,
                    onLanguageChanged: onLanguageChanged ?? (_) async {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your situation',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick the issue most like yours and get a guided answer.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: situationOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final situation = situationOptions[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          situation.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(situation.description),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuidedFlowScreen(
                                situation: situation,
                                language: language,
                                apiClient: apiClient,
                              ),
                            ),
                          );
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
