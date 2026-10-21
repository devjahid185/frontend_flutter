import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps the app and shows a full-screen "no internet" view when the API host
/// cannot be reached. The view hides itself (with a short "back online" toast)
/// as soon as the connection returns.
class NetworkStatusGate extends StatefulWidget {
  const NetworkStatusGate({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusGate> createState() => _NetworkStatusGateState();
}

class _NetworkStatusGateState extends State<NetworkStatusGate> {
  static const String _host = 'api.bholavashi.site';

  Timer? _timer;
  Timer? _restoredTimer;
  bool _offline = false;
  bool _checking = false;
  bool _restored = false;
  bool _retryFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  Future<void> _check({bool manual = false}) async {
    if (_checking) return;
    _checking = true;
    if (manual && mounted) {
      setState(() => _retryFailed = false);
    }

    var online = false;
    try {
      final result = await InternetAddress.lookup(
        _host,
      ).timeout(const Duration(seconds: 5));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    // Offline lookups fail instantly; keep the spinner visible long enough
    // for the user to notice that something happened.
    if (manual) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    _checking = false;
    if (!mounted) return;

    final wasOffline = _offline;
    setState(() {
      _offline = !online;
      _retryFailed = manual && !online;
      if (wasOffline && online) _restored = true;
    });

    if (wasOffline && online) {
      _restoredTimer?.cancel();
      _restoredTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted) setState(() => _restored = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_offline,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.04, end: 1.0).animate(
                      animation,
                    ),
                    child: child,
                  ),
                );
              },
              child: _offline
                  ? _OfflineView(
                      key: const ValueKey('offline'),
                      checking: _checking,
                      failed: _retryFailed,
                      onRetry: () => _check(manual: true),
                    )
                  : const SizedBox.shrink(key: ValueKey('online')),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _RestoredToast(visible: _restored),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small dark pill that slides in from the top when the connection returns.
class _RestoredToast extends StatelessWidget {
  const _RestoredToast({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -2.5),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: scheme.inverseSurface,
            elevation: 8,
            shadowColor: scheme.shadow.withValues(alpha: 0.4),
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ইন্টারনেট সংযোগ ফিরে এসেছে',
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineView extends StatefulWidget {
  const _OfflineView({
    super.key,
    required this.checking,
    required this.failed,
    required this.onRetry,
  });

  final bool checking;
  final bool failed;
  final VoidCallback onRetry;

  @override
  State<_OfflineView> createState() => _OfflineViewState();
}

class _OfflineViewState extends State<_OfflineView>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _enter;

  late final CurvedAnimation _illoFade;
  late final CurvedAnimation _illoScale;
  late final CurvedAnimation _title;
  late final CurvedAnimation _body;
  late final CurvedAnimation _tips;
  late final CurvedAnimation _cta;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    CurvedAnimation iv(double a, double b, Curve c) =>
        CurvedAnimation(parent: _enter, curve: Interval(a, b, curve: c));

    _illoFade = iv(0.0, 0.40, Curves.easeOut);
    _illoScale = iv(0.0, 0.55, Curves.easeOutBack);
    _title = iv(0.22, 0.62, Curves.easeOutCubic);
    _body = iv(0.32, 0.72, Curves.easeOutCubic);
    _tips = iv(0.44, 0.84, Curves.easeOutCubic);
    _cta = iv(0.56, 1.0, Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop.stop();
      _enter.value = 1;
    }
  }

  @override
  void dispose() {
    _illoFade.dispose();
    _illoScale.dispose();
    _title.dispose();
    _body.dispose();
    _tips.dispose();
    _cta.dispose();
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  Widget _ring(ColorScheme scheme, double t, double phase) {
    final v = (t + phase) % 1.0;
    final e = Curves.easeOut.transform(v);
    final size = 110 + 106 * e;
    return Opacity(
      opacity: (1 - e) * 0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _illustration(ColorScheme scheme) {
    return SizedBox(
      width: 216,
      height: 216,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final t = _loop.value;
          final float = math.sin(t * 2 * math.pi) * 5;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _ring(scheme, t, 0),
              _ring(scheme, t, 1 / 3),
              _ring(scheme, t, 2 / 3),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
              ),
              // Small dot orbiting the icon.
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: SizedBox(
                  width: 172,
                  height: 172,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 42,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(ColorScheme scheme, double size, double drift) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final s = math.sin(_loop.value * 2 * math.pi + drift);
        return Transform.translate(offset: Offset(s * 14, s * -10), child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _tip(ColorScheme scheme, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.10),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final checking = widget.checking;

    return SizedBox.expand(
      child: Material(
        color: scheme.surface,
        child: Stack(
          children: [
            Positioned(top: -90, right: -70, child: _blob(scheme, 260, 0)),
            Positioned(bottom: -110, left: -80, child: _blob(scheme, 300, 2.2)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _illoFade,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.6, end: 1.0)
                                .animate(_illoScale),
                            child: _illustration(scheme),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Reveal(
                          animation: _title,
                          child: Text(
                            'ইন্টারনেট সংযোগ নেই',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Reveal(
                          animation: _body,
                          child: Text(
                            'কানেকশন ঠিক করে আবার চেষ্টা করুন। সংযোগ ফিরে এলে অ্যাপ নিজে থেকেই চালু হবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _Reveal(
                          animation: _tips,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              children: [
                                _tip(
                                  scheme,
                                  Icons.wifi_rounded,
                                  'Wi-Fi বা মোবাইল ডাটা চালু আছে কিনা দেখুন',
                                ),
                                const SizedBox(height: 10),
                                _tip(
                                  scheme,
                                  Icons.airplanemode_inactive_rounded,
                                  'এয়ারপ্লেন মোড বন্ধ আছে কিনা দেখুন',
                                ),
                                const SizedBox(height: 10),
                                _tip(
                                  scheme,
                                  Icons.schedule_rounded,
                                  'কিছুক্ষণ অপেক্ষা করে আবার চেষ্টা করুন',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _Reveal(
                          animation: _cta,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: FilledButton(
                                  onPressed: checking ? null : widget.onRetry,
                                  style: FilledButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    disabledBackgroundColor: scheme.primary
                                        .withValues(alpha: 0.9),
                                    disabledForegroundColor: scheme.onPrimary,
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: checking
                                        ? Row(
                                            key: const ValueKey('checking'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: scheme.onPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text('চেক করা হচ্ছে...'),
                                            ],
                                          )
                                        : const Row(
                                            key: ValueKey('idle'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.refresh_rounded),
                                              SizedBox(width: 8),
                                              Text('আবার চেষ্টা করুন'),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                child: (widget.failed && !checking)
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          'এখনও সংযোগ পাওয়া যায়নি। একটু পরে আবার চেষ্টা করুন।',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: scheme.error,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                              const SizedBox(height: 16),
                              AnimatedBuilder(
                                animation: _loop,
                                builder: (context, _) {
                                  final pulse =
                                      0.5 +
                                      0.5 *
                                          math.sin(
                                            _loop.value * 2 * math.pi,
                                          );
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Opacity(
                                        opacity: 0.35 + 0.65 * pulse,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'স্বয়ংক্রিয়ভাবে চেক করা হচ্ছে',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade + small upward slide, driven by a staggered animation.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}