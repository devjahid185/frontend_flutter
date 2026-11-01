import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/bangladesh_time.dart';
import '../../core/widgets/location_picker_screen.dart';

const _gasRed = Color(0xFFD91F2A);
const _gasInk = Color(0xFF17212B);
const _gasBg = Color(0xFFF5F7F8);
const _gasLine = Color(0xFFE5E9EC);
const _gasMuted = Color(0xFF6B7782);
const _gasGreen = Color(0xFF16A34A);
const _gasAmber = Color(0xFFD97706);

double _number(dynamic value) => double.tryParse('$value') ?? 0;
int _integer(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}'.trim()) ?? 0;
}

bool _truthy(dynamic value) {
  if (value == true || value == 1) return true;
  final normalized = '${value ?? ''}'.trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

String _money(dynamic value) =>
    '৳${_number(value).toStringAsFixed(_number(value) % 1 == 0 ? 0 : 2)}';

String _statusText(dynamic status) => '$status'.replaceAll('_', ' ');

void _toast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? _gasRed : _gasInk,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/* ===========================================================================
   Shared animated building blocks
   =========================================================================== */

/// Fade + slide-up entrance when the widget is first built.
class _Entrance extends StatelessWidget {
  const _Entrance({
    super.key,
    required this.child,
    this.delay = 0,
    this.dy = 18,
  });

  final Widget child;
  final int delay;
  final double dy;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = 520 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * dy),
          child: child,
        ),
      ),
    );
  }
}

/// Press-to-shrink surface with ripple and a light haptic tick.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onTap,
    required this.child,
    this.radius = 18,
    this.color,
    this.border,
    this.scale = 0.96,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final Color? color;
  final BorderSide? border;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      side: widget.border ?? BorderSide.none,
    );
    return AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.color ?? Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onHighlightChanged: (v) => setState(() => _down = v),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Flat pulsing placeholder block.
class _Skeleton extends StatefulWidget {
  const _Skeleton({this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE9EDF0),
            const Color(0xFFDDE3E7),
            Curves.easeInOut.transform(_c.value),
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Money text that counts to its new value whenever it changes.
class _AnimatedMoney extends StatelessWidget {
  const _AnimatedMoney({required this.value, this.style, this.prefix = ''});

  final double value;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${_money(v.roundToDouble())}', style: style),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 180),
      child: _Pressable(
        onTap: enabled ? onTap : null,
        radius: size,
        scale: 0.85,
        color: Colors.white,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.52, color: _gasRed),
        ),
      ),
    );
  }
}

/// Pill stepper with an animated number.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 36.0;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8EA),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: value > min,
            size: size,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: compact ? 30 : 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 15 : 17,
                  color: _gasInk,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            size: size,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

/// Colour-coded order status chip.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.onDark = false});

  final dynamic status;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final s = '$status'.toLowerCase();
    Color color;
    if (s.contains('cancel') || s.contains('reject') || s.contains('fail')) {
      color = _gasRed;
    } else if (s.contains('deliver') || s.contains('complete')) {
      color = _gasGreen;
    } else if (s.contains('pending') || s.contains('wait')) {
      color = _gasAmber;
    } else {
      color = const Color(0xFF2563EB);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _statusText(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingIcon(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: _gasRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: _gasRed),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: _gasInk,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _gasMuted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gasRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gentle idle bob used on hero icons and empty states.
class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.child});

  final Widget child;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -5 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}

class _GasImage extends StatelessWidget {
  const _GasImage({this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty || u == 'null') return const _GasPlaceholder();
    return Image.network(
      u,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (_, error, stackTrace) => const _GasPlaceholder(),
    );
  }
}

class _GasPlaceholder extends StatelessWidget {
  const _GasPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF1F3F4),
    alignment: Alignment.center,
    child: const Icon(Icons.propane_tank_rounded, size: 56, color: _gasRed),
  );
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.index = 0,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      delay: index * 70,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gasLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _gasRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: _gasRed),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _gasInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/* ===========================================================================
   Gas home
   =========================================================================== */

class GasDeliveryScreen extends StatefulWidget {
  const GasDeliveryScreen({super.key});
  @override
  State<GasDeliveryScreen> createState() => _GasDeliveryScreenState();
}

