import 'audio_model.dart';
import 'video_model.dart';
import 'citation_model.dart';

class FavoritesData {
  final List<AudioModel> audios;
  final List<VideoModel> videos;
  final List<CitationModel> citations;

  const FavoritesData({
    required this.audios,
    required this.videos,
    required this.citations,
  });

  factory FavoritesData.empty() =>
      const FavoritesData(audios: [], videos: [], citations: []);

  bool get isEmpty =>
      audios.isEmpty && videos.isEmpty && citations.isEmpty;

  factory FavoritesData.fromList(List<dynamic> items) {
    final audios = <AudioModel>[];
    final videos = <VideoModel>[];
    final citations = <CitationModel>[];

    for (final item in items) {
      final type = item['type_contenu'] as String?;
      final objet = item['objet'] as Map<String, dynamic>?;
      if (objet == null) continue;
      switch (type) {
        case 'audio':
          audios.add(AudioModel.fromJson(objet));
        case 'video':
          videos.add(VideoModel.fromJson(objet));
        case 'citation':
          citations.add(CitationModel.fromJson(objet));
      }
    }

    return FavoritesData(audios: audios, videos: videos, citations: citations);
  }
}
