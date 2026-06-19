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

  ValueListenable<AudioModel?> get currentAudioListenable => _currentAudioNotifier;
  AudioModel? get currentAudio => _currentAudio;
  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration?> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get isPlaying => _player.playing;

  Future<void> playAudio(AudioModel audio) async {
    if (audio.fichier == null || audio.fichier!.isEmpty) return;
    _currentAudio = audio;
    _currentAudioNotifier.value = audio;
    await _player.setUrl(audio.fichier!);
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
