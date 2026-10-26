import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/languages.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import 'tr.dart';

/// Tap to record a question, tap again to stop. The recording is sent to Sunbird speech-to-text and
/// [onText] receives what was heard, so the person can check it before asking.
/// In a language without speech-to-text the mic is hidden and a short note says to type.
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.onText});

  final ValueChanged<String> onText;

  @override
  State<MicButton> createState() => _MicButtonState();
}

enum _MicState { idle, recording, transcribing }

class _MicButtonState extends State<MicButton> {
  _MicState _state = _MicState.idle;

  Future<void> _toggle() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    if (_state == _MicState.recording) {
      final path = await app.audio.stopRecording();
      if (path == null) {
        setState(() => _state = _MicState.idle);
        return;
      }
      setState(() => _state = _MicState.transcribing);
      try {
        final text = await app.api.transcribe(path, language: app.language.code);
        if (text.trim().isEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(app.t('We could not hear any words. Please try again.'))));
        } else {
          widget.onText(text.trim());
        }
      } on ApiException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(app.t(e.message))));
      } finally {
        if (mounted) setState(() => _state = _MicState.idle);
      }
      return;
    }

    if (!await app.audio.hasMicPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(app.t('Please allow the microphone to ask by voice.'))));
      return;
    }
    await app.audio.startRecording();
    setState(() => _state = _MicState.recording);
  }

  @override
  void dispose() {
    if (_state == _MicState.recording) context.read<AppState>().audio.cancelRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppState>().language;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (!language.canSpeak) {
      return Text(context.tr(voiceInputUnavailable),
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (_state) {
          _MicState.transcribing => const SizedBox.square(
              dimension: 48,
              child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 3)),
            ),
          _MicState.recording => IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
              iconSize: 28,
              onPressed: _toggle,
              icon: const Icon(Icons.stop),
              tooltip: context.tr('Stop recording'),
            ),
          _MicState.idle => IconButton.filledTonal(
              iconSize: 28,
              onPressed: _toggle,
              icon: const Icon(Icons.mic),
              tooltip: context.tr('Ask by voice'),
            ),
        },
        const SizedBox(width: 12),
        Flexible(
          child: Semantics(
            liveRegion: true,
            child: Text(
              context.tr(switch (_state) {
                _MicState.idle => 'Tap the mic to speak',
                _MicState.recording => 'Listening... tap to stop',
                _MicState.transcribing => 'Writing down what you said...',
              }),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
