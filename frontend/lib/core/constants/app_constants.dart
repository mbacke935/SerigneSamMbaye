import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class AppConstants {
  static const String appName = 'Serigne Sam Mbaye';

  static const String _prodUrl = 'https://serigne-sam-mbaye-api.onrender.com/api';

  static String get baseUrl {
    if (kDebugMode) {
      return kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';
    }
    return _prodUrl;
  }

  static const String tokenEndpoint        = '/token/';
  static const String refreshTokenEndpoint = '/token/refresh/';
  static const String registerEndpoint     = '/users/register/';
  static const String meEndpoint           = '/users/me/';

  static const String biographiesEndpoint  = '/biographies/';
  static const String audiosEndpoint       = '/audios/';
  static const String videosEndpoint       = '/videos/';
  static const String citationsEndpoint    = '/citations/';
  static const String favoritesEndpoint    = '/favorites/';
  static const String searchEndpoint       = '/search/';
}
