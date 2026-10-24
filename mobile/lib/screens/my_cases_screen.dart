import 'package:flutter/material.dart';

import '../config/languages.dart';
import 'settings_screen.dart';

class MyCasesScreen extends StatelessWidget {
  const MyCasesScreen({
    super.key,
    required this.language,
    this.onLanguageChanged,
  });

  final LanguageOption language;
  final Future<void> Function(String languageCode)? onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final cases = [
      {'title': 'Eviction response letter', 'status': 'Saved'},
      {'title': 'Workplace complaint', 'status': 'Sent to referral'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My cases'),
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
          child: ListView(
            children: [
              const Text(
                'Letters and referrals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...cases.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(item['title'] as String),
                    subtitle: Text(item['status'] as String),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
