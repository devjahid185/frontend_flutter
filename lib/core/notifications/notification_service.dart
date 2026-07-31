import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../storage/session_storage.dart';

const _channelId = 'bholavashi_general';
const _channelName = 'ভোলাবাসী নোটিফিকেশন';
const _channelDescription = 'ভোলাবাসী অ্যাপের সাধারণ নোটিফিকেশন';
const _fcmTokenKey = 'fcm_token';
const _pushEnabledKey = 'push_notifications_enabled';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.ensureInitialized();
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocalNotification(message);
    });

    _ready = true;
  }

  static Future<void> requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushEnabledKey) ?? true;
  }

  static Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, enabled);
    if (!enabled) {
      await unregisterDeviceToken();
    } else {
      await registerDeviceToken();
    }
  }

  static Future<void> registerDeviceToken() async {
    try {
      if (!await isPushEnabled()) return;
      await ensureInitialized();
      await requestPermissions();

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final api = ApiClient(getToken: SessionStorage().getToken);
      await api.post('/device-token', body: {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await api.post('/device-token', body: {
            'token': newToken,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_fcmTokenKey, newToken);
        } catch (e) {
          debugPrint('[Notifications] Token refresh failed: $e');
        }
      });
    } catch (e) {
      debugPrint('[Notifications] Register token failed: $e');
    }
  }

  static Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fcmTokenKey);
      if (token == null || token.isEmpty) return;

      final api = ApiClient(getToken: SessionStorage().getToken);
      await api.delete('/device-token', body: {'token': token});
      await prefs.remove(_fcmTokenKey);
    } catch (e) {
      debugPrint('[Notifications] Unregister token failed: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body = message.notification?.body ?? message.data['message']?.toString() ?? '';
    final imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['image_url']?.toString() ??
        message.data['image']?.toString();

    final androidDetails = await _buildAndroidDetails(imageUrl);
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title.isNotEmpty ? title : 'ভোলাবাসী',
      body.isNotEmpty ? body : 'নতুন নোটিফিকেশন',
      details,
    );
  }

  static Future<AndroidNotificationDetails> _buildAndroidDetails(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode != 200 || !contentType.toLowerCase().startsWith('image/')) {
        debugPrint('[Notifications] Image response invalid: ${response.statusCode} $contentType $imageUrl');
        return _plainAndroidDetails();
      }
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        debugPrint('[Notifications] Image response empty: $imageUrl');
        return _plainAndroidDetails();
      }
      final bigPicture = BigPictureStyleInformation(
        ByteArrayAndroidBitmap(bytes),
        largeIcon: ByteArrayAndroidBitmap(bytes),
        contentTitle: null,
        summaryText: null,
      );

      return AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        styleInformation: bigPicture,
        importance: Importance.high,
        priority: Priority.high,
      );
    } catch (e) {
      debugPrint('[Notifications] Image load failed: $e');
      return _plainAndroidDetails();
    }
  }

  static AndroidNotificationDetails _plainAndroidDetails() {
    return const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
  }
}
