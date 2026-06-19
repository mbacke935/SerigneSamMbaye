import '../models/favorites_data.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

class FavoriService {
  final ApiClient _apiClient;

  FavoriService(this._apiClient);

  Future<bool> toggle(String type, int objectId) async {
    try {
      final response = await _apiClient.dio.post(
        '${AppConstants.favoritesEndpoint}toggle/',
        data: {'type': type, 'object_id': objectId},
      );
      return response.data['is_favorited'] as bool;
    } catch (_) {
      return false;
    }
  }

  Future<Set<int>> getFavoritedIds(String type) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.favoritesEndpoint}ids/',
        queryParameters: {'type': type},
      );
      final ids = response.data['ids'] as List;
      return ids.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<FavoritesData> getFavorites() async {
    try {
      final response =
          await _apiClient.dio.get(AppConstants.favoritesEndpoint);
      final raw = response.data;
      final list =
          raw is List ? raw : (raw['results'] as List? ?? []);
      return FavoritesData.fromList(list);
    } catch (_) {
      return FavoritesData.empty();
    }
  }
}
