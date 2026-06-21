import '../models/audio_model.dart';
import '../models/video_model.dart';
import '../models/citation_model.dart';
import '../models/biographie_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

class PagedResult<T> {
  final List<T> items;
  final bool hasMore;
  const PagedResult({required this.items, required this.hasMore});
}

class ContentService {
  final ApiClient _apiClient;

  ContentService(this._apiClient);

  Future<CitationModel?> getCitationDuJour() async {
    try {
      final response = await _apiClient.dio
          .get('${AppConstants.citationsEndpoint}du_jour/');
      return CitationModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<AudioModel>> getDerniersAudios({int limit = 5}) async {
    try {
      final response = await _apiClient.dio.get(AppConstants.audiosEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .take(limit)
          .map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AudioModel>> getAllAudios() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.audiosEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PagedResult<AudioModel>> getAudiosPaged(int page) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.audiosEndpoint,
        queryParameters: {'page': page},
      );
      final raw = response.data;
      final list = (raw['results'] as List? ?? [])
          .map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult(items: list, hasMore: raw['next'] != null);
    } catch (_) {
      return const PagedResult(items: [], hasMore: false);
    }
  }

  Future<PagedResult<VideoModel>> getVideosPaged(int page) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.videosEndpoint,
        queryParameters: {'page': page},
      );
      final raw = response.data;
      final list = (raw['results'] as List? ?? [])
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult(items: list, hasMore: raw['next'] != null);
    } catch (_) {
      return const PagedResult(items: [], hasMore: false);
    }
  }

  Future<List<BiographieModel>> getBiographies() async {
    try {
      final response =
          await _apiClient.dio.get(AppConstants.biographiesEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .map((e) => BiographieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CitationModel>> getAllCitations() async {
    try {
      final response =
          await _apiClient.dio.get(AppConstants.citationsEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoModel>> getAllVideos() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.videosEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoModel>> getDernieresVideos({int limit = 6}) async {
    try {
      final response = await _apiClient.dio.get(AppConstants.videosEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .take(limit)
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
