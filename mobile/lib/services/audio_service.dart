import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records spoken questions and plays answers read aloud. On a phone recordings are AAC in .m4a; in a
/// browser they are Opus in WebM (what browsers record). Sunbird accepts both.
class AudioService {
  // Created on first use, so screens that never use voice never start the audio plugins.
  AudioRecorder? _recorderInstance;
  AudioPlayer? _playerInstance;
  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  Future<void> startRecording() async {
    if (kIsWeb) {
      // The browser keeps the recording in memory; stop() returns a blob URL.
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.opus, numChannels: 1), path: '');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/question_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // Mono at 16 kHz is plenty for speech and keeps uploads small on mobile data.
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 64000),
      path: path,
    );
  }

  /// Stops and returns the recording's path (a blob URL in a browser), or null if nothing was recorded.
  Future<String?> stopRecording() => _recorder.stop();

  Future<void> cancelRecording() => _recorder.cancel();

  /// Plays [audio] and completes when it has finished or was stopped.
  Future<void> playBytes(Uint8List audio) async {
    if (kIsWeb) {
      await _player.setAudioSource(AudioSource.uri(Uri.dataFromBytes(audio, mimeType: 'audio/wav')));
      await _player.play();
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/answer_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(audio, flush: true);
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> stop() async => _playerInstance?.stop();

  Future<void> dispose() async {
    await _recorderInstance?.dispose();
    await _playerInstance?.dispose();
  }
}