class _GasDeliveryScreenState extends State<GasDeliveryScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _home = {};
  String? _brand;

  List<dynamic> get _products {
    final query = _search.text.trim().toLowerCase();
    return List<dynamic>.from(_home['products'] as List? ?? []).where((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final matchesBrand = _brand == null || p['brand'] == _brand;
      final text = '${p['brand']} ${p['name']} ${p['weight_kg']}'.toLowerCase();
      return matchesBrand && (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// [silent] keeps the current content on screen while refreshing.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _api.get('/gas/home');
      if (mounted) {
        setState(() {
          _home = Map<String, dynamic>.from(data as Map);
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_home.isEmpty) {
        setState(() => _error = '$e');
      } else {
        _toast(context, '$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProduct(Map<String, dynamic> product) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GasProductSheet(product: product, api: _api),
    );
    if (added == true) {
      if (mounted) _toast(context, 'কার্টে যোগ করা হয়েছে');
      _load(silent: true);
    }
  }

  Future<void> _openCart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GasCartScreen()));
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _integer(_home['cart_count']);
    return Scaffold(
      backgroundColor: _gasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'গ্যাস সিলিন্ডার',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            Text(
              'নিরাপদ ডেলিভারি, যাচাইকৃত ডিলার',
              style: TextStyle(fontSize: 11, color: _gasMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GasOrdersScreen())),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'আমার অর্ডার',
          ),
          _CartButton(count: cartCount, onPressed: _openCart),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _gasLine),
        ),
      ),
      body: RefreshIndicator(
        color: _gasRed,
        onRefresh: () => _load(silent: true),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
        ),
        child: cartCount > 0
            ? SafeArea(
                key: const ValueKey('cart-bar'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: _Pressable(
                    onTap: _openCart,
                    radius: 18,
                    scale: 0.97,
                    color: _gasRed,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'কার্ট দেখুন · $cartCountটি',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('no-cart')),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _GasHomeSkeleton(key: ValueKey('loading'));
    }
    if (_error != null) {
      return CustomScrollView(
        key: const ValueKey('error'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: _StateMessage(
                icon: Icons.cloud_off_rounded,
                title: 'লোড করা যায়নি',
                subtitle: _error,
                actionLabel: 'আবার চেষ্টা করুন',
                onAction: _load,
              ),
            ),
          ),
        ],
      );
    }
    if (!_truthy(_home['enabled'])) {
      return CustomScrollView(
        key: const ValueKey('disabled'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: _StateMessage(
                icon: Icons.propane_tank_outlined,
                title: 'গ্যাস ডেলিভারি সাময়িকভাবে বন্ধ আছে',
                subtitle: 'কিছুক্ষণ পর আবার চেষ্টা করুন',
              ),
            ),
          ),
        ],
      );
    }

    final settings = Map<String, dynamic>.from(_home['settings'] as Map? ?? {});
    final brands = List<dynamic>.from(_home['brands'] as List? ?? []);
    final products = _products;
    final gridKey = '$_brand|${_search.text.trim()}';

    return CustomScrollView(
      key: const ValueKey('content'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _Entrance(child: _GasHero(settings: settings)),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedDelegate(
            height: 118,
            child: _FilterBar(
              controller: _search,
              brands: brands,
              selected: _brand,
              onSearch: () => setState(() {}),
              onBrand: (b) => setState(() => _brand = b),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'সিলিন্ডারসমূহ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _gasRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      '${products.length}টি',
                      key: ValueKey(products.length),
                      style: const TextStyle(
                        color: _gasRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: _StateMessage(
                icon: Icons.search_off_rounded,
                title: 'কোনো সিলিন্ডার পাওয়া যায়নি',
                subtitle: 'অন্য ব্র্যান্ড বা নাম দিয়ে খুঁজুন',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((_, i) {
                final p = Map<String, dynamic>.from(products[i] as Map);
                return _Entrance(
                  key: ValueKey('$gridKey#${p['id']}#$i'),
                  delay: math.min(i, 8) * 55,
                  child: _GasProductCard(
                    product: p,
                    onTap: () => _openProduct(p),
                  ),
                );
              }, childCount: products.length),
            ),
          ),
      ],
    );
  }
}

