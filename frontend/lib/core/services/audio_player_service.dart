import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_model.dart';
import 'background_audio/background_audio.dart';
import 'history_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _loadPersistedSpeed();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onCompleted();
      }
    });
    _player.playingStream.listen((playing) {
      if (playing) {
        _startPositionTimer();
      } else {
        _stopPositionTimer();
        if (_currentAudio != null) {
          _savePosition(_currentAudio!.id, _player.position);
        }
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  AudioModel? _currentAudio;
  final ValueNotifier<AudioModel?> _currentAudioNotifier = ValueNotifier(null);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1.0);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> sleepTimerEndNotifier = ValueNotifier(null);

  List<AudioModel> _playlist = [];
  int _playlistIndex = 0;
  Timer? _positionSaveTimer;
  Timer? _sleepTimer;

  ValueListenable<AudioModel?> get currentAudioListenable => _currentAudioNotifier;
  ValueListenable<double> get speedListenable => speedNotifier;
  ValueListenable<String?> get errorListenable => errorNotifier;
  AudioModel? get currentAudio => _currentAudio;
  AudioPlayer get player => _player;

  bool get hasNext => _playlist.isNotEmpty && _playlistIndex < _playlist.length - 1;
  bool get hasPrevious => _playlist.isNotEmpty && _playlistIndex > 0;

  void setPlaylist(List<AudioModel> playlist, int startIndex) {
    _playlist = List.of(playlist);
    _playlistIndex = startIndex.clamp(0, playlist.length - 1);
  }

  // ── Speed ──────────────────────────────────────────────────────────────────

  Future<void> _loadPersistedSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble('playback_speed') ?? 1.0;
    speedNotifier.value = speed;
    await _player.setSpeed(speed);
  }

  Future<void> cycleSpeed() async {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    final i = speeds.indexOf(speedNotifier.value);
    final next = speeds[(i + 1) % speeds.length];
    speedNotifier.value = next;
    await _player.setSpeed(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', next);
  }

  // ── Position persistence ───────────────────────────────────────────────────

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentAudio != null) {
        _savePosition(_currentAudio!.id, _player.position);
      }
    });
  }

  void _stopPositionTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  Future<void> _savePosition(int audioId, Duration pos) async {
    if (pos.inSeconds < 5) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pos_$audioId', pos.inSeconds);
  }

  Future<Duration?> _loadPosition(int audioId) async {
    final prefs = await SharedPreferences.getInstance();
    final secs = prefs.getInt('pos_$audioId');
    return (secs != null && secs > 5) ? Duration(seconds: secs) : null;
  }

  Future<void> _clearPosition(int audioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pos_$audioId');
  }

  // ── Sleep timer ────────────────────────────────────────────────────────────

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    sleepTimerEndNotifier.value = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      await _player.pause();
      sleepTimerEndNotifier.value = null;
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerEndNotifier.value = null;
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  Future<void> _onCompleted() async {
    if (_currentAudio != null) {
      await _clearPosition(_currentAudio!.id);
    }
    if (hasNext) {
      _playlistIndex++;
      await playAudio(_playlist[_playlistIndex], keepPlaylist: true);
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration?> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get isPlaying => _player.playing;

  Future<void> playAudio(AudioModel audio, {bool keepPlaylist = false}) async {
    final url = audio.sourceUrl;
    if (url == null || url.isEmpty) {
      _setError(audio, 'Cet audio n\'a pas de source de lecture valide.');
      return;
    }

    if (_currentAudio != null && _currentAudio!.id != audio.id) {
      _stopPositionTimer();
      await _savePosition(_currentAudio!.id, _player.position);
    }

    if (!keepPlaylist) {
      _playlist = [];
      _playlistIndex = 0;
    }

    errorNotifier.value = null;
    _currentAudio = audio;
    _currentAudioNotifier.value = audio;

    // Track in history (fire-and-forget)
    unawaited(HistoryService().add(audio));

    try {
      await setPlayerSource(_player, audio, url)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      await _player.stop();
      _setError(audio, 'Impossible de lire cet audio. Vérifiez le lien ou réessayez.');
      return;
    }

    final savedPos = await _loadPosition(audio.id);
    if (savedPos != null) {
      try {
        await _player.seek(savedPos);
      } catch (_) {}
    }

    try {
      await _player.play();
    } catch (_) {
      // Autoplay bloqué sur web — le bouton lecture prendra le relais.
    }
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    _playlistIndex++;
    await playAudio(_playlist[_playlistIndex], keepPlaylist: true);
  }

  Future<void> playPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!hasPrevious) return;
    _playlistIndex--;
    await playAudio(_playlist[_playlistIndex], keepPlaylist: true);
  }

  void _setError(AudioModel audio, String message) {
    _currentAudio = null;
    _currentAudioNotifier.value = null;
    errorNotifier.value = message;
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
    _stopPositionTimer();
    cancelSleepTimer();
    if (_currentAudio != null) {
      await _savePosition(_currentAudio!.id, _player.position);
    }
    await _player.stop();
    _currentAudio = null;
    _currentAudioNotifier.value = null;
    errorNotifier.value = null;
    _playlist = [];
    _playlistIndex = 0;
  }
}
