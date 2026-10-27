import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/languages.dart';
import '../services/app_state.dart';

/// All languages with a search box. Names stay in their own spelling, never translated.
/// Icons show where you can speak a question and where answers can be played.
class LanguageList extends StatefulWidget {
  const LanguageList({super.key, required this.onChosen, this.scrollController, this.header});

  final VoidCallback onChosen;
  final ScrollController? scrollController;
  final Widget? header;

  @override
  State<LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<LanguageList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = context.watch<AppState>().chosenLanguage?.code;
    final shown = languageOptions.where((l) => l.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ?widget.header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            hintText: 'Search languages',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Legend(icon: Icons.mic, text: 'You can speak', color: scheme.onSurfaceVariant),
              _Legend(icon: Icons.volume_up, text: 'Answers can be played', color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        for (final language in shown)
          ListTile(
            title: Text(language.name),
            selected: language.code == current,
            leading: Icon(language.code == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (language.canSpeak) Icon(Icons.mic, size: 20, semanticLabel: 'You can speak'),
                if (language.canListen) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.volume_up, size: 20, semanticLabel: 'Answers can be played'),
                ],
              ],
            ),
            onTap: () async {
              await context.read<AppState>().setLanguage(language.code);
              widget.onChosen();
            },
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No language matches "$_query".', style: theme.textTheme.bodyLarge),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

/// Opens the language list in a bottom sheet.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => LanguageList(
        scrollController: controller,
        onChosen: () => Navigator.pop(sheetContext),
        header: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Choose your language', style: Theme.of(sheetContext).textTheme.titleLarge),
        ),
      ),
    ),
  );
}
