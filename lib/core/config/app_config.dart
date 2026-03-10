import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _lanBaseUrl = 'http://192.168.0.107:8000/api';

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
