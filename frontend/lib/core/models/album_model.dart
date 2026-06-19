import 'audio_model.dart';
import 'video_model.dart';

class AlbumModel {
  final int id;
  final String titre;
  final String? description;
  final String? image;
  final int nbAudios;
  final int nbVideos;
  final List<AudioModel> audios;
  final List<VideoModel> videos;

  const AlbumModel({
    required this.id,
    required this.titre,
    this.description,
    this.image,
    this.nbAudios = 0,
    this.nbVideos = 0,
    this.audios = const [],
    this.videos = const [],
  });

  int get total => nbAudios + nbVideos;

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      nbAudios: (json['nb_audios'] as int?) ?? 0,
      nbVideos: (json['nb_videos'] as int?) ?? 0,
      audios: (json['audios'] as List?)
              ?.map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      videos: (json['videos'] as List?)
              ?.map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
