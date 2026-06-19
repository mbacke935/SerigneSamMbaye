import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_model.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioModel? _currentAudio;
  final ValueNotifier<AudioModel?> _currentAudioNotifier = ValueNotifier(null);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1.0);

  ValueListenable<AudioModel?> get currentAudioListenable => _currentAudioNotifier;
  ValueListenable<double> get speedListenable => speedNotifier;
  AudioModel? get currentAudio => _currentAudio;
  AudioPlayer get player => _player;

  /// Fait défiler les vitesses de lecture courantes (1x → 1.25 → 1.5 → 2 → 0.75).
  Future<void> cycleSpeed() async {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    final i = speeds.indexOf(speedNotifier.value);
    final next = speeds[(i + 1) % speeds.length];
    speedNotifier.value = next;
    await _player.setSpeed(next);
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration?> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get isPlaying => _player.playing;

  Future<void> playAudio(AudioModel audio) async {
    final url = audio.sourceUrl;
    if (url == null || url.isEmpty) return;
    _currentAudio = audio;
    _currentAudioNotifier.value = audio;
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekForward() async {
    final duration = _player.duration ?? Duration.zero;
    final target = _player.position + const Duration(seconds: 15);
    await _player.seek(target > duration ? duration : target);
  }

  Future<void> seekBackward() async {
    final target = _player.position - const Duration(seconds: 15);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    _currentAudio = null;
    _currentAudioNotifier.value = null;
  }
}
