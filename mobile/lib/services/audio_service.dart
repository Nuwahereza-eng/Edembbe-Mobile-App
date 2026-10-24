import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records spoken questions (AAC in .m4a, which Sunbird accepts) and plays answers read aloud.
class AudioService {
  // Created on first use, so screens that never use voice never start the audio plugins.
  AudioRecorder? _recorderInstance;
  AudioPlayer? _playerInstance;
  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/question_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // Mono at 16 kHz is plenty for speech and keeps uploads small on mobile data.
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 64000),
      path: path,
    );
  }

  /// Stops and returns the recording's path, or null if nothing was recorded.
  Future<String?> stopRecording() => _recorder.stop();

  Future<void> cancelRecording() => _recorder.cancel();

  /// Plays [audio] and completes when it has finished or was stopped.
  Future<void> playBytes(Uint8List audio) async {
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
