import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../storage/session_storage.dart';

class MapSettings {
  const MapSettings({
    required this.isEnabled,
    required this.provider,
    required this.mobileMapMode,
    required this.browserApiKey,
    required this.mapsJavascriptEnabled,
    required this.embedEnabled,
    required this.placesEnabled,
    required this.directionsEnabled,
    required this.clientCacheMinutes,
  });

  final bool isEnabled;
  final String provider;
  final String mobileMapMode;
  final String? browserApiKey;
  final bool mapsJavascriptEnabled;
  final bool embedEnabled;
  final bool placesEnabled;
  final bool directionsEnabled;
  final int clientCacheMinutes;

  bool get canUseGoogle =>
      isEnabled &&
      provider == 'google' &&
      browserApiKey != null &&
      browserApiKey!.isNotEmpty;

  bool get prefersNativeAndroid => mobileMapMode == 'native_android';

  factory MapSettings.fromJson(Map<String, dynamic> json) {
    return MapSettings(
      isEnabled: json['is_enabled'] == true,
      provider: json['provider']?.toString() ?? 'google',
      mobileMapMode: json['mobile_map_mode']?.toString() ?? 'webview',
      browserApiKey: json['browser_api_key']?.toString(),
      mapsJavascriptEnabled: json['maps_javascript_enabled'] != false,
      embedEnabled: json['embed_enabled'] != false,
      placesEnabled: json['places_enabled'] == true,
      directionsEnabled: json['directions_enabled'] == true,
      clientCacheMinutes:
          int.tryParse('${json['client_cache_minutes'] ?? 1440}') ?? 1440,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_enabled': isEnabled,
    'provider': provider,
    'mobile_map_mode': mobileMapMode,
    'browser_api_key': browserApiKey,
    'maps_javascript_enabled': mapsJavascriptEnabled,
    'embed_enabled': embedEnabled,
    'places_enabled': placesEnabled,
    'directions_enabled': directionsEnabled,
    'client_cache_minutes': clientCacheMinutes,
  };
}

class MapSettingsService {
  MapSettingsService._();

  static final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  static const _cacheKey = 'map_settings_cache';
  static const _cacheTimeKey = 'map_settings_cache_time';
  static MapSettings? _memory;

  static Future<MapSettings?> getSettings({bool force = false}) async {
    if (!force && _memory != null) return _memory;

    final prefs = await SharedPreferences.getInstance();
    if (!force) {
      final cached = prefs.getString(_cacheKey);
      final cachedAt = prefs.getInt(_cacheTimeKey);
      if (cached != null && cachedAt != null) {
        final settings = MapSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
        final maxAge = Duration(
          minutes: settings.clientCacheMinutes.clamp(5, 10080),
        );
        if (DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(cachedAt),
            ) <
            maxAge) {
          _memory = settings;
          return settings;
        }
      }
    }

    try {
      final res = await _api.get('/map-settings', auth: false);
      if (res is Map<String, dynamic> && res['settings'] is Map) {
        final settings = MapSettings.fromJson(
          Map<String, dynamic>.from(res['settings'] as Map),
        );
        _memory = settings;
        await prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
        await prefs.setInt(
          _cacheTimeKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return settings;
      }
    } catch (_) {
      return _memory;
    }

    return _memory;
  }
}
