import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Design tokens used across the food-delivery screen system.
/// Centralised here so every screen (home, restaurant, item details, cart,
/// rider dashboard) shares the exact same professional, gradient-free palette
/// and motion language. Safe to import from any of the other screen files.
/// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Brand — a deep, confident maroon/red. Flat, never gradient.
  static const Color primary = Color(0xFFA6150B);
  static const Color primaryDark = Color(0xFF7A0F07);
  static const Color primarySoft = Color(0xFFFCE9E5);

  // Neutrals
  static const Color ink = Color(0xFF1D1913);
  static const Color inkMuted = Color(0xFF6B6259);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAF7F3);
  static const Color border = Color(0xFFE9E2D8);
  static const Color divider = Color(0xFFEFEAE2);

  // Status
  static const Color success = Color(0xFF1E7A46);
  static const Color warning = Color(0xFFB4791F);
  static const Color danger = Color(0xFFB3261E);

  static const Color star = Color(0xFFC8871A);

  // Secondary accent — used for "verified", eco/veg, delivery-positive states.
  // Flat teal, never mixed into a gradient.
  static const Color teal = Color(0xFF00765B);
  static const Color tealSoft = Color(0xFFE8F4EF);
  static const Color tealSoft2 = Color(0xFFEAF5F0);
  static const Color tealDeep = Color(0xFF153B31);
  static const Color tealDeepest = Color(0xFF12211C);
  static const Color tealMuted = Color(0xFFCFE7DC);

  static const Color amber = Color(0xFFFF9F1C);
  static const Color amberSoft = Color(0xFFFFF4E5);
  static const Color orange = Color(0xFFF97316);

  // Extra neutrals used across the wider screen system (dashboards, orders).
  static const Color ink2 = Color(0xFF17251F);
  static const Color ink3 = Color(0xFF1F2937);
  static const Color inkSoftBrown = Color(0xFF39150D);
  static const Color inkMuted2 = Color(0xFF6B7280);
  static const Color inkMuted3 = Color(0xFF374151);
  static const Color inkMuted4 = Color(0xFF9CA3AF);
  static const Color inkMuted5 = Color(0xFF68746E);
  static const Color inkMuted6 = Color(0xFF9BA6A0);
  static const Color inkMuted7 = Color(0xFF9AA59F);
  static const Color inkMuted8 = Color(0xFF6B756F);

  static const Color border2 = Color(0xFFE5E7EB);
  static const Color border3 = Color(0xFFE2E8E2);
  static const Color peach = Color(0xFFFFD7C2);

  static const Color surfaceAlt2 = Color(0xFFF9FAFB);
  static const Color surfaceAlt3 = Color(0xFFF9FBF8);
  static const Color surfaceAlt4 = Color(0xFFF6F8F5);
  static const Color surfaceAlt5 = Color(0xFFF3F6F4);

  static const Color dangerDeep = Color(0xFF7F1D1D);
}

/// ---------------------------------------------------------------------------
/// Shared motion widgets
/// ---------------------------------------------------------------------------
/// Reused across every screen in the module so entrance/press animation feel
/// identical everywhere. Intentionally lightweight: a fade+rise entrance for
/// content appearing on screen (cards in a list, sections on first build) and
/// a press-scale wrapper for anything tappable that doesn't already have its
/// own animation. No gradients, no non-user-triggered looping effects other
/// than the one restrained shimmer used for image loading.

/// Fades and rises a child into place. Give list items an increasing [index]
/// so a scrolling list staggers in, one after another, instead of popping in
/// all at once.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerIndex = const Duration(milliseconds: 45),
    this.offset = 14,
    this.duration = AppMotion.slow,
  });

  final Widget child;
  final int index;
  final Duration delayPerIndex;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    final delay = widget.delayPerIndex * widget.index.clamp(0, 12);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _curve.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps any tappable content with a subtle, professional press-scale so
/// every card and button in the module responds the same way to touch.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.035,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (_controller.value * widget.scaleAmount);
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// A flat, professional "count up" style animated number — used for stat
/// cards, totals, and badge counters so a changing value doesn't just snap.
class AnimatedCountLabel extends StatelessWidget {
  const AnimatedCountLabel({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AppMotion.slow,
      curve: AppMotion.enter,
      builder: (context, v, child) {
        final display = value == value.roundToDouble()
            ? v.round().toString()
            : v.toStringAsFixed(1);
        return Text('$prefix$display$suffix', style: style);
      },
    );
  }
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

class AppShadow {
  AppShadow._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.10),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
  static const Curve pop = Curves.easeOutBack;
}

