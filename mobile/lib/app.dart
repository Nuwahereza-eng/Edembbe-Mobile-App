import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/env.dart';
import 'config/languages.dart';
import 'screens/ask_screen.dart';
import 'screens/get_help_screen.dart';
import 'screens/home_situations_screen.dart';
import 'screens/language_picker_screen.dart';
import 'screens/my_cases_screen.dart';
import 'screens/scan_screen.dart';
import 'services/api_client.dart';
import 'theme.dart';

class EddembeApp extends StatefulWidget {
  const EddembeApp({super.key});

  @override
  State<EddembeApp> createState() => _EddembeAppState();
}

class _EddembeAppState extends State<EddembeApp> {
  bool _loading = true;
  bool _showLanguagePicker = false;
  String _languageCode = '';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_language_code');
    if (!mounted) return;
    setState(() {
      _languageCode = saved ?? '';
      _showLanguagePicker = saved == null;
      _loading = false;
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language_code', languageCode);
    if (!mounted) return;
    setState(() {
      _languageCode = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final language = languageForCode(_languageCode);

    return MaterialApp(
      title: 'Eddembe',
      theme: appTheme,
      home: _showLanguagePicker
          ? LanguagePickerScreen(
              onSelect: (code) async {
                await _saveLanguage(code);
                setState(() {
                  _showLanguagePicker = false;
                  _languageCode = code;
                });
              },
            )
          : MainShell(
              language: language,
              onLanguageChanged: _saveLanguage,
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final LanguageOption language;
  final Future<void> Function(String languageCode) onLanguageChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final client = ApiClient(baseUrl: apiBaseUrl);
    _screens = [
      HomeSituationsScreen(
        language: widget.language,
        apiClient: client,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      AskScreen(
        language: widget.language,
        apiClient: client,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      ScanScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      MyCasesScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.help_outline), selectedIcon: Icon(Icons.help), label: 'Ask'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'My cases'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GetHelpScreen(language: widget.language),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Get help'),
            )
          : null,
    );
  }
}
