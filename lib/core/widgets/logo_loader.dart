import 'package:flutter/material.dart';

class LogoLoader extends StatefulWidget {
  const LogoLoader({super.key, this.size = 54, this.showLabel = false});

  final double size;
  final bool showLabel;

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logoSize = widget.size.clamp(14.0, 88.0);
    final radius = logoSize * 0.28;

    if (widget.showLabel && widget.size >= 40) {
      return _SkeletonPulse(
        animation: _scale,
        child: const _FigmaLoadingSkeleton(),
      );
    }

    final loader = ScaleTransition(
      scale: _scale,
      child: Container(
        width: logoSize,
        height: logoSize,
        padding: EdgeInsets.all(logoSize * 0.16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.18),
              blurRadius: logoSize * 0.28,
              offset: Offset(0, logoSize * 0.08),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/favicon_bholavashi.png',
          fit: BoxFit.contain,
        ),
      ),
    );

    if (!widget.showLabel) return loader;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loader,
        const SizedBox(height: 10),
        Text(
          'লোড হচ্ছে...',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FigmaLoadingSkeleton extends StatelessWidget {
  const _FigmaLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _SkeletonBox(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 120, height: 14, radius: 4),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 80, height: 10, radius: 3),
                  ],
                ),
              ),
              const _SkeletonBox(width: 40, height: 40, radius: 20),
            ],
          ),
          const SizedBox(height: 24),
          const _SkeletonBox(width: double.infinity, height: 82, radius: 16),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: _SkeletonBox(width: 140, height: 16, radius: 4),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _SkeletonService()),
              SizedBox(width: 12),
              Expanded(child: _SkeletonService()),
              SizedBox(width: 12),
              Expanded(child: _SkeletonService()),
              SizedBox(width: 12),
              Expanded(child: _SkeletonService()),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: _SkeletonBox(width: 100, height: 16, radius: 4),
          ),
          const SizedBox(height: 12),
          const _SkeletonFeedCard(),
          const SizedBox(height: 12),
          const _SkeletonFeedCard(),
        ],
      ),
    );
  }
}

class _SkeletonService extends StatelessWidget {
  const _SkeletonService();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonBox(width: double.infinity, height: 60, radius: 12),
        SizedBox(height: 8),
        _SkeletonBox(width: 44, height: 10, radius: 2),
      ],
    );
  }
}

class _SkeletonFeedCard extends StatelessWidget {
  const _SkeletonFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: const [
          _SkeletonBox(width: 64, height: 64, radius: 8),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 14, radius: 3),
                SizedBox(height: 8),
                _SkeletonBox(width: 140, height: 10, radius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _SkeletonPulse.of(context),
      builder: (context, child) {
        final value = _SkeletonPulse.of(context).value;
        final color = Color.lerp(
          const Color(0xfff3f4f6),
          const Color(0xffe5e7eb),
          value,
        )!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

class _SkeletonPulse extends InheritedNotifier<Animation<double>> {
  const _SkeletonPulse({
    required Animation<double> animation,
    required super.child,
  }) : super(notifier: animation);

  static Animation<double> of(BuildContext context) {
    final pulse = context
        .dependOnInheritedWidgetOfExactType<_SkeletonPulse>()
        ?.notifier;
    return pulse ?? const AlwaysStoppedAnimation(0.5);
  }
}
