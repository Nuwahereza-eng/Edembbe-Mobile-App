import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/app_state.dart';
import 'tr.dart';

/// Reads [text] aloud with a Sunbird voice. Hidden in languages without one.
class PlayAnswerButton extends StatefulWidget {
  const PlayAnswerButton({super.key, required this.text});

  final String text;

  @override
  State<PlayAnswerButton> createState() => _PlayAnswerButtonState();
}

class _PlayAnswerButtonState extends State<PlayAnswerButton> {
  bool _loading = false;
  bool _playing = false;

  Future<void> _play() async {
    final app = context.read<AppState>();
    if (_playing) {
      await app.audio.stop();
      return;
    }
    setState(() => _loading = true);
    try {
      final audio = await app.api.speak(widget.text, language: app.language.code);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
      // Completes when the answer has finished playing or was stopped.
      await app.audio.playBytes(audio);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t(e.message))));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.t('Could not play the answer.'))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AppState>().language.canListen) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _loading ? null : _play,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(_playing ? Icons.stop : Icons.volume_up),
      label: Text(context.tr(_loading ? 'Preparing voice...' : (_playing ? 'Stop' : 'Listen'))),
    );
  }
}
