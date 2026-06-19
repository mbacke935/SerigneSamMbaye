import '../models/search_result_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

class SearchService {
  final ApiClient _apiClient;

  SearchService(this._apiClient);

  Future<SearchResultModel?> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return null;
    try {
      final response = await _apiClient.dio.get(
        AppConstants.searchEndpoint,
        queryParameters: {'q': q},
      );
      return SearchResultModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
