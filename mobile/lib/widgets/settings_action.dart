import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';
import 'tr.dart';

/// The settings button in each tab's app bar.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: context.tr('Settings'),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
    );
  }
}
