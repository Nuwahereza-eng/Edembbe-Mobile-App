import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/languages.dart';
import '../services/app_state.dart';
import 'layout.dart';
import 'mic_button.dart';
import 'tr.dart';

/// A chat-style message bar for the bottom of a screen: a rounded text field that grows with the
/// text, then the mic and the send button beside it. Above it go what the mic is doing, or a note
/// that the text came from speech, or that voice is not available in this language.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.sendTooltip = 'Send',
    this.maxLength = 2000,
    this.onTranscribed,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final String sendTooltip;
  final int maxLength;

  /// Called with what speech-to-text heard, so the answer can show "We heard:".
  final ValueChanged<String>? onTranscribed;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  /// What the mic is doing, or null when idle.
  String? _micStatus;

  /// The words speech-to-text returned, to say "We heard this" while the field still holds them.
  String? _heard;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = context.watch<AppState>().language;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final note =
        _micStatus ??
        (_heard != null && _heard == widget.controller.text
            ? 'We heard this. You can correct it before you send.'
            : (language.canSpeak ? null : voiceInputUnavailable));

    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          context.tr(note),
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: widget.maxLength,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: context.tr(widget.hintText),
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      MicButton(
                        compact: true,
                        onStatus: (status) => setState(() => _micStatus = status),
                        onText: (text) {
                          setState(() {
                            _heard = text;
                            widget.controller.text = text;
                          });
                          widget.onTranscribed?.call(text);
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        iconSize: 24,
                        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                        tooltip: context.tr(widget.sendTooltip),
                        onPressed: hasText ? widget.onSend : null,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
