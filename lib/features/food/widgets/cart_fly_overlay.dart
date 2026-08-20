import 'package:flutter/material.dart';

class CartFlyOverlay extends StatelessWidget {
  const CartFlyOverlay({
    super.key,
    required this.start,
    required this.end,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 720),
          curve: Curves.easeInOutCubicEmphasized,
          onEnd: onDone,
          builder: (context, value, child) {
            final liftedStart = start.translate(0, -8);
            final control = Offset(
              (liftedStart.dx + end.dx) / 2,
              liftedStart.dy - 96,
            );
            final first = Offset.lerp(liftedStart, control, value)!;
            final second = Offset.lerp(control, end, value)!;
            final position = Offset.lerp(first, second, value)!;
            final lateProgress = ((value - 0.78) / 0.22).clamp(0.0, 1.0);
            final scale = value < 0.78
                ? 1.0 + (0.18 * Curves.easeOut.transform(value / 0.78))
                : 1.18 - (0.42 * Curves.easeIn.transform(lateProgress));
            final opacity = value < 0.82
                ? 1.0
                : 1 - (((value - 0.82) / 0.18).clamp(0.0, 1.0));

            return Stack(
              children: [
                Positioned(
                  left: position.dx - 19,
                  top: position.dy - 19,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              ],
            );
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB91C1C).withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
