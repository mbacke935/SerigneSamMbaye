import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

/// Erreur d'authentification porteuse d'un message prêt à afficher.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.tokenEndpoint,
        data: {'email': email, 'password': password},
      );
      await _apiClient.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );
      return true;
    } on DioException catch (e) {
      throw _mapError(e, isLogin: true);
    }
  }

  Future<UserModel> register(String email, String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.registerEndpoint,
        data: {'email': email, 'username': username, 'password': password},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, isLogin: false);
    }
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get(AppConstants.meEndpoint);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<bool> isLoggedIn() => _apiClient.isAuthenticated();

  /// Traduit une DioException en message clair pour l'utilisateur.
  AuthException _mapError(DioException e, {required bool isLogin}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AuthException(
          'Le serveur démarre, réessayez dans quelques secondes.',
        );
      case DioExceptionType.connectionError:
        return const AuthException(
          'Connexion impossible. Vérifiez votre réseau.',
        );
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (isLogin && status == 401) {
      return const AuthException('Email ou mot de passe incorrect.');
    }

    // Erreurs de validation DRF : {"champ": ["message"], ...}
    if (status == 400 && data is Map) {
      final msg = _firstFieldError(data);
      if (msg != null) return AuthException(msg);
    }

    if (status == 500) {
      return const AuthException('Erreur du serveur. Réessayez plus tard.');
    }

    return AuthException(
      isLogin ? 'Connexion impossible. Réessayez.' : 'Inscription impossible. Réessayez.',
    );
  }

  String? _firstFieldError(Map data) {
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
