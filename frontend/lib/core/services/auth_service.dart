import '../models/user_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<bool> login(String email, String password) async {
    final response = await _apiClient.dio.post(
      AppConstants.tokenEndpoint,
      data: {'email': email, 'password': password},
    );
    await _apiClient.saveTokens(
      response.data['access'],
      response.data['refresh'],
    );
    return true;
  }

  Future<UserModel> register(String email, String username, String password) async {
    final response = await _apiClient.dio.post(
      AppConstants.registerEndpoint,
      data: {'email': email, 'username': username, 'password': password},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get(AppConstants.meEndpoint);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<bool> isLoggedIn() => _apiClient.isAuthenticated();
}
