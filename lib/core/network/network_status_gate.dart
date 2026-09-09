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
              color: const Color(0xfff4f7f6),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        height: 120,
                        width: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xffe6f1ee),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 62,
                          color: Color(0xff006a4e),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'ইন্টারনেট সংযোগ নেই!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xff1f2937),
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'আপনার ফোনের ডাটা অথবা ওয়াইফাই সংযোগটি পরীক্ষা করে পুনরায় চেষ্টা করুন',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xff6b7280),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _check,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff006a4e),
                            side: const BorderSide(
                              color: Color(0xff006a4e),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('আবার চেষ্টা করুন'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
