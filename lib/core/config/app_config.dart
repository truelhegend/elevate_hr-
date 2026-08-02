import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  static const String _devBaseUrl = 'http://localhost:3000/api/v1';
  static const String _prodBaseUrl = 'https://api.elevatehr.com/api/v1';

  static String get apiBaseUrl {
    const prodOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (prodOverride.isNotEmpty) return prodOverride;
    return kIsWeb ? _prodBaseUrl : _devBaseUrl;
  }

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