class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: _gasBg,
      elevation: overlapsContent ? 3 : 0,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedDelegate oldDelegate) => true;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.brands,
    required this.selected,
    required this.onSearch,
    required this.onBrand,
  });

  final TextEditingController controller;
  final List<dynamic> brands;
  final String? selected;
  final VoidCallback onSearch;
  final ValueChanged<String?> onBrand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: controller,
                onChanged: (_) => onSearch(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ব্র্যান্ড বা সিলিন্ডার খুঁজুন',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: controller.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: () {
                              controller.clear();
                              onSearch();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _gasLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _gasLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _gasRed, width: 1.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              children: [
                _BrandChip(
                  label: 'সব',
                  selected: selected == null,
                  onTap: () => onBrand(null),
                ),
                ...brands.map(
                  (b) => _BrandChip(
                    label: '$b',
                    selected: selected == '$b',
                    onTap: () => onBrand('$b'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _gasInk : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? _gasInk : _gasLine),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            style: TextStyle(
              color: selected ? Colors.white : _gasInk,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatefulWidget {
  const _CartButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _CartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onPressed,
      tooltip: 'কার্ট',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) {
              final t = _bounce.value;
              final s = 1 + 0.35 * math.sin(t * math.pi) * (1 - t);
              return Transform.scale(scale: s, child: child);
            },
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: AnimatedScale(
              scale: widget.count > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: _gasRed,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GasHero extends StatelessWidget {
  const _GasHero({required this.settings});

  final Map<String, dynamic> settings;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: _gasInk,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            const Positioned(
              right: -50,
              top: -60,
              child: _Disc(size: 170, alpha: 0.06),
            ),
            const Positioned(
              right: 60,
              bottom: -60,
              child: _Disc(size: 110, alpha: 0.05),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _FloatingIcon(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _gasRed,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.propane_tank_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'নতুন সিলিন্ডার বা রিফিল',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${settings['service_notice'] ?? 'বাসায় পৌঁছে যাবে নিরাপদ গ্যাস সিলিন্ডার'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrustChip(
                      icon: Icons.verified_rounded,
                      label: 'যাচাইকৃত ডিলার',
                    ),
                    _TrustChip(
                      icon: Icons.shield_rounded,
                      label: 'নিরাপদ ডেলিভারি',
                    ),
                    _TrustChip(
                      icon: Icons.bolt_rounded,
                      label: 'জরুরি ডেলিভারি',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GasHomeSkeleton extends StatelessWidget {
  const _GasHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const _Skeleton(height: 150, radius: 24),
        const SizedBox(height: 16),
        const _Skeleton(height: 50, radius: 16),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            4,
            (i) => const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _Skeleton(height: 36, width: 70, radius: 99),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: _Skeleton(height: 250, radius: 18)),
            SizedBox(width: 12),
            Expanded(child: _Skeleton(height: 250, radius: 18)),
          ],
        ),
      ],
    );
  }
}

/* ===========================================================================
   Product card
   =========================================================================== */

class _GasProductCard extends StatelessWidget {
  const _GasProductCard({required this.product, required this.onTap});
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = product['image_url']?.toString();
    return _Pressable(
      onTap: onTap,
      radius: 20,
      color: Colors.white,
      border: const BorderSide(color: _gasLine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _GasImage(url: image),
                if (product['is_promoted'] == true)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _gasRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'জনপ্রিয়',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product['weight_kg']} কেজি',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _gasInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product['brand']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _gasRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${product['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _gasInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'রিফিল ${_money(product['refill_price'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: _gasInk,
                        ),
                      ),
                      Text(
                        'নতুন ${_money(product['new_cylinder_price'])}',
                        style: const TextStyle(fontSize: 11, color: _gasMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _gasRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===========================================================================
   Product bottom sheet
   =========================================================================== */

class _GasProductSheet extends StatefulWidget {
  const _GasProductSheet({required this.product, required this.api});
  final Map<String, dynamic> product;
  final ApiClient api;
  @override
  State<_GasProductSheet> createState() => _GasProductSheetState();
}

class _GasProductSheetState extends State<_GasProductSheet> {
  String _type = 'refill';
  int _qty = 1;
  int _empty = 1;
  bool _saving = false;

  Future<void> _add() async {
    setState(() => _saving = true);
    try {
      await widget.api.post(
        '/gas/cart/items',
        body: {
          'product_id': widget.product['id'],
          'purchase_type': _type,
          'quantity': _qty,
          'empty_return_quantity': _type == 'refill' ? _empty : 0,
        },
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setType(String value) {
    if (_type == value) return;
    setState(() {
      _type = value;
      _empty = _type == 'refill' ? _qty : 0;
    });
  }

  void _setQty(int value) {
    setState(() {
      final up = value > _qty;
      _qty = value;
      if (!up && _empty > _qty) _empty = _qty;
      if (up && _type == 'refill') _empty = _qty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final deposit = _number(p['security_deposit']);
    final newUnit = _number(p['new_cylinder_price']) + deposit;
    final refillUnit = _number(p['refill_price']);
    final unit = _type == 'new' ? newUnit : refillUnit;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        10 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Entrance(
                dy: 10,
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _GasImage(url: p['image_url']?.toString()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['brand']} ${p['name']}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _gasInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p['weight_kg']} কেজি · ${p['dealer']?['name'] ?? ''}',
                            style: const TextStyle(color: _gasMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      selected: _type == 'refill',
                      icon: Icons.autorenew_rounded,
                      title: 'রিফিল / এক্সচেঞ্জ',
                      price: _money(refillUnit),
                      onTap: () => _setType('refill'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeCard(
                      selected: _type == 'new',
                      icon: Icons.add_box_outlined,
                      title: 'নতুন সিলিন্ডার',
                      price: _money(newUnit),
                      onTap: () => _setType('new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _type == 'new'
                      ? (deposit > 0
                            ? _InfoBox(
                                key: const ValueKey('deposit'),
                                color: Colors.amber,
                                icon: Icons.info_outline_rounded,
                                text:
                                    'নতুন সিলিন্ডারের দামের সঙ্গে প্রতি সিলিন্ডারে ${_money(p['security_deposit'])} নিরাপত্তা জামানত যোগ হবে।',
                              )
                            : const SizedBox.shrink(key: ValueKey('nodep')))
                      : _InfoBox(
                          key: const ValueKey('empty'),
                          color: Colors.blueGrey,
                          icon: Icons.recycling_rounded,
                          text:
                              'ডেলিভারির সময় ${_empty}টি খালি সিলিন্ডার ফেরত দেবেন।',
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'পরিমাণ',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const Spacer(),
                  _QtyStepper(value: _qty, min: 1, max: 10, onChanged: _setQty),
                ],
              ),
              const SizedBox(height: 16),
              _Pressable(
                onTap: _saving ? null : _add,
                radius: 16,
                scale: 0.97,
                color: _saving ? _gasRed.withValues(alpha: 0.7) : _gasRed,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _saving
                        ? const Row(
                            key: ValueKey('saving'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'যোগ হচ্ছে...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'কার্টে যোগ করুন · ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              _AnimatedMoney(
                                value: unit * _qty,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.price,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _gasRed.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _gasRed : _gasLine,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: selected ? _gasRed : _gasMuted),
                const Spacer(),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: _gasRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? _gasRed : _gasInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: _gasInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  final MaterialColor color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: color.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===========================================================================
   Cart
   =========================================================================== */

class GasCartScreen extends StatefulWidget {
  const GasCartScreen({super.key});
  @override
  State<GasCartScreen> createState() => _GasCartScreenState();
}

class _GasCartScreenState extends State<GasCartScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get('/gas/cart');
      if (mounted) {
        setState(() => _cart = Map<String, dynamic>.from(data as Map));
      }
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(Map<String, dynamic> item, int qty) async {
    if (qty < 1) return;
    try {
      await _api.post(
        '/gas/cart/items/${item['id']}',
        body: {
          'quantity': qty,
          'empty_return_quantity': item['purchase_type'] == 'refill' ? qty : 0,
        },
      );
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    }
    await _load(silent: true);
  }

  Future<void> _remove(int id) async {
    try {
      await _api.delete('/gas/cart/items/$id');
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    }
    await _load(silent: true);
  }

  /// Removes the row from the local list right away (required by Dismissible),
  /// then syncs with the server.
  void _dismiss(int id) {
    setState(() {
      _cart = {
        ..._cart,
        'items': List<dynamic>.from(
          _cart['items'] as List? ?? [],
        ).where((r) => _integer((r as Map)['id']) != id).toList(),
      };
    });
    _remove(id);
  }

  Future<void> _checkout() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GasCheckoutScreen(cart: _cart)),
    );
    if (done == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = List<dynamic>.from(_cart['items'] as List? ?? []);
    final total = _number(_cart['items_total']);
    return Scaffold(
      backgroundColor: _gasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Text(
              'সিলিন্ডার কার্ট',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _gasRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${items.length}টি',
                  style: const TextStyle(
                    color: _gasRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _gasLine),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? ListView(
                key: const ValueKey('loading'),
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _Skeleton(height: 96, radius: 20),
                  ),
                ),
              )
            : items.isEmpty
            ? Center(
                key: const ValueKey('empty'),
                child: _StateMessage(
                  icon: Icons.shopping_bag_outlined,
                  title: 'কার্ট খালি',
                  subtitle: 'পছন্দের সিলিন্ডার কার্টে যোগ করুন',
                  actionLabel: 'সিলিন্ডার দেখুন',
                  onAction: () => Navigator.pop(context),
                ),
              )
            : RefreshIndicator(
                key: const ValueKey('list'),
                color: _gasRed,
                onRefresh: () => _load(silent: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _Entrance(
                        key: ValueKey('c${_integer((items[i] as Map)['id'])}'),
                        delay: math.min(i, 6) * 60,
                        child: _cartTile(
                          Map<String, dynamic>.from(items[i] as Map),
                        ),
                      ),
                    _Entrance(
                      delay: 120,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gasLine),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'পণ্যের মোট',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                _AnimatedMoney(
                                  value: total,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                    color: _gasInk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 16,
                                  color: _gasMuted,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ডেলিভারি চার্জ চেকআউটে যোগ হবে',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _gasMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _Pressable(
                  onTap: _checkout,
                  radius: 18,
                  scale: 0.97,
                  color: _gasRed,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'চেকআউট করুন',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _cartTile(Map<String, dynamic> item) {
    final p = Map<String, dynamic>.from(item['product'] as Map);
    final id = _integer(item['id']);
    final qty = _integer(item['quantity']);
    final isRefill = item['purchase_type'] == 'refill';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss-$id'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _dismiss(id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: _gasRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gasLine),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _GasImage(url: p['image_url']?.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['brand']} ${p['name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _gasInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isRefill
                            ? const Color(0xFFE8F1FB)
                            : const Color(0xFFFDF3E1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        isRefill ? 'রিফিল / এক্সচেঞ্জ' : 'নতুন সিলিন্ডার',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isRefill ? const Color(0xFF1D4ED8) : _gasAmber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _AnimatedMoney(
                          value: _number(item['total_price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _gasRed,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        _QtyStepper(
                          value: qty,
                          compact: true,
                          onChanged: (v) => _change(item, v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===========================================================================
   Checkout
   =========================================================================== */

InputDecoration _gasDecoration(String label, IconData icon, {String? error}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    errorText: error,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: const Color(0xFFF8FAFB),
    border: border(_gasLine),
    enabledBorder: border(_gasLine),
    focusedBorder: border(_gasRed, 1.6),
    errorBorder: border(_gasRed),
    focusedErrorBorder: border(_gasRed, 1.6),
  );
}

class GasCheckoutScreen extends StatefulWidget {
  const GasCheckoutScreen({super.key, required this.cart});
  final Map<String, dynamic> cart;
  @override
  State<GasCheckoutScreen> createState() => _GasCheckoutScreenState();
}

class _GasCheckoutScreenState extends State<GasCheckoutScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _trx = TextEditingController();
  final _note = TextEditingController();
  Map<String, dynamic> _settings = {};
  double? _lat, _lng;
  String? _slot;
  String _payment = 'cash_on_delivery';
  bool _emergency = false, _safety = false, _placing = false, _loading = true;
  bool _locating = false;
  bool _submitted = false;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _trx.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final home = await _api.get('/gas/home');
      if (!mounted) return;
      final s = Map<String, dynamic>.from(home['settings'] as Map? ?? {});
      setState(() {
        _settings = s;
        _name.text = prefs.getString('gas_receiver_name') ?? '';
        _phone.text = prefs.getString('gas_receiver_phone') ?? '';
        _address.text = prefs.getString('gas_delivery_address') ?? '';
        _lat = prefs.getDouble('gas_delivery_lat');
        _lng = prefs.getDouble('gas_delivery_lng');
        if (_lat != null && _lng != null) {
          _locationStatus =
              'সেভ করা লোকেশন ব্যবহার হচ্ছে: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
        }
        final slots = List<dynamic>.from(s['delivery_slots'] as List? ?? []);
        _slot = slots.isNotEmpty ? '${slots.first}' : null;
        if (!_truthy(s['cod_enabled'])) {
          _payment = _truthy(s['bkash_enabled']) ? 'bkash' : 'nagad';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(context, '$e', error: true);
    }
  }

  Future<bool> _captureCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationStatus = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(
            () => _locationStatus =
                'লোকেশন সার্ভিস বন্ধ আছে। অনুগ্রহ করে চালু করুন।',
          );
        }
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(
            () => _locationStatus =
                'লোকেশন permission দিলে ডেলিভারি লোকেশন নেওয়া যাবে।',
          );
        }
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _locationStatus =
                'লোকেশন permission permanently বন্ধ আছে। App settings থেকে চালু করুন।',
          );
        }
        await Geolocator.openAppSettings();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return false;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationStatus =
            'বর্তমান লোকেশন নেওয়া হয়েছে: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationStatus =
              'লোকেশন নেওয়া যায়নি। GPS চালু করে আবার চেষ্টা করুন।',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
          title: 'গ্যাস ডেলিভারি লোকেশন',
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _lat = picked.lat;
        _lng = picked.lng;
        _locationStatus =
            'ম্যাপ থেকে লোকেশন নেওয়া হয়েছে: ${picked.lat.toStringAsFixed(5)}, ${picked.lng.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _place() async {
    if (_lat == null || _lng == null) {
      final captured = await _captureCurrentLocation();
      if (!captured && mounted) {
        setState(() => _submitted = true);
        _toast(
          context,
          'অর্ডার করতে বর্তমান অথবা ম্যাপ লোকেশন দিন।',
          error: true,
        );
        return;
      }
    }
    if (!mounted) return;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _lat == null ||
        _lng == null ||
        !_safety) {
      HapticFeedback.heavyImpact();
      setState(() => _submitted = true);
      _toast(
        context,
        'নাম, ফোন, ঠিকানা, ম্যাপ লোকেশন ও নিরাপত্তা সম্মতি পূরণ করুন।',
        error: true,
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final data = await _api.post(
        '/gas/checkout',
        body: {
          'receiver_name': _name.text.trim(),
          'receiver_phone': _phone.text.trim(),
          'delivery_address': _address.text.trim(),
          'delivery_lat': _lat,
          'delivery_lng': _lng,
          'delivery_date': BangladeshTime.todayIso(),
          'delivery_slot': _slot,
          'is_emergency': _emergency,
          'payment_method': _payment,
          'manual_transaction_id': _trx.text.trim().isEmpty
              ? null
              : _trx.text.trim(),
          'order_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          'safety_confirmed': true,
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gas_receiver_name', _name.text.trim());
      await prefs.setString('gas_receiver_phone', _phone.text.trim());
      await prefs.setString('gas_delivery_address', _address.text.trim());
      await prefs.setDouble('gas_delivery_lat', _lat!);
      await prefs.setDouble('gas_delivery_lng', _lng!);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final order = Map<String, dynamic>.from(data['order'] as Map);
      Navigator.of(context)
          .pushReplacement(
            MaterialPageRoute(
              builder: (_) => GasOrderDetailsScreen(
                orderId: (order['id'] as num).toInt(),
                initial: order,
              ),
            ),
          )
          .then((_) {
            if (mounted) Navigator.pop(context, true);
          });
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  String? _err(TextEditingController c) =>
      _submitted && c.text.trim().isEmpty ? 'এই তথ্যটি দিন' : null;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _gasBg,
        appBar: AppBar(title: const Text('অর্ডার নিশ্চিত করুন')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _Skeleton(height: 240, radius: 20),
            SizedBox(height: 14),
            _Skeleton(height: 150, radius: 20),
            SizedBox(height: 14),
            _Skeleton(height: 150, radius: 20),
          ],
        ),
      );
    }
    final slots = List<dynamic>.from(
      _settings['delivery_slots'] as List? ?? [],
    );
    final itemsTotal = _number(widget.cart['items_total']);
    final double delivery =
        _settings['free_delivery_min_order'] != null &&
            itemsTotal >= _number(_settings['free_delivery_min_order'])
        ? 0.0
        : _number(_settings['fixed_delivery_fee']);
    final double emergencyFee = _emergency
        ? _number(_settings['emergency_fee'])
        : 0.0;
    final grand = itemsTotal + delivery + emergencyFee;
    final payNumber = _payment == 'bkash'
        ? '${_settings['bkash_number'] ?? ''}'
        : '${_settings['nagad_number'] ?? ''}';

    return Scaffold(
      backgroundColor: _gasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        title: const Text(
          'অর্ডার নিশ্চিত করুন',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _gasLine),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _SectionCard(
            index: 0,
            title: 'ডেলিভারি তথ্য',
            icon: Icons.person_pin_circle_outlined,
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _submitted ? setState(() {}) : null,
                  decoration: _gasDecoration(
                    'নাম',
                    Icons.person_outline_rounded,
                    error: _err(_name),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _submitted ? setState(() {}) : null,
                  decoration: _gasDecoration(
                    'চালু মোবাইল নম্বর',
                    Icons.phone_outlined,
                    error: _err(_phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  onChanged: (_) => _submitted ? setState(() {}) : null,
                  decoration: _gasDecoration(
                    'সম্পূর্ণ ঠিকানা',
                    Icons.home_outlined,
                    error: _err(_address),
                  ),
                ),
                const SizedBox(height: 12),
                _LocationButton(
                  hasLocation: _lat != null && _lng != null,
                  showError: _submitted && (_lat == null || _lng == null),
                  locating: _locating,
                  status: _locationStatus,
                  onCurrentLocation: _captureCurrentLocation,
                  onTap: _pickMap,
                ),
              ],
            ),
          ),
          _SectionCard(
            index: 1,
            title: 'ডেলিভারি সময়',
            icon: Icons.schedule_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slots.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in slots)
                        _OptionChip(
                          label: '$s',
                          selected: _slot == '$s',
                          onTap: () => setState(() => _slot = '$s'),
                        ),
                    ],
                  ),
                if (slots.isNotEmpty) const SizedBox(height: 14),
                _EmergencyTile(
                  value: _emergency,
                  fee: _money(_settings['emergency_fee']),
                  onChanged: (v) => setState(() => _emergency = v),
                ),
              ],
            ),
          ),
          _SectionCard(
            index: 2,
            title: 'পেমেন্ট',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_truthy(_settings['cod_enabled']))
                  _PayTile(
                    selected: _payment == 'cash_on_delivery',
                    icon: Icons.payments_outlined,
                    title: 'ক্যাশ অন ডেলিভারি',
                    subtitle: 'সিলিন্ডার হাতে পেয়ে টাকা দিন',
                    onTap: () => setState(() => _payment = 'cash_on_delivery'),
                  ),
                if (_truthy(_settings['bkash_enabled']))
                  _PayTile(
                    selected: _payment == 'bkash',
                    icon: Icons.phone_android_rounded,
                    title: 'বিকাশ',
                    subtitle: 'Send Money করে ট্রানজেকশন আইডি দিন',
                    onTap: () => setState(() => _payment = 'bkash'),
                  ),
                if (_truthy(_settings['nagad_enabled']))
                  _PayTile(
                    selected: _payment == 'nagad',
                    icon: Icons.phone_android_rounded,
                    title: 'নগদ',
                    subtitle: 'Send Money করে ট্রানজেকশন আইডি দিন',
                    onTap: () => setState(() => _payment = 'nagad'),
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _payment == 'cash_on_delivery'
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                                decoration: BoxDecoration(
                                  color: _gasRed.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Send Money: $payNumber',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _gasInk,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'নম্বর কপি করুন',
                                      onPressed: payNumber.isEmpty
                                          ? null
                                          : () {
                                              Clipboard.setData(
                                                ClipboardData(text: payNumber),
                                              );
                                              _toast(
                                                context,
                                                'নম্বর কপি হয়েছে',
                                              );
                                            },
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 19,
                                        color: _gasRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _trx,
                                decoration: _gasDecoration(
                                  'ট্রানজেকশন আইডি',
                                  Icons.tag_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          _SectionCard(
            index: 3,
            title: 'অর্ডার নোট',
            icon: Icons.edit_note_rounded,
            child: TextField(
              controller: _note,
              maxLines: 3,
              decoration: _gasDecoration(
                'বিশেষ কোনো নির্দেশনা থাকলে লিখুন',
                Icons.notes_rounded,
              ),
            ),
          ),
          _Entrance(
            delay: 280,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _submitted && !_safety
                      ? _gasRed
                      : Colors.orange.shade200,
                  width: _submitted && !_safety ? 1.8 : 1,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _gasRed,
                value: _safety,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _safety = v == true);
                },
                title: const Text(
                  'নিরাপত্তা নির্দেশনা বুঝেছি',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${_settings['safety_notice'] ?? ''}',
                  style: const TextStyle(height: 1.35, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Entrance(
            delay: 340,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gasLine),
              ),
              child: Column(
                children: [
                  _summary('পণ্যের মোট', itemsTotal),
                  _summary('ডেলিভারি চার্জ', delivery),
                  _summary('জরুরি ডেলিভারি', emergencyFee),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: _gasLine),
                  ),
                  _summary('সর্বমোট', grand, strong: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _Pressable(
            onTap: _placing ? null : _place,
            radius: 18,
            scale: 0.97,
            color: _placing ? _gasRed.withValues(alpha: 0.7) : _gasRed,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _placing
                    ? const Row(
                        key: ValueKey('placing'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'অর্ডার হচ্ছে...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('place'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'অর্ডার নিশ্চিত করুন · ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          _AnimatedMoney(
                            value: grand,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, double value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            color: strong ? _gasInk : _gasMuted,
          ),
        ),
        _AnimatedMoney(
          value: value,
          style: TextStyle(
            fontSize: strong ? 20 : 14,
            fontWeight: FontWeight.w900,
            color: strong ? _gasRed : _gasInk,
          ),
        ),
      ],
    ),
  );
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.hasLocation,
    required this.showError,
    required this.locating,
    required this.status,
    required this.onCurrentLocation,
    required this.onTap,
  });

  final bool hasLocation;
  final bool showError;
  final bool locating;
  final String? status;
  final Future<bool> Function() onCurrentLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hasLocation ? _gasGreen : _gasRed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showError ? _gasRed : color.withValues(alpha: 0.32),
          width: showError ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  hasLocation
                      ? Icons.check_circle_rounded
                      : Icons.add_location_alt_outlined,
                  key: ValueKey(hasLocation),
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? 'ডেলিভারি লোকেশন নিশ্চিত হয়েছে'
                      : 'ডেলিভারি লোকেশন নির্বাচন করুন',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(
              status!,
              style: TextStyle(color: color, fontSize: 12, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: locating ? null : onCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gasInk,
                    side: const BorderSide(color: _gasLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: Text(locating ? 'নেওয়া হচ্ছে' : 'বর্তমান লোকেশন'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: locating ? null : onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gasRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('ম্যাপ থেকে'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _gasRed : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _gasRed : _gasLine),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _gasInk,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile({
    required this.value,
    required this.fee,
    required this.onChanged,
  });

  final bool value;
  final String fee;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: value
            ? _gasRed.withValues(alpha: 0.07)
            : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? _gasRed : _gasLine),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: value ? _gasRed : _gasMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'জরুরি ডেলিভারি',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'অতিরিক্ত $fee',
                  style: const TextStyle(fontSize: 12, color: _gasMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: _gasRed,
            activeThumbColor: Colors.white,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? _gasRed.withValues(alpha: 0.07) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _gasRed : _gasLine,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? _gasRed : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? Colors.white : _gasMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _gasInk,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _gasMuted),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: const Icon(Icons.check_circle_rounded, color: _gasRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===========================================================================
   Orders list
   =========================================================================== */

class GasOrdersScreen extends StatefulWidget {
  const GasOrdersScreen({super.key});
  @override
  State<GasOrdersScreen> createState() => _GasOrdersScreenState();
}

class _GasOrdersScreenState extends State<GasOrdersScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get('/gas/orders');
      if (mounted) {
        setState(
          () => _orders = List<dynamic>.from(data['data'] as List? ?? []),
        );
      }
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        title: const Text(
          'আমার গ্যাস অর্ডার',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _gasLine),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? ListView(
                key: const ValueKey('loading'),
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  5,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _Skeleton(height: 84, radius: 20),
                  ),
                ),
              )
            : RefreshIndicator(
                key: const ValueKey('list'),
                color: _gasRed,
                onRefresh: () => _load(silent: true),
                child: _orders.isEmpty
                    ? CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: const [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: _StateMessage(
                                icon: Icons.receipt_long_outlined,
                                title: 'এখনও কোনো অর্ডার নেই',
                                subtitle: 'অর্ডার করলে এখানে দেখতে পাবেন',
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final order = Map<String, dynamic>.from(
                            _orders[i] as Map,
                          );
                          return _Entrance(
                            delay: math.min(i, 8) * 55,
                            child: _OrderCard(
                              order: order,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GasOrderDetailsScreen(
                                      orderId: (order['id'] as num).toInt(),
                                      initial: order,
                                    ),
                                  ),
                                );
                                _load(silent: true);
                              },
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = '${order['delivery_date'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Pressable(
        onTap: onTap,
        radius: 20,
        color: Colors.white,
        border: const BorderSide(color: _gasLine),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _gasRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.propane_tank_rounded,
                  color: _gasRed,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order['order_no']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _gasInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(status: order['status']),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _gasMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(order['grand_total']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _gasInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _gasMuted,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===========================================================================
   Order details
   =========================================================================== */

class GasOrderDetailsScreen extends StatefulWidget {
  const GasOrderDetailsScreen({super.key, required this.orderId, this.initial});
  final int orderId;
  final Map<String, dynamic>? initial;
  @override
  State<GasOrderDetailsScreen> createState() => _GasOrderDetailsScreenState();
}

class _GasOrderDetailsScreenState extends State<GasOrderDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  Map<String, dynamic> _order = {};
  bool _loading = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initial ?? {};
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('/gas/orders/${widget.orderId}');
      if (mounted) {
        setState(() => _order = Map<String, dynamic>.from(data as Map));
      }
    } catch (e) {
      if (mounted && _order.isEmpty) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.cancel_outlined, color: _gasRed, size: 36),
        title: const Text(
          'অর্ডার বাতিল করবেন?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'বাতিল করলে এই অর্ডার আর ফেরত আনা যাবে না।',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, রাখুন'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _gasRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, বাতিল'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    setState(() => _cancelling = true);
    try {
      await _api.post('/gas/orders/${widget.orderId}/cancel');
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<dynamic>.from(_order['items'] as List? ?? []);
    final orderNo = '${_order['order_no'] ?? ''}';
    return Scaffold(
      backgroundColor: _gasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        title: Text(
          orderNo.isEmpty ? 'অর্ডার' : orderNo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (orderNo.isNotEmpty)
            IconButton(
              tooltip: 'অর্ডার নম্বর কপি করুন',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: orderNo));
                _toast(context, 'অর্ডার নম্বর কপি হয়েছে');
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _gasLine),
        ),
      ),
      body: _loading && _order.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _Skeleton(height: 120, radius: 24),
                SizedBox(height: 12),
                _Skeleton(height: 160, radius: 20),
                SizedBox(height: 12),
                _Skeleton(height: 240, radius: 20),
              ],
            )
          : RefreshIndicator(
              color: _gasRed,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  _Entrance(child: _statusHero()),
                  const SizedBox(height: 12),
                  _Entrance(
                    delay: 70,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gasLine),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সিলিন্ডার',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (var i = 0; i < items.length; i++)
                            _itemRow(
                              Map<String, dynamic>.from(items[i] as Map),
                              last: i == items.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Entrance(
                    delay: 140,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gasLine),
                      ),
                      child: Column(
                        children: [
                          _info('নাম', _order['receiver_name']),
                          _info('ফোন', _order['receiver_phone']),
                          _info('ঠিকানা', _order['delivery_address']),
                          _info('ডিলার', _order['dealer']?['name']),
                          _info(
                            'রাইডার',
                            _order['rider']?['name'] ?? 'এখনও নির্ধারিত হয়নি',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Divider(height: 1, color: _gasLine),
                          ),
                          _info('পণ্যের মোট', _money(_order['items_total'])),
                          _info('ডেলিভারি', _money(_order['delivery_fee'])),
                          _info('জরুরি ফি', _money(_order['emergency_fee'])),
                          _info(
                            'সর্বমোট',
                            _money(_order['grand_total']),
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_order['status'] == 'pending')
                    _Entrance(
                      delay: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _Pressable(
                          onTap: _cancelling ? null : _cancel,
                          radius: 16,
                          scale: 0.97,
                          color: Colors.white,
                          border: BorderSide(
                            color: _gasRed.withValues(alpha: 0.5),
                          ),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: _cancelling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: _gasRed,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cancel_outlined,
                                        color: _gasRed,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'অর্ডার বাতিল করুন',
                                        style: TextStyle(
                                          color: _gasRed,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _statusHero() {
    final slot =
        '${_order['delivery_slot'] ?? (_order['is_emergency'] == true ? 'জরুরি ডেলিভারি' : '')}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        color: _gasInk,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            const Positioned(
              right: -40,
              top: -50,
              child: _Disc(size: 150, alpha: 0.06),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'অর্ডারের অবস্থা',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const Spacer(),
                    if (_order['is_emergency'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _gasRed,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'জরুরি',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _statusText(_order['status'] ?? ''),
                    key: ValueKey('${_order['status']}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_order['delivery_date'] ?? ''} · $slot',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item, {required bool last}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _gasLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _gasRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.propane_tank_outlined,
              color: _gasRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['brand']} ${item['product_name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _gasInk,
                  ),
                ),
                Text(
                  '${item['weight_kg']} কেজি · ${item['purchase_type'] == 'refill' ? 'রিফিল' : 'নতুন'} · ${item['quantity']}টি',
                  style: const TextStyle(fontSize: 12, color: _gasMuted),
                ),
              ],
            ),
          ),
          Text(
            _money(item['total_price']),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _info(String l, dynamic v, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: _gasMuted)),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            '${v ?? '-'}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              fontSize: strong ? 18 : 14,
              color: strong ? _gasRed : _gasInk,
            ),
          ),
        ),
      ],
    ),
  );
}
