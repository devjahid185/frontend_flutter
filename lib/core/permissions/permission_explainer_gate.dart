import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_service.dart';

class PermissionExplainerGate extends StatefulWidget {
  const PermissionExplainerGate({super.key, required this.child});

  final Widget child;

  @override
  State<PermissionExplainerGate> createState() =>
      _PermissionExplainerGateState();
}

class _PermissionExplainerGateState extends State<PermissionExplainerGate> {
  static const _notificationAskedKey = 'notification_permission_explained';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_explainNotifications());
    });
  }

  Future<void> _explainNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_notificationAskedKey) == true || !mounted) return;

    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নোটিফিকেশন চালু করবেন?'),
        content: const Text(
          'অর্ডার আপডেট, রাইডার স্ট্যাটাস, সাপোর্ট রিপ্লাই এবং জরুরি তথ্য সময়মতো পেতে নোটিফিকেশন দরকার।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('এখন নয়'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('চালু করুন'),
          ),
        ],
      ),
    );

    await prefs.setBool(_notificationAskedKey, true);
    if (allow == true) {
      await NotificationService.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
