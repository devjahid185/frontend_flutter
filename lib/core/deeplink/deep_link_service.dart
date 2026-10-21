import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/food/food_home_screen.dart';
import '../../features/home/help_support_screen.dart';
import '../analytics/meta_app_events_service.dart';
import '../analytics/app_analytics_service.dart';
import '../network/api_client.dart';
import '../navigation/app_navigator.dart';
import '../notifications/notification_service.dart';
import '../storage/session_storage.dart';
import '../widgets/logo_loader.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _notificationSubscription = NotificationService.tapEvents.listen(
      (data) => unawaited(openNotificationData(data)),
    );
    final pendingNotification = NotificationService.takePendingTapData();
    if (pendingNotification != null) {
      unawaited(openNotificationData(pendingNotification));
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) unawaited(_handle(initial));
    } catch (_) {}

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri)),
      onError: (_) {},
    );
  }

  Future<void> openNotificationData(Map<String, dynamic> data) async {
    final decisionId = data['ai_decision_id']?.toString();
    if (decisionId != null && decisionId.isNotEmpty) {
      unawaited(
        AppAnalyticsService.instance.logEvent('notification_open', {
          'ai_decision_id': decisionId,
          if (data['campaign'] != null) 'campaign': data['campaign'].toString(),
        }),
      );
    }

    final deepLink = data['deep_link']?.toString();
    if (deepLink == null || deepLink.isEmpty) return;
    final uri = Uri.tryParse(deepLink);
    if (uri != null) await _handleWhenReady(uri);
  }

  Future<void> _handleWhenReady(Uri uri) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (appNavigatorKey.currentState != null) {
        await _handle(uri);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _handle(Uri uri) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    unawaited(
      MetaAppEventsService.instance.logEvent(
        name: 'deep_link_open',
        parameters: {'path': uri.path, 'host': uri.host},
      ),
    );

    final segments = _normalizedSegments(uri);
    if (segments.isEmpty) return;

    Widget? screen;
    if (segments.first == 'food') {
      if (segments.length >= 3 &&
          segments[1] == 'orders' &&
          int.tryParse(segments[2]) != null) {
        screen = FoodOrderDetailsScreen(orderId: int.parse(segments[2]));
      } else if (segments.length >= 3 &&
          segments[1] == 'restaurants' &&
          int.tryParse(segments[2]) != null) {
        screen = FoodRestaurantDetailsScreen(id: int.parse(segments[2]));
      } else if (segments.length >= 3 &&
          segments[1] == 'items' &&
          int.tryParse(segments[2]) != null) {
        screen = _DeepLinkedFoodItemScreen(itemId: int.parse(segments[2]));
      } else if (segments.length >= 2 && segments[1] == 'cart') {
        screen = const FoodCartScreen();
      } else {
        screen = const FoodHomeScreen();
      }
    } else if (segments.first == 'support') {
      screen = const HelpSupportScreen();
    }

    if (screen == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => screen!));
  }

  List<String> _normalizedSegments(Uri uri) {
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (uri.scheme == 'bholavashi' && uri.host.isNotEmpty) {
      return [uri.host, ...pathSegments];
    }
    return pathSegments;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _notificationSubscription?.cancel();
    _subscription = null;
    _notificationSubscription = null;
    _started = false;
  }
}

class _DeepLinkedFoodItemScreen extends StatefulWidget {
  const _DeepLinkedFoodItemScreen({required this.itemId});
  final int itemId;

  @override
  State<_DeepLinkedFoodItemScreen> createState() =>
      _DeepLinkedFoodItemScreenState();
}

class _DeepLinkedFoodItemScreenState extends State<_DeepLinkedFoodItemScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final item = await _api.get('/food/items/${widget.itemId}');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FoodItemDetailsScreen(
            item: Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FoodHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: LogoLoader(showLabel: true)));
  }
}
