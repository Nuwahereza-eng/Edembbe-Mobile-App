import 'package:flutter/material.dart';

import '../config/languages.dart';

class GetHelpScreen extends StatelessWidget {
  const GetHelpScreen({super.key, required this.language});

  final LanguageOption language;

  @override
  Widget build(BuildContext context) {
    final organisations = [
      'Legal aid office',
      'Labour office',
      'Land and housing office',
      'Government information desk',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Get help')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            children: [
              const Text(
                'Nearby support',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Map results', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Live Places / Maps integration is ready for the Google Maps setup step.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Show nearby support'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verified organisations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...organisations.map(
                (organisation) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: Text(organisation),
                    subtitle: const Text('This list is ready for Firestore integration.'),
                    trailing: const Icon(Icons.arrow_forward_ios),
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
