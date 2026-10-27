import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/ask_screen.dart';
import 'screens/home_situations_screen.dart';
import 'screens/language_picker_screen.dart';
import 'screens/my_cases_screen.dart';
import 'screens/scan_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';
import 'widgets/layout.dart';
import 'widgets/tr.dart';

class EddembeApp extends StatelessWidget {
  const EddembeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The language is picked once on first launch and changed later from the top bar or Settings.
    final hasLanguage = context.select<AppState, bool>((s) => s.chosenLanguage != null);
    final themeMode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'Eddembe',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: hasLanguage ? const MainShell() : const LanguagePickerScreen(),
    );
  }
}

/// The four destinations: a bottom navigation bar on phones, a navigation rail on wider screens.
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
    final destinations = [
      (Icons.home_outlined, Icons.home, context.tr('Home')),
      (Icons.chat_outlined, Icons.chat, context.tr('Ask')),
      (Icons.document_scanner_outlined, Icons.document_scanner, context.tr('Scan')),
      (Icons.folder_outlined, Icons.folder, context.tr('My cases')),
    ];
    final body = IndexedStack(
      index: _index,
      children: [
        const HomeSituationsScreen(),
        const AskScreen(),
        const ScanScreen(),
        MyCasesScreen(visible: _index == MainShell.myCasesTab),
      ],
    );

    if (windowClassOf(context) == WindowClass.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final (icon, selected, label) in destinations)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Icon(Icons.balance, size: 32, color: Theme.of(context).colorScheme.primary, semanticLabel: 'Eddembe'),
              ),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
