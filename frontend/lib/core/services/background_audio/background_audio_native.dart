import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../models/audio_model.dart';

Future<void> initBackground() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.serigne_sam_mbaye.channel.audio',
    androidNotificationChannelName: 'Serigne Sam Mbaye',
    androidNotificationOngoing: true,
    notificationColor: const Color(0xFF0F3D2E),
  );
}

Future<void> setPlayerSource(AudioPlayer player, AudioModel audio, String url) async {
  await player.setAudioSource(
    AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(
        id: '${audio.id}',
        title: audio.titre,
        artUri: audio.imageMiniature != null
            ? Uri.tryParse(audio.imageMiniature!)
            : null,
      ),
    ),
  );
}
