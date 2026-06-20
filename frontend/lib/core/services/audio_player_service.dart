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
  // Message d'erreur de lecture (null = pas d'erreur). Permet à l'UI d'afficher
  // un état d'échec au lieu d'un spinner infini quand un audio ne se charge pas.
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  ValueListenable<AudioModel?> get currentAudioListenable => _currentAudioNotifier;
  ValueListenable<double> get speedListenable => speedNotifier;
  ValueListenable<String?> get errorListenable => errorNotifier;
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
    if (url == null || url.isEmpty) {
      _setError(audio, 'Cet audio n’a pas de source de lecture valide.');
      return;
    }
    errorNotifier.value = null;
    _currentAudio = audio;
    _currentAudioNotifier.value = audio;
    try {
      // Timeout : si le chargement ne répond pas (réseau, serveur muet), on
      // bascule en erreur plutôt que de laisser tourner le spinner sans fin.
      await _player.setUrl(url).timeout(const Duration(seconds: 30));
    } catch (_) {
      // URL injoignable, format non supporté, lien Archive pointant vers une
      // page au lieu du fichier… On remonte un état d'erreur à l'UI plutôt que
      // de laisser un spinner tourner indéfiniment.
      await _player.stop();
      _setError(audio, 'Impossible de lire cet audio. Vérifiez le lien ou réessayez.');
      return;
    }
    // Démarrage : sur le web, la politique d'autoplay du navigateur bloque souvent
    // play() quand il n'est pas déclenché par un geste direct (ici on arrive après
    // l'await réseau). Ce n'est PAS une erreur : l'audio est chargé et prêt ; le
    // bouton lecture (geste utilisateur) le démarrera sans problème.
    try {
      await _player.play();
    } catch (_) {
      // Autoplay bloqué — on laisse l'audio prêt et en pause, sans afficher d'erreur.
    }
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
    await _player.stop();
    _currentAudio = null;
    _currentAudioNotifier.value = null;
    errorNotifier.value = null;
  }
}
