import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../storage/session_storage.dart';

class AppAnalyticsService {
  AppAnalyticsService._();

  static final AppAnalyticsService instance = AppAnalyticsService._();
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  final _api = ApiClient(getToken: SessionStorage().getToken);
  String? _sessionId;
  String? _deviceId;
  String? _appVersion;
  String? _currentScreen;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('analytics_session_id');
      if (_sessionId == null || _sessionId!.isEmpty) {
        _sessionId =
            '${DateTime.now().millisecondsSinceEpoch}-${identityHashCode(this)}';
        await prefs.setString('analytics_session_id', _sessionId!);
      }
      _deviceId = prefs.getString('analytics_device_id');
      if (_deviceId == null || _deviceId!.isEmpty) {
        _deviceId =
            'dev-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(prefs)}';
        await prefs.setString('analytics_device_id', _deviceId!);
      }
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      _ready = true;
      unawaited(logEvent('app_open'));
    } catch (error) {
      debugPrint('Analytics init skipped: $error');
    }
  }

  Future<void> setUser({String? id, String? phone}) async {
    try {
      if (id != null && id.isNotEmpty) {
        await FirebaseAnalytics.instance.setUserId(id: id);
      }
      if (phone != null && phone.isNotEmpty) {
        await FirebaseAnalytics.instance.setUserProperty(
          name: 'has_phone',
          value: 'true',
        );
      }
    } catch (error) {
      debugPrint('Analytics user setup skipped: $error');
    }
  }

  Future<void> clearUser() async {
    try {
      await FirebaseAnalytics.instance.setUserId(id: null);
    } catch (_) {}
  }

  Future<void> setCurrentScreen(String screenName) async {
    _currentScreen = screenName;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (error) {
      debugPrint('Firebase screen event skipped: $screenName $error');
    }
    unawaited(_sendBackendEvent('screen_view', {'screen_name': screenName}));
  }

  Future<void> logLogin({required String method}) =>
      logEvent('login', {'method': method});

  Future<void> logSignUp({required String method}) =>
      logEvent('sign_up', {'method': method});

  Future<void> logSearch({required String term, String? module}) => logEvent(
    'search',
    {'search_term': term, if (module != null) 'module': module},
  );

  Future<void> logAddToCart({
    required String itemId,
    String? itemName,
    num? value,
  }) {
    return logEvent('add_to_cart', {
      'item_id': itemId,
      if (itemName != null && itemName.isNotEmpty) 'item_name': itemName,
      if (value != null) 'value': value,
      'currency': 'BDT',
    });
  }

  Future<void> logPurchase({
    required num value,
    String? orderId,
    String currency = 'BDT',
  }) {
    return logEvent('purchase', {
      'value': value,
      'currency': currency,
      if (orderId != null && orderId.isNotEmpty) 'transaction_id': orderId,
    });
  }

  Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final clean = _cleanParameters(parameters);
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: clean);
    } catch (error) {
      debugPrint('Firebase event skipped: $name $error');
    }
    unawaited(_sendBackendEvent(name, clean));
  }

  Map<String, Object> _cleanParameters(Map<String, Object?> input) {
    final output = <String, Object>{};
    for (final entry in input.entries) {
      final key = entry.key
          .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')
          .toLowerCase();
      if (key.isEmpty || entry.value == null) continue;
      final value = entry.value!;
      if (value is num || value is String || value is bool) {
        output[key.length > 40
            ? key.substring(0, 40)
            : key] = value is String && value.length > 100
            ? value.substring(0, 100)
            : (value is bool ? value.toString() : value);
      }
    }
    return output;
  }

  Future<void> _sendBackendEvent(
    String name,
    Map<String, Object> params,
  ) async {
    try {
      await _api.post(
        '/analytics/events',
        auth: true,
        body: {
          'event_name': name,
          'screen_name': _currentScreen ?? params['screen_name'],
          'session_id': _sessionId,
          'device_id': _deviceId,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'app_version': _appVersion,
          'parameters': params,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      debugPrint('Backend analytics skipped: $name $error');
    }
  }
}
