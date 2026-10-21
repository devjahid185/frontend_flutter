import 'dart:async';
import 'dart:convert';
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
const _ownerOrderChannelId = 'bholavashi_owner_orders';
const _ownerOrderChannelName = 'রেস্টুরেন্টের নতুন অর্ডার';
const _ownerOrderChannelDescription =
    'রেস্টুরেন্ট মালিকের নতুন খাবারের অর্ডার অ্যালার্ট';
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
  static final StreamController<Map<String, dynamic>>
  _foregroundEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _tapEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _ready = false;
  static Map<String, dynamic>? _pendingTapData;

  static Stream<Map<String, dynamic>> get foregroundEvents =>
      _foregroundEventController.stream;

  static Stream<Map<String, dynamic>> get tapEvents =>
      _tapEventController.stream;

  static Map<String, dynamic>? takePendingTapData() {
    final data = _pendingTapData;
    _pendingTapData = null;
    return data;
  }

  static Future<void> ensureInitialized() async {
    if (_ready) return;

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    const ownerOrderChannel = AndroidNotificationChannel(
      _ownerOrderChannelId,
      _ownerOrderChannelName,
      description: _ownerOrderChannelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            _emitTap(Map<String, dynamic>.from(decoded));
          }
        } catch (e) {
          debugPrint('[Notifications] Invalid tap payload: $e');
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(ownerOrderChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data.isNotEmpty) {
        _foregroundEventController.add(Map<String, dynamic>.from(message.data));
      }
      await _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.isNotEmpty) {
        _emitTap(Map<String, dynamic>.from(message.data));
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      _pendingTapData = Map<String, dynamic>.from(initialMessage.data);
    }

    final localLaunch = await _localNotifications
        .getNotificationAppLaunchDetails();
    final localPayload = localLaunch?.notificationResponse?.payload;
    if (localLaunch?.didNotificationLaunchApp == true &&
        localPayload != null &&
        localPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(localPayload);
        if (decoded is Map) {
          _pendingTapData = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('[Notifications] Invalid launch payload: $e');
      }
    }

    _ready = true;
  }

  static Future<void> requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
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
      await api.post(
        '/device-token',
        body: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await api.post(
            '/device-token',
            body: {
              'token': newToken,
              'platform': Platform.isAndroid ? 'android' : 'ios',
            },
          );
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
    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['message']?.toString() ?? '';
    final imageUrl =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['image_url']?.toString() ??
        message.data['image']?.toString();

    final ownerOrder = _isOwnerOrder(message.data);
    final androidDetails = await _buildAndroidDetails(imageUrl, ownerOrder);
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      int.tryParse('${message.data['order_id'] ?? ''}') ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title.isNotEmpty ? title : 'ভোলাবাসী',
      body.isNotEmpty ? body : 'নতুন নোটিফিকেশন',
      details,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  static Future<AndroidNotificationDetails> _buildAndroidDetails(
    String? imageUrl,
    bool ownerOrder,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return AndroidNotificationDetails(
        ownerOrder ? _ownerOrderChannelId : _channelId,
        ownerOrder ? _ownerOrderChannelName : _channelName,
        channelDescription: ownerOrder
            ? _ownerOrderChannelDescription
            : _channelDescription,
        importance: ownerOrder ? Importance.max : Importance.high,
        priority: ownerOrder ? Priority.max : Priority.high,
        category: ownerOrder
            ? AndroidNotificationCategory.message
            : AndroidNotificationCategory.status,
        playSound: true,
        enableVibration: true,
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(imageUrl),
            headers: const {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 12));
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode != 200 ||
          !contentType.toLowerCase().startsWith('image/')) {
        debugPrint(
          '[Notifications] Image response invalid: ${response.statusCode} $contentType $imageUrl',
        );
        return _plainAndroidDetails(ownerOrder);
      }
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        debugPrint('[Notifications] Image response empty: $imageUrl');
        return _plainAndroidDetails(ownerOrder);
      }
      final bigPicture = BigPictureStyleInformation(
        ByteArrayAndroidBitmap(bytes),
        largeIcon: ByteArrayAndroidBitmap(bytes),
        contentTitle: null,
        summaryText: null,
      );

      return AndroidNotificationDetails(
        ownerOrder ? _ownerOrderChannelId : _channelId,
        ownerOrder ? _ownerOrderChannelName : _channelName,
        channelDescription: ownerOrder
            ? _ownerOrderChannelDescription
            : _channelDescription,
        styleInformation: bigPicture,
        importance: ownerOrder ? Importance.max : Importance.high,
        priority: ownerOrder ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
      );
    } catch (e) {
      debugPrint('[Notifications] Image load failed: $e');
      return _plainAndroidDetails(ownerOrder);
    }
  }

  static AndroidNotificationDetails _plainAndroidDetails(bool ownerOrder) {
    return AndroidNotificationDetails(
      ownerOrder ? _ownerOrderChannelId : _channelId,
      ownerOrder ? _ownerOrderChannelName : _channelName,
      channelDescription: ownerOrder
          ? _ownerOrderChannelDescription
          : _channelDescription,
      importance: ownerOrder ? Importance.max : Importance.high,
      priority: ownerOrder ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
    );
  }

  static bool _isOwnerOrder(Map<String, dynamic> data) {
    return data['type']?.toString() == 'food_order' &&
        data['role']?.toString() == 'restaurant_owner' &&
        data['event']?.toString() == 'new_order';
  }

  static void _emitTap(Map<String, dynamic> data) {
    if (_tapEventController.hasListener) {
      _tapEventController.add(data);
    } else {
      _pendingTapData = data;
    }
  }
}
