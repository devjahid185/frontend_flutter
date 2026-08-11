import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrl = 'https://api.bholavashi.site/api';
  // Web client ID from Google Cloud Console (OAuth 2.0 Client IDs).
  // Needed to get idToken on Android.
  static const String googleWebClientId = '182072072004-33v2h7gofkgg1j2uj3vop8q5npn9mg5c.apps.googleusercontent.com';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return _apiBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _apiBaseUrl;
      default:
        return _apiBaseUrl;
    }
  }
}
