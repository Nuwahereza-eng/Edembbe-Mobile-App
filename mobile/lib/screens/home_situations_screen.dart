import 'package:flutter/material.dart';

import '../config/situations.dart';
import '../widgets/settings_action.dart';
import '../widgets/tr.dart';
import 'get_help_screen.dart';
import 'guided_flow_screen.dart';

class HomeSituationsScreen extends StatelessWidget {
  const HomeSituationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.balance), SizedBox(width: 8), Text('Eddembe')]),
        actions: const [SettingsAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GetHelpScreen())),
        icon: const Icon(Icons.support_agent),
        label: Text(context.tr('Get help')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
          children: [
            Text(context.tr('What is happening?'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              context.tr('Choose what is closest to your situation. We will ask a few simple questions.'),
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            for (final situation in situationOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GuidedFlowScreen(situation: situation)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(situation.icon, color: scheme.onPrimaryContainer, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.tr(situation.title),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(context.tr(situation.description),
                                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
