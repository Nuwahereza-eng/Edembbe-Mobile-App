import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/ask_screen.dart';
import 'screens/home_situations_screen.dart';
import 'screens/language_picker_screen.dart';
import 'screens/my_cases_screen.dart';
import 'screens/scan_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';
import 'widgets/tr.dart';

class EddembeApp extends StatelessWidget {
  const EddembeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The language is picked once on first launch and changed later in Settings.
    final hasLanguage = context.select<AppState, bool>((s) => s.chosenLanguage != null);
    return MaterialApp(
      title: 'Eddembe',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: hasLanguage ? const MainShell() : const LanguagePickerScreen(firstLaunch: true),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Lets a screen switch tabs, e.g. to My cases after saving a letter.
  static void showTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_MainShellState>()?._select(index);

  static const int myCasesTab = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeSituationsScreen(),
          const AskScreen(),
          const ScanScreen(),
          MyCasesScreen(visible: _index == MainShell.myCasesTab),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr('Home')),
          NavigationDestination(
              icon: const Icon(Icons.chat_outlined), selectedIcon: const Icon(Icons.chat), label: context.tr('Ask')),
          NavigationDestination(
              icon: const Icon(Icons.document_scanner_outlined),
              selectedIcon: const Icon(Icons.document_scanner),
              label: context.tr('Scan')),
          NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: context.tr('My cases')),
        ],
      ),
    );
  }
}
