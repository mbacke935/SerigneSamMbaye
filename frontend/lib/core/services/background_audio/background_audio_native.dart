import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../models/audio_model.dart';

bool _backgroundInitialized = false;

Future<void> initBackground() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.serigne_sam_mbaye.channel.audio',
      androidNotificationChannelName: 'Serigne Sam Mbaye',
      androidNotificationOngoing: true,
      notificationColor: const Color(0xFF0F3D2E),
    );
    _backgroundInitialized = true;
  } catch (e) {
    // Fallback : lecture sans notification si le service échoue
    debugPrint('[Audio] JustAudioBackground.init() failed: $e');
  }
}

Future<void> setPlayerSource(AudioPlayer player, AudioModel audio, String url) async {
  // ExoPlayer exige des URLs strictement percent-encodées.
  final encoded = _encodeUrl(url);

  if (_backgroundInitialized) {
    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(encoded),
        tag: MediaItem(
          id: '${audio.id}',
          title: audio.titre,
          artUri: audio.imageMiniature != null
              ? Uri.tryParse(audio.imageMiniature!)
              : null,
        ),
      ),
    );
  } else {
    await player.setUrl(encoded);
  }
}

/// Encode les caractères invalides dans une URL sans double-encoder
/// les séquences %XX déjà présentes.
String _encodeUrl(String url) {
  try {
    return Uri.parse(url.trim()).toString();
  } catch (_) {
    return Uri.encodeFull(url.trim());
  }
}
