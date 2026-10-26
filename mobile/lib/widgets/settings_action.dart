import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings_screen.dart';
import '../services/app_state.dart';
import 'language_list.dart';
import 'tr.dart';

/// Language and settings icon buttons for each tab's top app bar.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppState>().language;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.translate),
          tooltip: '${context.tr('Language')}: ${language.name}',
          onPressed: () => showLanguageSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: context.tr('Settings'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
