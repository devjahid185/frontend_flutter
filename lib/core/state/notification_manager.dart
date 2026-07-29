import 'package:flutter/foundation.dart';
import 'dart:async';

import '../network/api_client.dart';
import '../storage/session_storage.dart';

class NotificationManager extends ChangeNotifier {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  int unreadCount = 0;
  bool _loading = false;
  DateTime? _lastFetchedAt;
  Timer? _timer;

  Future<void> refresh({bool force = false}) async {
    if (_loading) return;
    if (!force && _lastFetchedAt != null) {
      final diff = DateTime.now().difference(_lastFetchedAt!);
      if (diff.inSeconds < 30) return;
    }

    _loading = true;
    try {
      final res = await _api.get('/notifications/unread-count');
      if (res is Map<String, dynamic> && res['count'] is num) {
        unreadCount = (res['count'] as num).toInt();
        notifyListeners();
      }
      _lastFetchedAt = DateTime.now();
    } catch (_) {
      // ignore network errors
    } finally {
      _loading = false;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.post('/notifications/read-all');
      unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void decrement() {
    if (unreadCount <= 0) return;
    unreadCount -= 1;
    notifyListeners();
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) {
      refresh();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
}
