import 'audio_model.dart';
import 'video_model.dart';
import 'citation_model.dart';
import 'biographie_model.dart';

class SearchResultModel {
  final String query;
  final List<AudioModel> audios;
  final List<VideoModel> videos;
  final List<CitationModel> citations;
  final List<BiographieModel> biographies;

  const SearchResultModel({
    required this.query,
    required this.audios,
    required this.videos,
    required this.citations,
    required this.biographies,
  });

  bool get isEmpty =>
      audios.isEmpty &&
      videos.isEmpty &&
      citations.isEmpty &&
      biographies.isEmpty;

  int get totalCount =>
      audios.length + videos.length + citations.length + biographies.length;

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final r = json['resultats'] as Map<String, dynamic>? ?? {};
    return SearchResultModel(
      query: json['query'] as String? ?? '',
      audios: (r['audios'] as List? ?? [])
          .map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      videos: (r['videos'] as List? ?? [])
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      citations: (r['citations'] as List? ?? [])
          .map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      biographies: (r['biographies'] as List? ?? [])
          .map((e) => BiographieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
