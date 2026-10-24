import 'package:flutter/material.dart';

import '../config/languages.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key, required this.language});

  final LanguageOption language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request help')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            const Text(
              'Share what you need help with',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Brief summary of the issue',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('I consent to sharing my case summary with a support organisation.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send),
              label: const Text('Send referral request'),
            ),
          ],
        ),
      ),
    );
  }
}
