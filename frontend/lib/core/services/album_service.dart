import '../models/album_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

class AlbumService {
  final ApiClient _apiClient;

  AlbumService(this._apiClient);

  Future<List<AlbumModel>> getAlbums() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.albumsEndpoint);
      final raw = response.data;
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      return list
          .map((e) => AlbumModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AlbumModel?> getAlbum(int id) async {
    try {
      final response =
          await _apiClient.dio.get('${AppConstants.albumsEndpoint}$id/');
      return AlbumModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
