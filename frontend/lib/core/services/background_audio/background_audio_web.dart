import 'package:just_audio/just_audio.dart';
import '../../models/audio_model.dart';

Future<void> initBackground() async {}

Future<void> setPlayerSource(AudioPlayer player, AudioModel audio, String url) async {
  await player.setUrl(url);
}
