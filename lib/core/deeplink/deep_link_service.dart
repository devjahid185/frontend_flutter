import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/food/food_home_screen.dart';
import '../../features/home/help_support_screen.dart';
import '../analytics/meta_app_events_service.dart';
import '../navigation/app_navigator.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) unawaited(_handle(initial));
    } catch (_) {}

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri)),
      onError: (_) {},
    );
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
    _subscription = null;
    _started = false;
  }
}
