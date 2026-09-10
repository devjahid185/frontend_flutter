import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class NetworkStatusGate extends StatefulWidget {
  const NetworkStatusGate({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusGate> createState() => _NetworkStatusGateState();
}

class _NetworkStatusGateState extends State<NetworkStatusGate> {
  Timer? _timer;
  bool _offline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final result = await InternetAddress.lookup(
        'api.bholavashi.site',
      ).timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted) setState(() => _offline = !online);
    } catch (_) {
      if (mounted) setState(() => _offline = true);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'ইন্টারনেট সংযোগ নেই',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'কানেকশন ঠিক করে আবার চেষ্টা করুন। সংযোগ ফিরে এলে অ্যাপ নিজে থেকেই চালু হবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _check,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('আবার চেষ্টা করুন'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
