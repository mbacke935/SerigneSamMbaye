import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      // Render (offre gratuite) se met en veille après 15 min : un démarrage à
      // froid peut prendre 30-60s. Des timeouts généreux évitent de faux échecs.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        // Ne pas tenter de rafraîchir sur les endpoints d'authentification eux-mêmes
        // (un 401 y signifie « identifiants invalides », pas « token expiré »).
        final isAuthEndpoint = path.contains('/token');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.read(key: _accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}',
        data: {'refresh': refreshToken},
      );

      await _storage.write(key: _accessTokenKey, value: response.data['access']);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }

  Dio get dio => _dio;
}
