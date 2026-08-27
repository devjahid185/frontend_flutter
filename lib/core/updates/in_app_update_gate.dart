import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateGate extends StatefulWidget {
  const InAppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<InAppUpdateGate> createState() => _InAppUpdateGateState();
}

class _InAppUpdateGateState extends State<InAppUpdateGate> {
  static bool _checkedThisSession = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checkedThisSession || _checking || !Platform.isAndroid) return;
    _checkedThisSession = true;
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted ||
          info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (!mounted) return;
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('নতুন আপডেট ইনস্টল হয়েছে')),
            );
          }
        }
      }
    } catch (_) {
      // Google Play ছাড়া local/debug install-এ এই API স্বাভাবিকভাবেই unavailable.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
