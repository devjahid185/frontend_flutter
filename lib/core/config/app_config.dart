import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _lanBaseUrl = 'https://rema-cleansable-mirtha.ngrok-free.dev/api';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return _lanBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _lanBaseUrl;
      default:
        return _lanBaseUrl;
    }
  }
}
