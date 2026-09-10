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
