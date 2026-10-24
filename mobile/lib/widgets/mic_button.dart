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
    if (!language.canSpeak) {
      return Text(context.tr(voiceInputUnavailable), style: const TextStyle(fontSize: 14, color: Colors.black54));
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: switch (_state) {
            _MicState.transcribing => const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator()),
            _MicState.recording => IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: scheme.error),
                onPressed: _toggle,
                icon: const Icon(Icons.stop),
                tooltip: context.tr('Stop recording'),
              ),
            _MicState.idle => IconButton.filledTonal(
                onPressed: _toggle,
                icon: const Icon(Icons.mic),
                tooltip: context.tr('Ask by voice'),
              ),
          },
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            context.tr(switch (_state) {
              _MicState.idle => 'Tap to speak',
              _MicState.recording => 'Listening... tap to stop',
              _MicState.transcribing => 'Writing down what you said...',
            }),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
