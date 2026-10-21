import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One destination in [AnimatedBottomNavBar].
class AnimatedBottomNavItem {
  const AnimatedBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Optional counter bubble on the icon.
  ///
  /// `null` hides the badge completely. `0` keeps it mounted but scaled out,
  /// so it pops in with a bounce as soon as the count goes above zero.
  final int? badgeCount;
}

/// Floating dock navigation bar with an optional raised centre action.
///
/// * the dock is drawn as one smooth path, with a round cradle cut out for
///   the featured button (no hard overlaps, works on any page background)
/// * regular tabs get a tinted capsule that grows behind the active icon,
///   the icon pops with an elastic bounce and the label turns bold
/// * the featured button pulses with a soft halo while it is selected
/// * press feedback, haptics, badge counters and reduced-motion support
class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.featuredIndex,
  });

  final List<AnimatedBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Index of the item shown as the raised centre button.
  final int? featuredIndex;

  static const double _barHeight = 68;
  static const double _overhang = 30;
  static const double _featuredSize = 58;
  static const double _notchRadius = _featuredSize / 2 + 8;
  static const double _notchFillet = 10;
  static const double _corner = 28;
  static const double _maxWidth = 560;

  void _handleTap(int index, {required bool featured}) {
    if (index != currentIndex) {
      if (featured) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final count = items.length;
    final selectedIndex = math.max(0, math.min(currentIndex, count - 1));

    final fi = featuredIndex;
    final int? featured = (fi != null && fi >= 0 && fi < count) ? fi : null;
    final overhang = featured != null ? _overhang : 0.0;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, (1 - v) * 20),
                child: child,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: _barHeight + overhang,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cell = width / count;
                  final double? notchX = featured == null
                      ? null
                      : cell * (featured + 0.5);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Dock surface; the surrounding navbar area stays
                      //    transparent because the shell extends behind it.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: overhang,
                        height: _barHeight,
                        child: CustomPaint(
                          painter: _DockPainter(
                            fill: scheme.surface,
                            border: scheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                            shadow: scheme.shadow.withValues(alpha: 0.16),
                            corner: _corner,
                            notchCenterX: notchX,
                            notchRadius: _notchRadius,
                            notchFillet: _notchFillet,
                          ),
                        ),
                      ),
                      // 2. Tabs.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: overhang,
                        height: _barHeight,
                        child: Row(
                          children: [
                            for (var i = 0; i < count; i++)
                              Expanded(
                                child: i == featured
                                    ? _FeaturedLabel(
                                        item: items[i],
                                        selected: i == selectedIndex,
                                        onTap: () =>
                                            _handleTap(i, featured: true),
                                      )
                                    : _NavTile(
                                        item: items[i],
                                        selected: i == selectedIndex,
                                        onTap: () =>
                                            _handleTap(i, featured: false),
                                      ),
                              ),
                          ],
                        ),
                      ),
                      // 3. Raised centre button (kept inside the widget bounds
                      //    so it is fully tappable).
                      if (featured != null && notchX != null)
                        Positioned(
                          left: notchX - _featuredSize / 2,
                          top: overhang - _featuredSize / 2,
                          width: _featuredSize,
                          height: _featuredSize,
                          child: _FeaturedButton(
                            item: items[featured],
                            selected: featured == selectedIndex,
                            size: _featuredSize,
                            onTap: () => _handleTap(featured, featured: true),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the dock as a single path so the notch is a real cut-out.
class _DockPainter extends CustomPainter {
  const _DockPainter({
    required this.fill,
    required this.border,
    required this.shadow,
    required this.corner,
    required this.notchCenterX,
    required this.notchRadius,
    required this.notchFillet,
  });

  final Color fill;
  final Color border;
  final Color shadow;
  final double corner;
  final double? notchCenterX;
  final double notchRadius;
  final double notchFillet;

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final c = corner;

    final path = Path()
      ..moveTo(0, c)
      ..arcToPoint(Offset(c, 0), radius: Radius.circular(c));

    final cx = notchCenterX;
    if (cx != null) {
      final r = notchRadius;
      final f = notchFillet;
      // Fillet circles (radius f) are tangent to the top edge and to the
      // notch circle (radius r, centred on the top edge), so the shoulders
      // of the cut-out are perfectly smooth.
      final k = math.sqrt(r * r + 2 * r * f);
      final ratio = r / (r + f);
      final left = cx - k;
      final right = cx + k;
      if (left > c && right < w - c) {
        path
          ..lineTo(left, 0)
          ..arcToPoint(
            Offset(cx - k * ratio, f * ratio),
            radius: Radius.circular(f),
          )
          ..arcToPoint(
            Offset(cx + k * ratio, f * ratio),
            radius: Radius.circular(r),
            clockwise: false,
          )
          ..arcToPoint(Offset(right, 0), radius: Radius.circular(f));
      }
    }

    path
      ..lineTo(w - c, 0)
      ..arcToPoint(Offset(w, c), radius: Radius.circular(c))
      ..lineTo(w, h - c)
      ..arcToPoint(Offset(w - c, h), radius: Radius.circular(c))
      ..lineTo(c, h)
      ..arcToPoint(Offset(0, h - c), radius: Radius.circular(c))
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_DockPainter old) {
    return old.fill != fill ||
        old.border != border ||
        old.shadow != shadow ||
        old.corner != corner ||
        old.notchCenterX != notchCenterX ||
        old.notchRadius != notchRadius ||
        old.notchFillet != notchFillet;
  }
}

/// Regular tab: icon in a growing capsule + label.
class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AnimatedBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final selected = widget.selected;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: selected ? 52 : 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _NavIcon(
                  item: item,
                  selected: selected,
                  color: color,
                  size: 22,
                  badgeBorderColor: scheme.surface,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The label that sits under the raised button (aligned with other labels).
class _FeaturedLabel extends StatelessWidget {
  const _FeaturedLabel({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AnimatedBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same height as the capsule (30) + gap (4) of a regular tile.
            const SizedBox(height: 34),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raised circular centre button with a pulsing halo while selected.
class _FeaturedButton extends StatefulWidget {
  const _FeaturedButton({
    required this.item,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final AnimatedBottomNavItem item;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  State<_FeaturedButton> createState() => _FeaturedButtonState();
}

class _FeaturedButtonState extends State<_FeaturedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _FeaturedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.selected && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  Widget _halo(ColorScheme scheme, double phase) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = (_pulse.value + phase) % 1.0;
        final t = Curves.easeOut.transform(v);
        return Opacity(
          opacity: (1 - t) * 0.30,
          child: Transform.scale(
            scale: 1 + 0.55 * t,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (selected && !reduceMotion) ...[
              _halo(scheme, 0),
              _halo(scheme, 0.5),
            ],
            AnimatedScale(
              scale: _pressed ? 0.92 : (selected ? 1.06 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: widget.size,
                height: widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: selected ? 0.45 : 0.30,
                      ),
                      blurRadius: selected ? 22 : 16,
                      offset: Offset(0, selected ? 9 : 6),
                    ),
                  ],
                ),
                child: _NavIcon(
                  item: widget.item,
                  selected: selected,
                  color: scheme.onPrimary,
                  size: 28,
                  badgeBorderColor: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon with colour tween, elastic pop on activation and an optional badge.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.item,
    required this.selected,
    required this.color,
    required this.size,
    required this.badgeBorderColor,
  });

  final AnimatedBottomNavItem item;
  final bool selected;
  final Color color;
  final double size;
  final Color badgeBorderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = item.badgeCount;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (context, animatedColor, _) {
        // Re-keyed on selection so the elastic pop replays every time the
        // item becomes active. Deselecting starts and ends at 1.0 (no pop).
        return TweenAnimationBuilder<double>(
          key: ValueKey<bool>(selected),
          tween: Tween<double>(begin: selected ? 0.55 : 1.0, end: 1.0),
          duration: const Duration(milliseconds: 560),
          curve: Curves.elasticOut,
          builder: (context, scale, _) {
            return Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: size,
                    color: animatedColor,
                  ),
                  if (badge != null)
                    PositionedDirectional(
                      top: -6,
                      end: -8,
                      child: AnimatedScale(
                        scale: badge > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: badgeBorderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: TextStyle(
                              color: scheme.onError,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