/// ---------------------------------------------------------------------------
/// FoodProductCard
/// ---------------------------------------------------------------------------
/// Same public API as before (item / onTap / onRestaurantTap / onAdd) — no
/// functionality removed — rebuilt as a StatefulWidget so it can carry a
/// press-scale interaction, a staggered entrance for its badge/price row,
/// an image cross-fade, and a satisfying "add" micro-animation on the button.
/// ---------------------------------------------------------------------------
/// FoodProductCard
/// ---------------------------------------------------------------------------
/// A from-scratch take on the product card: a full-bleed photo up top with
/// a circular "add" button floating half on/half off its bottom-right
/// corner (so it always reads as the primary action, no matter what's in
/// the photo), a slim corner tag for promo/popular badges, and a clean two
/// line text block below. Flat colours only, generous whitespace, and every
/// interactive piece carries its own small, purposeful animation. Same
/// public API as before (item / onTap / onRestaurantTap / onAdd) — nothing
/// about how this widget is *used* elsewhere has changed.
class FoodProductCard extends StatefulWidget {
  const FoodProductCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRestaurantTap,
    required this.onAdd,
    this.heroTagPrefix = 'food-image',
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback? onRestaurantTap;
  final ValueChanged<BuildContext> onAdd;
  final String heroTagPrefix;

  @override
  State<FoodProductCard> createState() => _FoodProductCardState();
}

class _FoodProductCardState extends State<FoodProductCard>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  late final AnimationController _addButton = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );

  @override
  void dispose() {
    _entrance.dispose();
    _press.dispose();
    _addButton.dispose();
    super.dispose();
  }

  void _handleAdd(BuildContext buttonContext) {
    _addButton.forward(from: 0);
    widget.onAdd(buttonContext);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final restaurant = item['restaurant'] is Map
        ? Map<String, dynamic>.from(item['restaurant'] as Map)
        : <String, dynamic>{};
    final price = item['discount_price'] ?? item['price'];
    final oldPrice = item['discount_price'] == null ? null : item['price'];
    final isPromoted = _isTruthy(
      item['is_currently_promoted'] ?? item['is_promoted'],
    );
    final isPopular = _isTruthy(item['is_popular']);
    final promotionLabel = item['promotion_label']?.toString().trim();
    final tagLabel = isPromoted
        ? (promotionLabel == null || promotionLabel.isEmpty
              ? 'Promoted'
              : promotionLabel)
        : (isPopular ? 'জনপ্রিয়' : null);
    final tagIcon = isPromoted
        ? Icons.campaign_rounded
        : Icons.local_fire_department_rounded;
    final hasDiscount = oldPrice != null;

    final entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: AppMotion.enter,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _press]),
      builder: (context, child) {
        final rise = (1 - entranceCurve.value).clamp(0.0, 1.0) * 16;
        final pressScale = 1 - (_press.value * 0.03);
        return Opacity(
          opacity: entranceCurve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, rise),
            child: Transform.scale(scale: pressScale, child: child),
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Photo, full width, top corners only -------------------
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: Hero(
                      tag:
                          '${widget.heroTagPrefix}-${item['id'] ?? item.hashCode}',
                      flightShuttleBuilder: (_, animation, _, _, toContext) =>
                          FadeTransition(
                            opacity: animation,
                            child: toContext.widget,
                          ),
                      child: _FoodCardImage(
                        url: item['image_url']?.toString(),
                        height: 138,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  if (tagLabel != null)
                    Positioned(
                      left: 0,
                      top: 12,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.slow,
                        curve: AppMotion.pop,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          alignment: Alignment.centerLeft,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 12,
                            top: 6,
                            bottom: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(AppRadius.pill),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tagIcon, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                tagLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // ---- Floating circular add button -----------------------
                  Positioned(
                    right: 10,
                    bottom: -18,
                    child: Builder(
                      builder: (buttonContext) => AnimatedBuilder(
                        animation: _addButton,
                        builder: (context, child) {
                          final t = _addButton.value;
                          final scale = t < 0.5
                              ? 1 - (t * 0.36)
                              : 0.82 + ((t - 0.5) * 0.36);
                          final spin = t * 0.55;
                          return Transform.rotate(
                            angle: t == 0 ? 0 : spin,
                            child: Transform.scale(
                              scale: t == 0 ? 1 : scale,
                              child: child,
                            ),
                          );
                        },
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          elevation: 0,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _handleAdd(buttonContext),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 3,
                                ),
                                boxShadow: AppShadow.raised,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ---- Text block -----------------------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 44, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: widget.onRestaurantTap,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  color: AppColors.inkMuted,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    restaurant['name']?.toString() ??
                                        'রেস্টুরেন্ট',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['name']?.toString() ?? 'খাবার',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '৳$price',
                            style: TextStyle(
                              color: hasDiscount
                                  ? AppColors.primary
                                  : AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '৳$oldPrice',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isTruthy(dynamic value) {
  if (value == true || value == 1) return true;
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}

/// Image with a soft shimmer placeholder and a smooth cross-fade once loaded,
/// instead of popping straight in.
class _FoodCardImage extends StatelessWidget {
  const _FoodCardImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  Widget _placeholder({bool shimmer = false}) {
    final base = Container(
      width: width,
      height: height,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: 34,
        color: AppColors.border,
      ),
    );
    if (!shimmer) return base;
    return AppShimmer(width: width, height: height, child: base);
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return AnimatedSwitcher(duration: AppMotion.base, child: child);
        }
        return _placeholder(shimmer: true);
      },
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}

/// A restrained, professional shimmer sweep for image loading states —
/// flat neutral tones, no gradient color mixing, just an opacity sweep.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    required this.width,
    required this.height,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + (_controller.value * 0.35),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
