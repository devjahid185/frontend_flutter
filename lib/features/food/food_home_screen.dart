import 'dart:async';

import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/analytics/meta_app_events_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/location_picker_screen.dart';
import '../common/modern_app_bar.dart';
import 'rider_dashboard_screen.dart';
import 'widgets/cart_fly_overlay.dart';
import 'widgets/checkout_payment_section.dart';
import 'widgets/food_product_card.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _search = TextEditingController();
  final _bannerController = PageController();
  final _cartButtonKey = GlobalKey();
  Timer? _searchDebounce;
  bool _loading = true;
  bool _searching = false;
  bool _filtersOpen = false;
  int _bannerIndex = 0;
  int _cartCount = 0;
  bool _cartPulse = false;
  String _area = '';
  String _categoryId = '';
  Map<String, dynamic> _home = {};
  List<dynamic> _restaurants = [];
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadItemsRealtime();
    });
  }

  Future<void> _loadItemsRealtime() async {
    setState(() => _searching = true);
    try {
      final items = await _api.get(
        '/food/items',
        query: {
          'q': _search.text.trim(),
          if (_area.isNotEmpty) 'area': _area,
          if (_categoryId.isNotEmpty) 'category_id': _categoryId,
          'per_page': '50',
        },
      );
      if (!mounted) return;
      setState(() => _items = (items['data'] as List?) ?? []);
    } catch (_) {
      if (mounted) _snack('সার্চ করা যায়নি');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final home = await _api.get('/food/home');
      final items = await _api.get(
        '/food/items',
        query: {
          'q': _search.text.trim(),
          if (_area.isNotEmpty) 'area': _area,
          if (_categoryId.isNotEmpty) 'category_id': _categoryId,
          'per_page': '50',
        },
      );
      setState(() {
        _home = Map<String, dynamic>.from(home as Map);
        _restaurants = (_home['restaurants'] as List?) ?? [];
        _items = (items['data'] as List?) ?? [];
      });
    } catch (_) {
      if (mounted) {
        _snack(
          '\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u09a4\u09a5\u09cd\u09af \u09b2\u09cb\u09a1 \u0995\u09b0\u09be \u09af\u09be\u09df\u09a8\u09bf',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _loadCartCount();
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _loadCartCount() async {
    try {
      final data = await _api.get('/food/cart-count');
      if (!mounted) return;
      setState(() => _cartCount = (data['count'] as num?)?.toInt() ?? 0);
    } catch (_) {
      // Cart badge should not block food browsing.
    }
  }

  Future<void> _openCart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodCartScreen()));
    _loadCartCount();
  }

  Future<void> _addItemToCart(
    BuildContext sourceContext,
    Map<String, dynamic> item,
  ) async {
    try {
      await _api.post(
        '/food/cart/items',
        body: {'food_item_id': item['id'], 'quantity': 1},
      );
      unawaited(
        MetaAppEventsService.instance.logAddToCart(
          contentId: '${item['id'] ?? ''}',
          contentName: item['name']?.toString(),
          value: num.tryParse('${item['price'] ?? ''}'),
        ),
      );
      if (!mounted || !sourceContext.mounted) return;
      _playCartFlyAnimation(sourceContext);
      setState(() {
        _cartCount += 1;
        _cartPulse = true;
      });
      Future.delayed(const Duration(milliseconds: 520), () {
        if (mounted) setState(() => _cartPulse = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 950),
          behavior: SnackBarBehavior.floating,
          content: Text('${item['name'] ?? 'Item'} কার্টে যোগ হয়েছে'),
        ),
      );
      _loadCartCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _playCartFlyAnimation(BuildContext sourceContext) {
    final overlay = Overlay.of(context);
    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final cartBox =
        _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (sourceBox == null || cartBox == null || !sourceBox.hasSize) return;

    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final start = overlayBox.globalToLocal(
      sourceBox.localToGlobal(sourceBox.size.center(Offset.zero)),
    );
    final end = overlayBox.globalToLocal(
      cartBox.localToGlobal(cartBox.size.center(Offset.zero)),
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          CartFlyOverlay(start: start, end: end, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = (_home['categories'] as List?) ?? [];
    final banners = (_home['banners'] as List?) ?? [];
    final areas = ((_home['areas'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      appBar: ModernAppBar(
        title:
            '\u09ab\u09c1\u09a1 \u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf',
        subtitle:
            '\u09ad\u09cb\u09b2\u09be\u09df \u09b8\u09b9\u099c\u09c7 \u0996\u09be\u09ac\u09be\u09b0 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09c1\u09a8',
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FoodOrdersScreen())),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FoodOwnerDashboardScreen(),
              ),
            ),
            icon: const Icon(Icons.storefront_outlined),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
            ),
            icon: const Icon(Icons.delivery_dining_rounded),
          ),
          IconButton(
            onPressed: _openCart,
            icon: AnimatedScale(
              key: _cartButtonKey,
              scale: _cartPulse ? 1.18 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: _CartBadgeIcon(count: _cartCount),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(onCart: _openCart, cartCount: _cartCount),
            const SizedBox(height: 12),
            _FoodDiscoveryStrip(
              onOrders: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
              ),
              onOwner: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FoodOwnerDashboardScreen(),
                ),
              ),
              onRider: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39150D).withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadItemsRealtime(),
                      decoration: const InputDecoration(
                        hintText:
                            '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u09ac\u09be \u0996\u09be\u09ac\u09be\u09b0 \u0996\u09c1\u0981\u099c\u09c1\u09a8',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _filtersOpen = !_filtersOpen),
                      icon: Icon(
                        _filtersOpen ? Icons.close_rounded : Icons.tune_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        '\u09ab\u09bf\u09b2\u09cd\u099f\u09be\u09b0',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: !_filtersOpen
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _area.isEmpty ? null : _area,
                              decoration: const InputDecoration(
                                labelText: '\u098f\u09b2\u09be\u0995\u09be',
                              ),
                              items: areas
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(a),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _area = v ?? ''),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _categoryId.isEmpty
                                  ? null
                                  : _categoryId,
                              decoration: const InputDecoration(
                                labelText:
                                    '\u0996\u09be\u09ac\u09be\u09b0 \u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
                              ),
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: '${c['id']}',
                                      child: Text('${c['name']}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _categoryId = v ?? ''),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      _area = '';
                                      _categoryId = '';
                                    }),
                                    child: const Text(
                                      '\u0995\u09cd\u09b2\u09bf\u09df\u09be\u09b0',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _load,
                                    child: const Text(
                                      '\u09a6\u09c7\u0996\u09c1\u09a8',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            if (banners.isNotEmpty)
              _FoodBannerStrip(
                banners: banners,
                controller: _bannerController,
                index: _bannerIndex,
                onChanged: (value) => setState(() => _bannerIndex = value),
                onTap: _openExternal,
              ),
            const SizedBox(height: 14),
            _FoodSectionTitle(
              title: '\u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final isAll = index == 0;
                  final item = isAll ? null : categories[index - 1];
                  final selected = isAll
                      ? _categoryId.isEmpty
                      : _categoryId == '${item['id']}';
                  return ChoiceChip(
                    selected: selected,
                    label: Text(isAll ? "\u09b8\u09ac" : "${item['name']}"),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFB91C1C),
                    backgroundColor: scheme.surface,
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFB91C1C)
                          : scheme.outlineVariant.withValues(alpha: 0.46),
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (_) {
                      setState(
                        () => _categoryId = isAll ? '' : '${item['id']}',
                      );
                      _load();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '\u0996\u09be\u09ac\u09be\u09b0',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF23130F),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    "${_items.length} \u099f\u09bf \u09aa\u09be\u0993\u09df\u09be \u0997\u09c7\u099b\u09c7",
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: LogoLoader(size: 22),
                ),
              ),
            if (!_loading && _items.isEmpty)
              const _EmptyFoodState(text: 'খাবার পাওয়া যায়নি'),
            if (!_loading && _items.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 255,
                ),
                itemBuilder: (context, index) {
                  final item = Map<String, dynamic>.from(_items[index] as Map);
                  final restaurant = item['restaurant'] is Map
                      ? Map<String, dynamic>.from(item['restaurant'] as Map)
                      : <String, dynamic>{};
                  return FoodProductCard(
                    item: item,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodItemDetailsScreen(item: item),
                        ),
                      );
                      _loadCartCount();
                    },
                    onRestaurantTap: restaurant['id'] == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FoodRestaurantDetailsScreen(
                                id: (restaurant['id'] as num).toInt(),
                              ),
                            ),
                          ),
                    onAdd: (buttonContext) =>
                        _addItemToCart(buttonContext, item),
                  );
                },
              ),
            if (_restaurants.isNotEmpty) ...[
              const SizedBox(height: 18),
              _FoodSectionTitle(title: 'রেস্টুরেন্ট'),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _restaurants.take(8).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final r = Map<String, dynamic>.from(
                      _restaurants[index] as Map,
                    );
                    return SizedBox(
                      width: 220,
                      child: _RestaurantShowcaseCard(
                        data: r,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FoodRestaurantDetailsScreen(
                              id: (r['id'] as num).toInt(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FoodRestaurantDetailsScreen extends StatefulWidget {
  const FoodRestaurantDetailsScreen({super.key, required this.id});
  final int id;

  @override
  State<FoodRestaurantDetailsScreen> createState() =>
      _FoodRestaurantDetailsScreenState();
}

class _FoodRestaurantDetailsScreenState
    extends State<FoodRestaurantDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  int _cartCount = 0;
  Map<String, dynamic> _restaurant = {};
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _load();
    _loadCartCount();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/food/restaurants/${widget.id}');
      setState(() => _restaurant = Map<String, dynamic>.from(data as Map));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final data = await _api.get('/food/cart-count');
      if (!mounted) return;
      setState(() => _cartCount = (data['count'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  Future<void> _openCart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodCartScreen()));
    _loadCartCount();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = ((_restaurant['menu_items'] as List?) ?? []).where((item) {
      if (_category == 'all') return true;
      return '${item['food_category_id']}' == _category;
    }).toList();
    final categories = (_restaurant['menu_categories'] as List?) ?? [];

    return Scaffold(
      appBar: ModernAppBar(
        title:
            "${_restaurant['name'] ?? '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f'}",
        subtitle:
            "\u09ae\u09c7\u09a8\u09c1 \u0993 \u0985\u09b0\u09cd\u09a1\u09be\u09b0",
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCart,
        icon: _CartBadgeIcon(count: _cartCount, size: 22),
        label: const Text("\u0995\u09be\u09b0\u09cd\u099f"),
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _FoodImage(
                          url: _restaurant['image_url']?.toString(),
                          height: 150,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_restaurant['name']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_restaurant['address'] ?? '\u09a0\u09bf\u0995\u09be\u09a8\u09be \u09a6\u09c7\u0993\u09df\u09be \u09a8\u09c7\u0987'}",
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.star_rounded,
                            text:
                                "${_restaurant['rating'] ?? 0} \u09b0\u09c7\u099f\u09bf\u0982",
                          ),
                          _InfoPill(
                            icon: Icons.timer_outlined,
                            text:
                                "${_restaurant['delivery_time'] ?? '\u09e9\u09e6-\u09eb\u09e6 \u09ae\u09bf\u09a8\u09bf\u099f'}",
                          ),
                          if (_restaurant['minimum_order'] != null)
                            _InfoPill(
                              icon: Icons.shopping_basket_outlined,
                              text:
                                  "\u09ae\u09bf\u09a8 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09f3${_restaurant['minimum_order']}",
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FoodReviewsPanel(
                  restaurantId: widget.id,
                  reviews: (_restaurant['reviews'] as List?) ?? const [],
                  onChanged: _load,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final all = index == 0;
                      final c = all ? null : categories[index - 1];
                      final selected = all
                          ? _category == 'all'
                          : _category == '${c['id']}';
                      return ChoiceChip(
                        selected: selected,
                        label: Text(
                          all
                              ? "\u09b8\u09ac \u09ae\u09c7\u09a8\u09c1"
                              : "${c['name']}",
                        ),
                        onSelected: (_) => setState(
                          () => _category = all ? 'all' : '${c['id']}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => _FoodItemCard(
                    item: Map<String, dynamic>.from(item as Map),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodItemDetailsScreen(
                          item: Map<String, dynamic>.from(item),
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

class FoodItemDetailsScreen extends StatefulWidget {
  const FoodItemDetailsScreen({super.key, required this.item});
  final Map<String, dynamic> item;

  @override
  State<FoodItemDetailsScreen> createState() => _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends State<FoodItemDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _note = TextEditingController();
  late Map<String, dynamic> _item;
  int _qty = 1;
  String? _size;
  String? _spice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _loadDetails();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await _api.get('/food/items/${widget.item['id']}');
      if (!mounted) return;
      setState(() => _item = Map<String, dynamic>.from(data as Map));
    } catch (_) {}
  }

  Future<void> _add() async {
    setState(() => _saving = true);
    try {
      await _api.post(
        '/food/cart/items',
        body: {
          'food_item_id': widget.item['id'],
          'quantity': _qty,
          if (_size != null && _size!.trim().isNotEmpty) 'size': _size,
          if (_spice != null && _spice!.trim().isNotEmpty)
            'spice_level': _spice,
          'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "\u0995\u09be\u09b0\u09cd\u099f\u09c7 \u09af\u09cb\u0997 \u09b9\u09df\u09c7\u099b\u09c7",
          ),
        ),
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FoodCartScreen()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = _item;
    final sizes = ((item['size_options'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final spices = ((item['spice_options'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final price = item['discount_price'] ?? item['price'];
    if (sizes.isEmpty) _size = null;
    if (spices.isEmpty) _spice = null;

    return Scaffold(
      appBar: ModernAppBar(
        title: "${item['name']}",
        subtitle:
            "\u09b8\u09b9\u099c\u09c7 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09c1\u09a8",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _add,
            child: Text(
              _saving
                  ? "\u09af\u09cb\u0997 \u09b9\u099a\u09cd\u099b\u09c7..."
                  : "\u0995\u09be\u09b0\u09cd\u099f\u09c7 \u09af\u09cb\u0997 \u0995\u09b0\u09c1\u09a8 - \u09f3${((num.tryParse('$price') ?? 0) * _qty).toStringAsFixed(0)}",
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _FoodImage(url: item['image_url']?.toString(), height: 230),
          ),
          const SizedBox(height: 14),
          Text(
            '${item['name']}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if ((item['description'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "${item['description']}",
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            "\u09f3$price",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          if (sizes.isNotEmpty) ...[
            _OptionSection(
              title: "\u09b8\u09be\u0987\u099c",
              options: sizes,
              value: _size,
              onChanged: (v) => setState(() => _size = v),
            ),
            const SizedBox(height: 12),
          ],
          if (spices.isNotEmpty) ...[
            _OptionSection(
              title: "\u099d\u09be\u09b2",
              options: spices,
              value: _spice,
              onChanged: (v) => setState(() => _spice = v),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText:
                  "\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f\u09c7\u09b0 \u099c\u09a8\u09cd\u09af \u09a8\u09cb\u099f",
              hintText:
                  "\u09af\u09c7\u09ae\u09a8: \u099d\u09be\u09b2 \u0995\u09ae, \u09b8\u09b8 \u09ac\u09c7\u09b6\u09bf",
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  '$_qty',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FoodReviewsPanel(
            restaurantId: (item['restaurant_id'] as num?)?.toInt(),
            foodItemId: (item['id'] as num?)?.toInt(),
            reviews: (item['reviews'] as List?) ?? const [],
            onChanged: _loadDetails,
          ),
        ],
      ),
    );
  }
}

class FoodOwnerDashboardScreen extends StatefulWidget {
  const FoodOwnerDashboardScreen({super.key});

  @override
  State<FoodOwnerDashboardScreen> createState() =>
      _FoodOwnerDashboardScreenState();
}

class _FoodOwnerDashboardScreenState extends State<FoodOwnerDashboardScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/food/owner/dashboard');
      setState(() => _data = Map<String, dynamic>.from(data as Map));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = Map<String, dynamic>.from((_data['stats'] as Map?) ?? {});
    final restaurants = (_data['restaurants'] as List?) ?? [];
    final recentOrders = (_data['recent_orders'] as List?) ?? [];
    return Scaffold(
      appBar: const ModernAppBar(
        title:
            '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u09ae\u09cd\u09af\u09be\u09a8\u09c7\u099c',
        subtitle:
            '\u09ae\u09c7\u09a8\u09c1, \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0993 \u09aa\u09cd\u09b0\u09cb\u09ab\u09be\u0987\u09b2',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => const FoodOwnerRestaurantFormScreen(),
              ),
            )
            .then((_) => _load()),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text(
          '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u09af\u09cb\u0997',
        ),
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _OwnerStatCard(
                        label:
                            '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f',
                        value: '${stats['restaurants'] ?? 0}',
                        icon: Icons.storefront_outlined,
                      ),
                      _OwnerStatCard(
                        label:
                            '\u09ae\u09c7\u09a8\u09c1 \u0986\u0987\u099f\u09c7\u09ae',
                        value: '${stats['menu_items'] ?? 0}',
                        icon: Icons.restaurant_menu_outlined,
                      ),
                      _OwnerStatCard(
                        label:
                            '\u09aa\u09c7\u09a8\u09cd\u09a1\u09bf\u0982 \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
                        value: '${stats['pending_orders'] ?? 0}',
                        icon: Icons.pending_actions_outlined,
                      ),
                      _OwnerStatCard(
                        label: '\u09b8\u09c7\u09b2\u09b8',
                        value: '\u09f3${stats['sales_total'] ?? 0}',
                        icon: Icons.payments_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FoodOwnerMenuScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('\u09ae\u09c7\u09a8\u09c1'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FoodOwnerOrdersScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            '\u0985\u09b0\u09cd\u09a1\u09be\u09b0',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FoodOwnerReviewsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text(
                        '\u09b0\u09bf\u09ad\u09bf\u0989 \u0993 \u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FoodSectionHeader(
                    icon: Icons.store_mall_directory_outlined,
                    title:
                        '\u0986\u09ae\u09be\u09b0 \u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f',
                    subtitle:
                        '\u0985\u09cd\u09af\u09be\u09a1\u09ae\u09bf\u09a8 active \u0995\u09b0\u09b2\u09c7 food page \u098f \u09a6\u09c7\u0996\u09be\u09ac\u09c7',
                  ),
                  const SizedBox(height: 10),
                  if (restaurants.isEmpty)
                    const _EmptyFoodState(
                      text:
                          '\u098f\u0996\u09a8\u09cb \u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u09a8\u09c7\u0987',
                    ),
                  ...restaurants.map((raw) {
                    final r = Map<String, dynamic>.from(raw as Map);
                    return _OwnerRestaurantCard(
                      data: r,
                      onEdit: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodOwnerRestaurantFormScreen(initial: r),
                            ),
                          )
                          .then((_) => _load()),
                      onMenu: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodOwnerMenuScreen(
                            restaurantId: (r['id'] as num).toInt(),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _FoodSectionHeader(
                    icon: Icons.history_rounded,
                    title:
                        '\u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
                    subtitle:
                        '\u09b6\u09c7\u09b7 ${recentOrders.length} \u099f\u09bf',
                  ),
                  const SizedBox(height: 10),
                  ...recentOrders.map(
                    (raw) => _OwnerOrderCard(
                      order: Map<String, dynamic>.from(raw as Map),
                      onChanged: _load,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class FoodOwnerReviewsScreen extends StatefulWidget {
  const FoodOwnerReviewsScreen({super.key});

  @override
  State<FoodOwnerReviewsScreen> createState() => _FoodOwnerReviewsScreenState();
}

class _FoodOwnerReviewsScreenState extends State<FoodOwnerReviewsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/food/owner/reviews');
      setState(() => _reviews = (res['data'] as List?) ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reply(Map<String, dynamic> review) async {
    final controller = TextEditingController(
      text: '${review['owner_reply'] ?? ''}',
    );
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u09b0\u09bf\u09ad\u09bf\u0989\u09b0 \u0989\u09a4\u09cd\u09a4\u09b0',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '\u0995\u09be\u09b8\u09cd\u099f\u09ae\u09be\u09b0\u0995\u09c7 \u09ad\u09a6\u09cd\u09b0 \u0993 \u09b8\u09cd\u09aa\u09b7\u09cd\u099f \u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995 \u09a6\u09bf\u09a8\u0964',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                labelText:
                    '\u0986\u09aa\u09a8\u09be\u09b0 \u0989\u09a4\u09cd\u09a4\u09b0',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text(
                  '\u0989\u09a4\u09cd\u09a4\u09b0 \u09b8\u09c7\u09ad \u0995\u09b0\u09c1\u09a8',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (text == null || text.isEmpty) return;
    await _api.post(
      '/food/owner/reviews/${review['id']}/reply',
      body: {'owner_reply': text},
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995 \u09b8\u09c7\u09ad \u09b9\u09df\u09c7\u099b\u09c7',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: '\u09ab\u09c1\u09a1 \u09b0\u09bf\u09ad\u09bf\u0989',
        subtitle:
            '\u09ae\u09be\u09b2\u09bf\u0995\u09c7\u09b0 \u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _FoodSectionHeader(
                    icon: Icons.rate_review_outlined,
                    title:
                        '\u0995\u09be\u09b8\u09cd\u099f\u09ae\u09be\u09b0 \u09b0\u09bf\u09ad\u09bf\u0989',
                    subtitle: _reviews.isEmpty
                        ? '\u098f\u0996\u09a8\u09cb \u09b0\u09bf\u09ad\u09bf\u0989 \u09a8\u09c7\u0987'
                        : '${_reviews.length} \u099f\u09bf \u09b0\u09bf\u09ad\u09bf\u0989',
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    const _EmptyFoodState(
                      text:
                          '\u098f\u0996\u09a8\u09cb \u0995\u09cb\u09a8\u09cb \u09b0\u09bf\u09ad\u09bf\u0989 \u09a8\u09c7\u0987',
                    ),
                  ..._reviews.map((raw) {
                    final review = Map<String, dynamic>.from(raw as Map);
                    return _FoodReviewCard(
                      review: review,
                      action: OutlinedButton.icon(
                        onPressed: () => _reply(review),
                        icon: const Icon(Icons.reply_rounded, size: 18),
                        label: Text(
                          (review['owner_reply'] ?? '').toString().isEmpty
                              ? '\u0989\u09a4\u09cd\u09a4\u09b0 \u09a6\u09bf\u09a8'
                              : '\u0989\u09a4\u09cd\u09a4\u09b0 \u098f\u09a1\u09bf\u099f',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class FoodOwnerRestaurantFormScreen extends StatefulWidget {
  const FoodOwnerRestaurantFormScreen({super.key, this.initial});
  final Map<String, dynamic>? initial;

  @override
  State<FoodOwnerRestaurantFormScreen> createState() =>
      _FoodOwnerRestaurantFormScreenState();
}

class _FoodOwnerRestaurantFormScreenState
    extends State<FoodOwnerRestaurantFormScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _prep = TextEditingController(text: '30');
  final _minPrice = TextEditingController();
  final _description = TextEditingController();
  final _bkashNumber = TextEditingController();
  final _nagadNumber = TextEditingController();
  final _paymentInstructions = TextEditingController();
  bool _delivery = true;
  bool _codEnabled = true;
  bool _saving = false;
  bool _locating = false;
  double? _restaurantLat;
  double? _restaurantLng;
  String? _locationStatus;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    final data = widget.initial;
    if (data != null) {
      _name.text = '${data['name'] ?? ''}';
      _phone.text = '${data['phone'] ?? ''}';
      _address.text = '${data['address'] ?? ''}';
      _hours.text = '${data['opening_hours'] ?? ''}';
      _prep.text = '${data['average_prep_minutes'] ?? 30}';
      _minPrice.text = '${data['min_price'] ?? ''}';
      _description.text = '${data['description'] ?? ''}';
      _bkashNumber.text = '${data['manual_bkash_number'] ?? ''}';
      _nagadNumber.text = '${data['manual_nagad_number'] ?? ''}';
      _paymentInstructions.text =
          '${data['manual_payment_instructions'] ?? ''}';
      _delivery =
          data['delivery_available'] == true || data['delivery_available'] == 1;
      _codEnabled = data['cod_enabled'] != false && data['cod_enabled'] != 0;
      _restaurantLat = readDouble(data['lat']);
      _restaurantLng = readDouble(data['lng']);
      if (_restaurantLat != null && _restaurantLng != null) {
        _locationStatus =
            'লোকেশন নেওয়া আছে: ${_restaurantLat!.toStringAsFixed(5)}, ${_restaurantLng!.toStringAsFixed(5)}';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _hours.dispose();
    _prep.dispose();
    _minPrice.dispose();
    _description.dispose();
    _bkashNumber.dispose();
    _nagadNumber.dispose();
    _paymentInstructions.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _image = img);
  }

  Future<void> _captureCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationStatus = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _locationStatus = 'লোকেশন সার্ভিস চালু করুন।');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(
          () => _locationStatus =
              'লোকেশন permission দিলে রেস্টুরেন্ট লোকেশন নেওয়া যাবে।',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        setState(
          () => _locationStatus =
              'App settings থেকে লোকেশন permission চালু করুন।',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _restaurantLat = position.latitude;
        _restaurantLng = position.longitude;
        _locationStatus =
            'বর্তমান লোকেশন নেওয়া হয়েছে: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      setState(
        () => _locationStatus =
            'লোকেশন নেওয়া যায়নি। ম্যাপ থেকে সিলেক্ট করুন বা আবার চেষ্টা করুন।',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickRestaurantLocationOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _restaurantLat,
          initialLng: _restaurantLng,
          title: 'রেস্টুরেন্ট লোকেশন',
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _restaurantLat = picked.lat;
      _restaurantLng = picked.lng;
      _locationStatus =
          'ম্যাপ থেকে লোকেশন নেওয়া হয়েছে: ${picked.lat.toStringAsFixed(5)}, ${picked.lng.toStringAsFixed(5)}';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_restaurantLat == null || _restaurantLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('রেস্টুরেন্ট লোকেশন current location বা map থেকে দিন।'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.post(
        '/food/owner/restaurants',
        body: {
          'id': widget.initial?['id'],
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'opening_hours': _hours.text.trim(),
          'average_prep_minutes': int.tryParse(_prep.text.trim()) ?? 30,
          'min_price': int.tryParse(_minPrice.text.trim()),
          'description': _description.text.trim(),
          'delivery_available': _delivery,
          'accepts_food_orders': true,
          'cod_enabled': _codEnabled,
          'manual_bkash_number': _bkashNumber.text.trim().isEmpty
              ? null
              : _bkashNumber.text.trim(),
          'manual_nagad_number': _nagadNumber.text.trim().isEmpty
              ? null
              : _nagadNumber.text.trim(),
          'manual_payment_instructions':
              _paymentInstructions.text.trim().isEmpty
              ? null
              : _paymentInstructions.text.trim(),
          'district': 'Bhola',
          'lat': _restaurantLat,
          'lng': _restaurantLng,
        },
      );
      final restaurant = Map<String, dynamic>.from(res['restaurant'] as Map);
      final id = (restaurant['id'] as num).toInt();
      if (_image != null) {
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'restaurant',
            'target_type': 'restaurant',
            'target_id': '$id',
            'set_primary': 'true',
          },
          files: {
            'images[]': [_image!.path],
          },
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'Saved'}')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ModernAppBar(
      title:
          '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u09ab\u09b0\u09cd\u09ae',
      subtitle:
          '\u0985\u09cd\u09af\u09be\u09a1\u09ae\u09bf\u09a8 approval \u09aa\u09cd\u09b0\u09df\u09cb\u099c\u09a8',
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                : '\u09b8\u09c7\u09ad \u0995\u09b0\u09c1\u09a8',
          ),
        ),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(
              _image == null
                  ? '\u09b2\u09cb\u0997\u09cb/\u099b\u09ac\u09bf \u09a6\u09bf\u09a8'
                  : '\u099b\u09ac\u09bf \u09b8\u09bf\u09b2\u09c7\u0995\u09cd\u099f \u09b9\u09df\u09c7\u099b\u09c7',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText:
                  '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f\u09c7\u09b0 \u09a8\u09be\u09ae',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? '\u09a8\u09be\u09ae \u09a6\u09bf\u09a8'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '\u09ab\u09cb\u09a8 \u09a8\u09ae\u09cd\u09ac\u09b0',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '\u09a0\u09bf\u0995\u09be\u09a8\u09be',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? '\u09a0\u09bf\u0995\u09be\u09a8\u09be \u09a6\u09bf\u09a8'
                : null,
          ),
          const SizedBox(height: 10),
          _RestaurantLocationPanel(
            lat: _restaurantLat,
            lng: _restaurantLng,
            status: _locationStatus,
            locating: _locating,
            onCurrent: _captureCurrentLocation,
            onMap: _pickRestaurantLocationOnMap,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _hours,
            decoration: const InputDecoration(
              labelText: '\u0996\u09cb\u09b2\u09be\u09b0 \u09b8\u09ae\u09df',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prep,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText:
                        '\u09aa\u09cd\u09b0\u09bf\u09aa\u09be\u09b0\u09c7\u09b6\u09a8 \u09ae\u09bf\u09a8\u09bf\u099f',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _minPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText:
                        '\u09ae\u09bf\u09a8 \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _delivery,
            onChanged: (v) => setState(() => _delivery = v),
            title: const Text(
              '\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09a8\u09bf\u09ac\u09c7',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          _FoodSectionHeader(
            icon: Icons.payments_outlined,
            title: 'পেমেন্ট সেটিংস',
            subtitle: 'কাস্টমার কোন পদ্ধতিতে পেমেন্ট করবে সেটি ঠিক করুন',
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _codEnabled,
            onChanged: (v) => setState(() => _codEnabled = v),
            title: const Text('Cash on Delivery চালু থাকবে'),
            subtitle: const Text(
              'বন্ধ করলে কাস্টমার COD দিয়ে অর্ডার করতে পারবে না',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bkashNumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Manual bKash personal number',
              hintText: 'যেমন: 01XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_android_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nagadNumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Manual Nagad personal number',
              hintText: 'যেমন: 01XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_android_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _paymentInstructions,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Manual payment instruction',
              hintText:
                  'যেমন: Send Money করে transaction ID অর্ডার নোটে লিখুন।',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '\u09ac\u09bf\u09ac\u09b0\u09a3',
            ),
          ),
        ],
      ),
    ),
  );
}

class _RestaurantLocationPanel extends StatelessWidget {
  const _RestaurantLocationPanel({
    required this.lat,
    required this.lng,
    required this.status,
    required this.locating,
    required this.onCurrent,
    required this.onMap,
  });

  final double? lat;
  final double? lng;
  final String? status;
  final bool locating;
  final VoidCallback onCurrent;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLocation = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasLocation
            ? scheme.primaryContainer.withValues(alpha: 0.45)
            : scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasLocation
              ? scheme.primary.withValues(alpha: 0.32)
              : scheme.error.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on_rounded : Icons.location_off,
                color: hasLocation ? scheme.primary : scheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'রেস্টুরেন্ট লোকেশন আবশ্যক',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status ??
                'রাইডার খুঁজতে current location বা map থেকে রেস্টুরেন্টের সঠিক লোকেশন দিন।',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 6),
            Text(
              '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: locating ? null : onCurrent,
                icon: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: LogoLoader(size: 18),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Current location'),
              ),
              OutlinedButton.icon(
                onPressed: locating ? null : onMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Map থেকে সিলেক্ট'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FoodOwnerMenuScreen extends StatefulWidget {
  const FoodOwnerMenuScreen({super.key, this.restaurantId});
  final int? restaurantId;
  @override
  State<FoodOwnerMenuScreen> createState() => _FoodOwnerMenuScreenState();
}

class _FoodOwnerMenuScreenState extends State<FoodOwnerMenuScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.get(
      '/food/owner/items',
      query: {
        if (widget.restaurantId != null)
          'restaurant_id': widget.restaurantId.toString(),
      },
    );
    setState(() {
      _items = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ModernAppBar(
      title:
          '\u09ae\u09c7\u09a8\u09c1 \u09ae\u09cd\u09af\u09be\u09a8\u09c7\u099c',
      subtitle: widget.restaurantId == null
          ? '\u0996\u09be\u09ac\u09be\u09b0 \u09af\u09cb\u0997/\u098f\u09a1\u09bf\u099f'
          : '\u09b6\u09c1\u09a7\u09c1 \u098f\u0987 \u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f\u09c7\u09b0 \u09ae\u09c7\u09a8\u09c1',
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) =>
                  FoodOwnerItemFormScreen(restaurantId: widget.restaurantId),
            ),
          )
          .then((_) => _load()),
      icon: const Icon(Icons.add),
      label: const Text('\u0986\u0987\u099f\u09c7\u09ae'),
    ),
    body: _loading
        ? const Center(child: LogoLoader(showLabel: true))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_items.isEmpty)
                  const _EmptyFoodState(
                    text:
                        '\u09ae\u09c7\u09a8\u09c1 \u0986\u0987\u099f\u09c7\u09ae \u09a8\u09c7\u0987',
                  ),
                ..._items.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  return _OwnerMenuItemCard(
                    item: item,
                    onEdit: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => FoodOwnerItemFormScreen(
                              initial: item,
                              restaurantId: (item['restaurant_id'] as num?)
                                  ?.toInt(),
                            ),
                          ),
                        )
                        .then((_) => _load()),
                    onDelete: () async {
                      await _api.delete('/food/owner/items/${item['id']}');
                      _load();
                    },
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          ),
  );
}

class FoodOwnerItemFormScreen extends StatefulWidget {
  const FoodOwnerItemFormScreen({super.key, this.initial, this.restaurantId});
  final Map<String, dynamic>? initial;
  final int? restaurantId;
  @override
  State<FoodOwnerItemFormScreen> createState() =>
      _FoodOwnerItemFormScreenState();
}

class _FoodOwnerItemFormScreenState extends State<FoodOwnerItemFormScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController();
  final _prep = TextEditingController(text: '20');
  List<dynamic> _restaurants = [];
  List<dynamic> _categories = [];
  int? _restaurantId;
  int? _categoryId;
  bool _available = true;
  bool _saving = false;
  XFile? _image;
  @override
  void initState() {
    super.initState();
    _apply();
    _load();
  }

  void _apply() {
    final d = widget.initial;
    _restaurantId =
        widget.restaurantId ?? (d?['restaurant_id'] as num?)?.toInt();
    _categoryId = (d?['food_category_id'] as num?)?.toInt();
    _name.text = '${d?['name'] ?? ''}';
    _desc.text = '${d?['description'] ?? ''}';
    _price.text = '${d?['price'] ?? ''}';
    _discount.text = '${d?['discount_price'] ?? ''}';
    _prep.text = '${d?['preparation_minutes'] ?? 20}';
    _available =
        d == null || d['is_available'] == true || d['is_available'] == 1;
  }

  Future<void> _load() async {
    final rs = await _api.get('/food/owner/restaurants');
    final home = await _api.get('/food/home');
    setState(() {
      _restaurants = (rs as List?) ?? [];
      _categories = (home['categories'] as List?) ?? [];
      _restaurantId ??= _restaurants.isNotEmpty
          ? (_restaurants.first['id'] as num).toInt()
          : null;
    });
  }

  Future<void> _pick() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _image = img);
  }

  Future<void> _save() async {
    if (_restaurantId == null ||
        _name.text.trim().isEmpty ||
        _price.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.post(
        '/food/owner/items',
        body: {
          'id': widget.initial?['id'],
          'restaurant_id': _restaurantId,
          'food_category_id': _categoryId,
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': num.tryParse(_price.text.trim()) ?? 0,
          'discount_price': _discount.text.trim().isEmpty
              ? null
              : num.tryParse(_discount.text.trim()),
          'preparation_minutes': int.tryParse(_prep.text.trim()) ?? 20,
          'is_available': _available,
          'status': 'active',
        },
      );
      final item = Map<String, dynamic>.from(res['item'] as Map);
      if (_image != null) {
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'food',
            'target_type': 'food_item',
            'target_id': '${item['id']}',
            'set_primary': 'true',
          },
          files: {
            'images[]': [_image!.path],
          },
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _prep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ModernAppBar(
      title: '\u09ae\u09c7\u09a8\u09c1 \u0986\u0987\u099f\u09c7\u09ae',
      subtitle:
          '\u09a6\u09be\u09ae, \u099b\u09ac\u09bf \u0993 \u09b8\u09cd\u099f\u09cd\u09af\u09be\u099f\u09be\u09b8',
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                : '\u09b8\u09c7\u09ad',
          ),
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<int>(
          initialValue: _restaurantId,
          decoration: const InputDecoration(
            labelText:
                '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f',
          ),
          items: _restaurants
              .map(
                (r) => DropdownMenuItem(
                  value: (r['id'] as num).toInt(),
                  child: Text('${r['name']}'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _restaurantId = v),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          decoration: const InputDecoration(
            labelText: '\u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
          ),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: (c['id'] as num).toInt(),
                  child: Text('${c['name']}'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText:
                '\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desc,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: '\u09ac\u09bf\u09ac\u09b0\u09a3',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '\u09a6\u09be\u09ae',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _discount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '\u099b\u09be\u09dc \u09a6\u09be\u09ae',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _prep,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText:
                '\u09aa\u09cd\u09b0\u09bf\u09aa\u09be\u09b0\u09c7\u09b6\u09a8 \u09ae\u09bf\u09a8\u09bf\u099f',
          ),
        ),
        SwitchListTile(
          value: _available,
          onChanged: (v) => setState(() => _available = v),
          title: const Text(
            '\u09ac\u09bf\u0995\u09cd\u09b0\u09bf \u099a\u09be\u09b2\u09c1',
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            _image == null
                ? '\u099b\u09ac\u09bf \u09a6\u09bf\u09a8'
                : '\u099b\u09ac\u09bf \u09a8\u09c7\u0993\u09df\u09be \u09b9\u09df\u09c7\u099b\u09c7',
          ),
        ),
      ],
    ),
  );
}

class FoodOwnerOrdersScreen extends StatefulWidget {
  const FoodOwnerOrdersScreen({super.key});
  @override
  State<FoodOwnerOrdersScreen> createState() => _FoodOwnerOrdersScreenState();
}

class _FoodOwnerOrdersScreenState extends State<FoodOwnerOrdersScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _orders = [];
  Timer? _poller;

  Future<void> _load() async {
    final res = await _api.get('/food/owner/orders');
    if (!mounted) return;
    setState(() {
      _orders = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ModernAppBar(
      title:
          '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
      subtitle:
          '\u09b8\u09cd\u099f\u09cd\u09af\u09be\u099f\u09be\u09b8 \u0986\u09aa\u09a1\u09c7\u099f',
    ),
    body: _loading
        ? const Center(child: LogoLoader(showLabel: true))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_orders.isEmpty)
                  const _EmptyFoodState(
                    text:
                        '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09c7\u0987',
                  ),
                ..._orders.map(
                  (o) => _OwnerOrderCard(
                    order: Map<String, dynamic>.from(o as Map),
                    onChanged: _load,
                  ),
                ),
              ],
            ),
          ),
  );
}

class _OwnerStatCard extends StatelessWidget {
  const _OwnerStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OwnerRestaurantCard extends StatelessWidget {
  const _OwnerRestaurantCard({
    required this.data,
    required this.onEdit,
    required this.onMenu,
  });
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = '${data['status'] ?? 'pending'}';
    final active = status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _FoodImage(
                  url: data['image_url']?.toString(),
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['name'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['address'] ?? '\u09ad\u09cb\u09b2\u09be'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniPill(
                          active
                              ? '\u0985\u09cd\u09af\u09be\u0995\u099f\u09bf\u09ad'
                              : '\u0985\u09cd\u09af\u09be\u09aa\u09cd\u09b0\u09c1\u09ad\u09be\u09b2 \u09ac\u09be\u0995\u09bf',
                        ),
                        _MiniPill(
                          '${data['menu_items_count'] ?? 0} \u09ae\u09c7\u09a8\u09c1',
                        ),
                        _MiniPill(
                          '${data['pending_orders_count'] ?? 0} \u09aa\u09c7\u09a8\u09cd\u09a1\u09bf\u0982',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((data['approval_note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${data['approval_note']}',
              style: TextStyle(color: scheme.error, fontSize: 12, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('\u098f\u09a1\u09bf\u099f'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onMenu,
                  icon: const Icon(Icons.restaurant_menu_outlined, size: 18),
                  label: const Text('\u09ae\u09c7\u09a8\u09c1'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerMenuItemCard extends StatelessWidget {
  const _OwnerMenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '\u0986\u0987\u099f\u09c7\u09ae \u09a1\u09bf\u09b2\u09bf\u099f?',
        ),
        content: Text(
          '${item['name'] ?? ''} \u09ae\u09c7\u09a8\u09c1 \u09a5\u09c7\u0995\u09c7 \u09b8\u09b0\u09be\u09a8\u09cb \u09b9\u09ac\u09c7\u0964',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u09ac\u09be\u09a4\u09bf\u09b2'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\u09a1\u09bf\u09b2\u09bf\u099f'),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = item['discount_price'] ?? item['price'];
    final available = item['is_available'] == true || item['is_available'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _FoodImage(
              url: item['image_url']?.toString(),
              width: 70,
              height: 70,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['restaurant']?['name'] ?? item['category']?['name'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniPill('\u09f3$price'),
                    _MiniPill(
                      available
                          ? '\u099a\u09be\u09b2\u09c1'
                          : '\u09ac\u09a8\u09cd\u09a7',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerOrderCard extends StatelessWidget {
  const _OwnerOrderCard({required this.order, required this.onChanged});
  final Map<String, dynamic> order;
  final Future<void> Function() onChanged;

  Future<void> _showDeliveryMap(BuildContext context) async {
    final deliveryLat = readDouble(order['delivery_lat']);
    final deliveryLng = readDouble(order['delivery_lng']);
    if (deliveryLat == null || deliveryLng == null) return;

    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final rider = order['rider'] is Map
        ? Map<String, dynamic>.from(order['rider'] as Map)
        : <String, dynamic>{};
    final markers = <AppMapMarker>[];
    final restaurantLat = readDouble(restaurant['lat']);
    final restaurantLng = readDouble(restaurant['lng']);
    if (restaurantLat != null && restaurantLng != null) {
      markers.add(
        AppMapMarker(
          lat: restaurantLat,
          lng: restaurantLng,
          label: restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
          icon: Icons.restaurant_rounded,
          color: Colors.deepOrange,
        ),
      );
    }
    markers.add(
      AppMapMarker(
        lat: deliveryLat,
        lng: deliveryLng,
        label: order['receiver_name']?.toString() ?? 'কাস্টমার',
        icon: Icons.location_city_rounded,
      ),
    );
    final riderLat = readDouble(rider['last_lat']);
    final riderLng = readDouble(rider['last_lng']);
    if (riderLat != null && riderLng != null) {
      markers.add(
        AppMapMarker(
          lat: riderLat,
          lng: riderLng,
          label: rider['name']?.toString() ?? 'রাইডার',
          icon: Icons.delivery_dining,
          color: Colors.green,
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: riderLat ?? deliveryLat,
          initialLng: riderLng ?? deliveryLng,
          title: riderLat != null
              ? 'লাইভ ডেলিভারি ট্র্যাকিং'
              : 'কাস্টমার ডেলিভারি লোকেশন',
          readOnly: true,
          markers: markers,
        ),
      ),
    );
  }

  List<MapEntry<String, String>> _actionsFor(String status) {
    switch (status) {
      case 'pending':
        return const [
          MapEntry('accepted', '\u0997\u09cd\u09b0\u09b9\u09a3'),
          MapEntry('rejected', '\u09ac\u09be\u09a4\u09bf\u09b2'),
        ];
      case 'accepted':
        return const [
          MapEntry(
            'preparing',
            '\u09a4\u09c8\u09b0\u09bf \u09b9\u099a\u09cd\u099b\u09c7',
          ),
        ];
      case 'preparing':
        return const [
          MapEntry(
            'picked_up',
            '\u09b0\u09be\u0987\u09a1\u09be\u09b0 \u09a8\u09bf\u09df\u09c7\u099b\u09c7',
          ),
        ];
      case 'picked_up':
        return const [
          MapEntry('on_the_way', '\u09aa\u09a5\u09c7 \u0986\u099b\u09c7'),
        ];
      case 'on_the_way':
        return const [
          MapEntry(
            'delivered',
            '\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09cd\u09a1',
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = '${order['status'] ?? 'pending'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                FoodOwnerOrderDetailsScreen(order: order, onChanged: onChanged),
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${order['order_no'] ?? '#${order['id']}'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _FoodStatusChip(status: status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${order['receiver_name'] ?? ''} • ৳${order['grand_total'] ?? 0}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class FoodOwnerOrderDetailsScreen extends StatelessWidget {
  const FoodOwnerOrderDetailsScreen({
    super.key,
    required this.order,
    required this.onChanged,
  });

  final Map<String, dynamic> order;
  final Future<void> Function() onChanged;

  Future<void> _setStatus(BuildContext context, String status) async {
    try {
      await ApiClient(
        getToken: SessionStorage().getToken,
      ).post('/food/orders/${order['id']}/status', body: {'status': status});
      await onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অর্ডার স্ট্যাটাস আপডেট হয়েছে')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showDeliveryMap(BuildContext context) async {
    await _OwnerOrderCard(
      order: order,
      onChanged: onChanged,
    )._showDeliveryMap(context);
  }

  List<MapEntry<String, String>> _actionsFor(String status) =>
      _OwnerOrderCard(order: order, onChanged: onChanged)._actionsFor(status);

  @override
  Widget build(BuildContext context) {
    final status = '${order['status'] ?? 'pending'}';
    final items = (order['items'] as List?) ?? [];
    final actions = _actionsFor(status);
    final rider = order['rider'] is Map
        ? Map<String, dynamic>.from(order['rider'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: ModernAppBar(
        title: 'অর্ডার ডিটেইলস',
        subtitle: '${order['order_no'] ?? '#${order['id']}'}',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OwnerDetailCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${order['order_no'] ?? '#${order['id']}'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _FoodStatusChip(status: status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OwnerDetailCard(
            title: 'কাস্টমার',
            child: Column(
              children: [
                _OwnerDetailRow('নাম', order['receiver_name']),
                _OwnerDetailRow('মোবাইল', order['receiver_phone']),
                _OwnerDetailRow('ঠিকানা', order['delivery_address']),
                _OwnerDetailRow('এরিয়া', order['delivery_area']),
                if (order['delivery_lat'] != null &&
                    order['delivery_lng'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeliveryMap(context),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('ম্যাপে লোকেশন দেখুন'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OwnerDetailCard(
            title: 'খাবারের তালিকা',
            subtitle: '${items.length} টি আইটেম',
            child: Column(
              children: items.isEmpty
                  ? [const Text('আইটেম পাওয়া যায়নি')]
                  : items
                        .map(
                          (raw) => _OrderFoodLine(
                            item: Map<String, dynamic>.from(raw as Map),
                          ),
                        )
                        .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _OwnerDetailCard(
            title: 'বিল',
            child: _PriceBox(cart: order),
          ),
          const SizedBox(height: 12),
          _OwnerDetailCard(
            title: 'ডেলিভারি ও রাইডার',
            child: Column(
              children: [
                _OwnerDetailRow('রাইডার', rider['name']),
                _OwnerDetailRow('রাইডার মোবাইল', rider['phone']),
                _OwnerDetailRow('পেমেন্ট', order['payment_method']),
                _OwnerDetailRow('পেমেন্ট স্ট্যাটাস', order['payment_status']),
                _OwnerDetailRow(
                  'ট্রানজেকশন আইডি',
                  order['manual_transaction_id'],
                ),
                if ((order['payment_proof_photo_url'] ?? '')
                    .toString()
                    .isNotEmpty)
                  _PaymentProofPreview(
                    url: order['payment_proof_photo_url'].toString(),
                  ),
                _OwnerDetailRow('নোট', order['order_note']),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OwnerDetailCard(
              title: 'অর্ডার অ্যাকশন',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map(
                      (action) => action.key == 'rejected'
                          ? OutlinedButton(
                              onPressed: () => _setStatus(context, action.key),
                              child: Text(action.value),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _setStatus(context, action.key),
                              child: Text(action.value),
                            ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerDetailCard extends StatelessWidget {
  const _OwnerDetailCard({required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _OwnerDetailRow extends StatelessWidget {
  const _OwnerDetailRow(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class FoodCartScreen extends StatefulWidget {
  const FoodCartScreen({super.key});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/food/cart');
      setState(() => _cart = Map<String, dynamic>.from(data as Map));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _qty(int id, int q) async {
    if (q < 1) return;
    await _api.post('/food/cart/items/$id', body: {'quantity': q});
    _load();
  }

  Future<void> _remove(int id) async {
    await _api.delete('/food/cart/items/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = (_cart['items'] as List?) ?? [];
    return Scaffold(
      appBar: const ModernAppBar(
        title: '\u0986\u09ae\u09be\u09b0 \u0995\u09be\u09b0\u09cd\u099f',
        subtitle:
            '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u099a\u09c7\u0995 \u0995\u09b0\u09c1\u09a8',
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u09ae\u09cb\u099f \u09ac\u09bf\u09b2',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\u09f3${_cart['grand_total'] ?? 0}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 136,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FoodCheckoutScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          '\u099a\u09c7\u0995\u0986\u0989\u099f',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (items.isEmpty)
                    const _EmptyFoodState(
                      text:
                          '\u0995\u09be\u09b0\u09cd\u099f \u0996\u09be\u09b2\u09bf \u0986\u099b\u09c7',
                    ),
                  if (items.isNotEmpty) ...[
                    _FoodSectionHeader(
                      icon: Icons.shopping_bag_outlined,
                      title:
                          '\u0995\u09be\u09b0\u09cd\u099f\u09c7\u09b0 \u0996\u09be\u09ac\u09be\u09b0',
                      subtitle:
                          '${items.length} \u099f\u09bf item \u09af\u09cb\u0997 \u09b9\u09df\u09c7\u099b\u09c7',
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final id = (item['id'] as num).toInt();
                    final quantity = (item['quantity'] as num).toInt();
                    return _CartItemTile(
                      item: item,
                      onMinus: () => _qty(id, quantity - 1),
                      onPlus: () => _qty(id, quantity + 1),
                      onRemove: () => _remove(id),
                    );
                  }),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _PriceBox(cart: _cart),
                    const SizedBox(height: 90),
                  ],
                ],
              ),
            ),
    );
  }
}

class FoodCheckoutScreen extends StatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  State<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends State<FoodCheckoutScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _note = TextEditingController();
  final _manualTransactionId = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  Map<String, dynamic> _cart = {};
  List<dynamic> _addresses = [];
  int? _addressId;
  bool _loading = true;
  bool _placing = false;
  bool _locating = false;
  double? _deliveryLat;
  double? _deliveryLng;
  String? _locationStatus;
  String? _paymentMethod;
  XFile? _paymentProofPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    _address.dispose();
    _landmark.dispose();
    _note.dispose();
    _manualTransactionId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cart = await _api.get('/food/cart');
    final addresses = await _api.get('/food/addresses');
    setState(() {
      _cart = Map<String, dynamic>.from(cart as Map);
      _addresses = (addresses as List?) ?? [];
      final paymentOptions = (_cart['payment_options'] as List?) ?? [];
      if (paymentOptions.isNotEmpty &&
          !paymentOptions.any((option) => option['method'] == _paymentMethod)) {
        _paymentMethod = paymentOptions.first['method']?.toString();
      }
      final def = _addresses.where((a) => a['is_default'] == true).toList();
      _addressId = def.isNotEmpty
          ? (def.first['id'] as num).toInt()
          : (_addresses.isNotEmpty
                ? (_addresses.first['id'] as num).toInt()
                : null);
      _loading = false;
    });
  }

  Future<void> _saveAddress() async {
    final res = await _api.post(
      '/food/addresses',
      body: {
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.trim(),
        'area': _area.text.trim(),
        'address': _address.text.trim(),
        'landmark': _landmark.text.trim(),
        if (_deliveryLat != null) 'lat': _deliveryLat,
        if (_deliveryLng != null) 'lng': _deliveryLng,
        'is_default': true,
      },
    );
    final address = res['address'];
    setState(() => _addressId = (address['id'] as num).toInt());
    await _load();
  }

  Future<bool> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationStatus = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8 \u09ac\u09a8\u09cd\u09a7 \u0986\u099b\u09c7\u0964 \u0985\u09a8\u09c1\u0997\u09cd\u09b0\u09b9 \u0995\u09b0\u09c7 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8\u0964',
        );
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 permission \u09a8\u09be \u09a6\u09bf\u09b2\u09c7 delivery location \u09a8\u09c7\u0993\u09df\u09be \u09af\u09be\u09ac\u09c7 \u09a8\u09be\u0964',
        );
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 permission permanently \u09ac\u09a8\u09cd\u09a7 \u0986\u099b\u09c7\u0964 App settings \u09a5\u09c7\u0995\u09c7 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8\u0964',
        );
        await Geolocator.openAppSettings();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _deliveryLat = position.latitude;
        _deliveryLng = position.longitude;
        _locationStatus =
            '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09c7\u0993\u09df\u09be \u09b9\u09df\u09c7\u099b\u09c7: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
      return true;
    } catch (_) {
      setState(
        () => _locationStatus =
            '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09c7\u0993\u09df\u09be \u09af\u09be\u09df\u09a8\u09bf\u0964 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
      );
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _deliveryLat,
          initialLng: _deliveryLng,
          title: 'ডেলিভারি লোকেশন',
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _deliveryLat = picked.lat;
      _deliveryLng = picked.lng;
      _locationStatus =
          'ম্যাপ থেকে লোকেশন নেওয়া হয়েছে: ${picked.lat.toStringAsFixed(5)}, ${picked.lng.toStringAsFixed(5)}';
    });
  }

  Future<void> _pickPaymentProof() async {
    final image = await _paymentProofPicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    setState(() => _paymentProofPhoto = image);
  }

  Future<void> _place() async {
    if (_deliveryLat == null || _deliveryLng == null) {
      final ok = await _captureLocation();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09a4\u09c7 \u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09b2\u09be\u0997\u09ac\u09c7\u0964',
              ),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    if (_addressId == null) {
      if (_name.text.trim().isEmpty ||
          _phone.text.trim().isEmpty ||
          _address.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u09a8\u09be\u09ae, \u09ab\u09cb\u09a8 \u0993 \u09a0\u09bf\u0995\u09be\u09a8\u09be \u09a6\u09bf\u09a8',
            ),
          ),
        );
        return;
      }
      await _saveAddress();
    }
    setState(() => _placing = true);
    try {
      final isManualPayment =
          _paymentMethod == 'manual_bkash' || _paymentMethod == 'manual_nagad';
      final payload = {
        'food_address_id': _addressId,
        'order_type': 'delivery',
        'payment_method': _paymentMethod ?? 'cash_on_delivery',
        'order_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'delivery_lat': _deliveryLat,
        'delivery_lng': _deliveryLng,
        'delivery_map_url':
            'https://www.google.com/maps/search/?api=1&query=$_deliveryLat,$_deliveryLng',
        if (isManualPayment && _manualTransactionId.text.trim().isNotEmpty)
          'manual_transaction_id': _manualTransactionId.text.trim(),
      };
      final res = _paymentProofPhoto == null
          ? await _api.post('/food/checkout', body: payload)
          : await _api.postMultipart(
              '/food/checkout',
              fields: payload.map(
                (key, value) => MapEntry(key, value == null ? '' : '$value'),
              ),
              files: {'payment_proof_photo': _paymentProofPhoto!.path},
            );
      final order = res['order'] is Map
          ? Map<String, dynamic>.from(res['order'] as Map)
          : <String, dynamic>{};
      unawaited(
        MetaAppEventsService.instance.logPurchase(
          value:
              num.tryParse('${order['grand_total'] ?? _cart['grand_total']}') ??
              0,
          orderId: '${order['id'] ?? ''}',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              FoodOrderDetailsScreen(orderId: (order['id'] as num).toInt()),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: "\u099a\u09c7\u0995\u0986\u0989\u099f",
        subtitle:
            "\u09a0\u09bf\u0995\u09be\u09a8\u09be \u0993 \u09aa\u09c7\u09ae\u09c7\u09a8\u09cd\u099f",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _placing ? null : _place,
            child: Text(
              _placing
                  ? "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09b9\u099a\u09cd\u099b\u09c7..."
                  : "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09a8\u09ab\u09be\u09b0\u09cd\u09ae \u0995\u09b0\u09c1\u09a8",
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PriceBox(cart: _cart),
                const SizedBox(height: 14),
                _DeliveryLocationCard(
                  locating: _locating,
                  lat: _deliveryLat,
                  lng: _deliveryLng,
                  status: _locationStatus,
                  onTap: _captureLocation,
                  onPickMap: _pickLocationOnMap,
                ),
                const SizedBox(height: 14),
                Text(
                  "\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ..._addresses.map((a) {
                  final id = (a['id'] as num).toInt();
                  final selected = _addressId == id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _addressId = id),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a['receiver_name']} - ${a['receiver_phone']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a['address']}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  "\u09a8\u09a4\u09c1\u09a8 \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b0\u09bf\u09b8\u09bf\u09ad\u09be\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a8\u09ae\u09cd\u09ac\u09b0",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _area,
                  decoration: const InputDecoration(
                    labelText: "\u098f\u09b2\u09be\u0995\u09be",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b8\u09ae\u09cd\u09aa\u09c2\u09b0\u09cd\u09a3 \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _landmark,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b2\u09cd\u09af\u09be\u09a8\u09cd\u09a1\u09ae\u09be\u09b0\u09cd\u0995",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09cb\u099f",
                  ),
                ),
                const SizedBox(height: 12),
                CheckoutPaymentSection(
                  options: (_cart['payment_options'] as List?) ?? const [],
                  selectedMethod: _paymentMethod,
                  total: _cart['grand_total'],
                  onChanged: (method) =>
                      setState(() => _paymentMethod = method),
                ),
                if (_paymentMethod == 'manual_bkash' ||
                    _paymentMethod == 'manual_nagad') ...[
                  const SizedBox(height: 12),
                  _ManualPaymentProofCard(
                    transactionId: _manualTransactionId,
                    proof: _paymentProofPhoto,
                    onPick: _pickPaymentProof,
                    onRemove: () => setState(() => _paymentProofPhoto = null),
                  ),
                ],
              ],
            ),
    );
  }
}

class FoodOrdersScreen extends StatefulWidget {
  const FoodOrdersScreen({super.key});

  @override
  State<FoodOrdersScreen> createState() => _FoodOrdersScreenState();
}

class _FoodOrdersScreenState extends State<FoodOrdersScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.get('/food/orders');
    setState(() {
      _orders = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: '\u0986\u09ae\u09be\u09b0 \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
        subtitle:
            '\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09b8\u09cd\u099f\u09cd\u09af\u09be\u099f\u09be\u09b8',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _FoodSectionHeader(
                    icon: Icons.receipt_long_outlined,
                    title:
                        '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09b2\u09bf\u09b8\u09cd\u099f',
                    subtitle: _orders.isEmpty
                        ? '\u098f\u0996\u09a8\u09cb \u0995\u09cb\u09a8\u09cb \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09c7\u0987'
                        : '${_orders.length} \u099f\u09bf \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
                  ),
                  const SizedBox(height: 12),
                  if (_orders.isEmpty)
                    const _EmptyFoodState(
                      text:
                          '\u098f\u0996\u09a8\u09cb \u0995\u09cb\u09a8\u09cb \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09c7\u0987',
                    ),
                  ..._orders.map((raw) {
                    final order = Map<String, dynamic>.from(raw as Map);
                    return _OrderListCard(
                      order: order,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodOrderDetailsScreen(
                            orderId: (order['id'] as num).toInt(),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class FoodOrderDetailsScreen extends StatefulWidget {
  const FoodOrderDetailsScreen({super.key, required this.orderId});
  final int orderId;

  @override
  State<FoodOrderDetailsScreen> createState() => _FoodOrderDetailsScreenState();
}

class _FoodOrderDetailsScreenState extends State<FoodOrderDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  Map<String, dynamic> _order = {};
  bool _loading = true;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _api.get('/food/orders/${widget.orderId}');
    if (!mounted) return;
    setState(() {
      _order = Map<String, dynamic>.from(res as Map);
      _loading = false;
    });
  }

  Future<void> _openOrderMap() async {
    final deliveryLat = readDouble(_order['delivery_lat']);
    final deliveryLng = readDouble(_order['delivery_lng']);
    if (deliveryLat == null || deliveryLng == null) return;

    final restaurant = _order['restaurant'] is Map
        ? Map<String, dynamic>.from(_order['restaurant'] as Map)
        : <String, dynamic>{};
    final rider = _order['rider'] is Map
        ? Map<String, dynamic>.from(_order['rider'] as Map)
        : <String, dynamic>{};
    final markers = <AppMapMarker>[];
    final restaurantLat = readDouble(restaurant['lat']);
    final restaurantLng = readDouble(restaurant['lng']);
    if (restaurantLat != null && restaurantLng != null) {
      markers.add(
        AppMapMarker(
          lat: restaurantLat,
          lng: restaurantLng,
          label: restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
          icon: Icons.restaurant_rounded,
          color: Colors.deepOrange,
        ),
      );
    }
    markers.add(
      AppMapMarker(
        lat: deliveryLat,
        lng: deliveryLng,
        label: 'ডেলিভারি',
        icon: Icons.location_city_rounded,
      ),
    );
    final riderLat = readDouble(rider['last_lat']);
    final riderLng = readDouble(rider['last_lng']);
    if (riderLat != null && riderLng != null) {
      markers.add(
        AppMapMarker(
          lat: riderLat,
          lng: riderLng,
          label: rider['name']?.toString() ?? 'রাইডার',
          icon: Icons.delivery_dining,
          color: Colors.green,
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: riderLat ?? deliveryLat,
          initialLng: riderLng ?? deliveryLng,
          title: riderLat != null
              ? 'লাইভ ডেলিভারি ট্র্যাকিং'
              : 'ডেলিভারি ম্যাপ',
          readOnly: true,
          markers: markers,
        ),
      ),
    );
  }

  Future<void> _showOrderSupportSheet() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'অর্ডার সাহায্য',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'পেমেন্ট, ডেলিভারি বা খাবারের সমস্যা হলে এখানে জানান। সাপোর্ট টিম অর্ডারসহ বিস্তারিত দেখতে পারবে।',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(
                      labelText: 'সমস্যার ধরন',
                      hintText: 'যেমন: পেমেন্ট যাচাই, খাবার দেরি',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: message,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'বিস্তারিত লিখুন',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (subject.text.trim().isEmpty ||
                                  message.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('বিষয় ও বিস্তারিত লিখুন'),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                await _api.post(
                                  '/food/orders/${widget.orderId}/support-tickets',
                                  body: {
                                    'subject': subject.text.trim(),
                                    'message': message.text.trim(),
                                  },
                                );
                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'সাপোর্ট রিকোয়েস্ট পাঠানো হয়েছে',
                                    ),
                                  ),
                                );
                                await _load();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              } finally {
                                setSheetState(() => saving = false);
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.support_agent_rounded),
                      label: const Text('সাপোর্টে পাঠান'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    subject.dispose();
    message.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statuses = [
      'pending',
      'accepted',
      'preparing',
      'picked_up',
      'on_the_way',
      'delivered',
    ];
    final labels = _foodStatusLabels;
    final current = statuses.indexOf('${_order['status']}');
    final items = (_order['items'] as List?) ?? [];
    final existingReview = _order['review'] is Map
        ? Map<String, dynamic>.from(_order['review'] as Map)
        : null;
    final delivered = '${_order['status']}' == 'delivered';
    final hasMap =
        (_order['delivery_map_url']?.toString().isNotEmpty == true) ||
        (_order['delivery_lat'] != null && _order['delivery_lng'] != null);

    return Scaffold(
      appBar: const ModernAppBar(
        title:
            '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u099f\u09cd\u09b0\u09cd\u09af\u09be\u0995\u09bf\u0982',
        subtitle:
            '\u09b8\u09cd\u099f\u09cd\u09af\u09be\u099f\u09be\u09b8 \u0993 \u09ac\u09bf\u09b8\u09cd\u09a4\u09be\u09b0\u09bf\u09a4',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TinyIconBox(icon: Icons.receipt_long_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_order['order_no'] ?? ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_order['restaurant']?['name'] ?? ''}',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _FoodStatusChip(
                              status: '${_order['status'] ?? 'pending'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _OrderMiniMetric(
                                label: '\u09ae\u09cb\u099f',
                                value: '\u09f3${_order['grand_total'] ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OrderMiniMetric(
                                label:
                                    '\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf',
                                value: '\u09f3${_order['delivery_fee'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        if (hasMap) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openOrderMap,
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text(
                                'অ্যাপের ম্যাপে ডেলিভারি দেখুন',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FoodSectionHeader(
                    icon: Icons.route_outlined,
                    title:
                        '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09aa\u09cd\u09b0\u0997\u09cd\u09b0\u09c7\u09b8',
                    subtitle:
                        labels['${_order['status']}'] ?? '${_order['status']}',
                  ),
                  const SizedBox(height: 12),
                  _FoodStatusTimeline(
                    statuses: statuses,
                    labels: labels,
                    currentIndex: current,
                  ),
                  const SizedBox(height: 14),
                  _FoodSectionHeader(
                    icon: Icons.restaurant_menu_rounded,
                    title:
                        '\u0985\u09b0\u09cd\u09a1\u09be\u09b0\u09c7\u09b0 \u0996\u09be\u09ac\u09be\u09b0',
                    subtitle: '${items.length} \u099f\u09bf item',
                  ),
                  const SizedBox(height: 10),
                  ...items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    return _OrderFoodLine(item: item);
                  }),
                  const SizedBox(height: 8),
                  _PriceBox(cart: _order),
                  const SizedBox(height: 14),
                  _OrderPaymentInfoCard(order: _order),
                  const SizedBox(height: 14),
                  _OrderDeliveryInfoCard(
                    order: _order,
                    onOpenMap: _openOrderMap,
                  ),
                  const SizedBox(height: 14),
                  _OrderHelpCard(
                    order: _order,
                    onReportIssue: _showOrderSupportSheet,
                  ),
                  const SizedBox(height: 14),
                  _FoodReviewsPanel(
                    restaurantId: (_order['restaurant_id'] as num?)?.toInt(),
                    foodOrderId: (_order['id'] as num?)?.toInt(),
                    orderItems: items,
                    reviews: existingReview == null
                        ? const []
                        : [existingReview],
                    canSubmit: delivered && existingReview == null,
                    lockedMessage: !delivered
                        ? '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09b8\u09ae\u09cd\u09aa\u09a8\u09cd\u09a8 \u09b9\u09b2\u09c7 \u09b0\u09bf\u09ad\u09bf\u0989 \u09a6\u09bf\u09a4\u09c7 \u09aa\u09be\u09b0\u09ac\u09c7\u09a8\u0964'
                        : '\u098f\u0987 \u0985\u09b0\u09cd\u09a1\u09be\u09b0\u09c7\u09b0 \u099c\u09a8\u09cd\u09af \u0986\u09aa\u09a8\u09bf \u0987\u09a4\u09bf\u09ae\u09a7\u09cd\u09af\u09c7 \u09b0\u09bf\u09ad\u09bf\u0989 \u09a6\u09bf\u09df\u09c7\u099b\u09c7\u09a8\u0964',
                    onChanged: _load,
                  ),
                ],
              ),
            ),
    );
  }
}

const Map<String, String> _foodStatusLabels = {
  'pending':
      '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09aa\u09be\u09a0\u09be\u09a8\u09cb \u09b9\u09df\u09c7\u099b\u09c7',
  'accepted':
      '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09bf\u09df\u09c7\u099b\u09c7',
  'preparing':
      '\u0996\u09be\u09ac\u09be\u09b0 \u09a4\u09c8\u09b0\u09bf \u09b9\u099a\u09cd\u099b\u09c7',
  'picked_up':
      '\u09b0\u09be\u0987\u09a1\u09be\u09b0 \u0996\u09be\u09ac\u09be\u09b0 \u09a8\u09bf\u09df\u09c7\u099b\u09c7',
  'on_the_way': '\u09aa\u09a5\u09c7 \u0986\u099b\u09c7',
  'delivered':
      '\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09b8\u09ae\u09cd\u09aa\u09a8\u09cd\u09a8',
  'cancelled':
      '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09ac\u09be\u09a4\u09bf\u09b2',
  'rejected':
      '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09c7\u0993\u09df\u09be \u09b9\u09df\u09a8\u09bf',
};

class _OrderPaymentInfoCard extends StatelessWidget {
  const _OrderPaymentInfoCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final method = '${order['payment_method'] ?? 'cash_on_delivery'}';
    final label = switch (method) {
      'manual_bkash' => 'ম্যানুয়াল bKash',
      'manual_nagad' => 'ম্যানুয়াল Nagad',
      'online' => 'অনলাইন পেমেন্ট',
      _ => 'ক্যাশ অন ডেলিভারি',
    };
    final transactionId =
        order['manual_transaction_id'] ?? order['transaction_id'];
    final proofUrl =
        order['payment_proof_photo_url'] ??
        order['payment_proof'] ??
        order['manual_payment_proof'];

    return _SoftInfoCard(
      icon: Icons.payments_outlined,
      title: 'পেমেন্ট তথ্য',
      children: [
        _OrderInfoRow('মেথড', label),
        _OrderInfoRow('স্ট্যাটাস', '${order['payment_status'] ?? 'pending'}'),
        if (transactionId != null && '$transactionId'.trim().isNotEmpty)
          _OrderInfoRow('ট্রানজেকশন আইডি', '$transactionId'),
        if (proofUrl != null && '$proofUrl'.trim().isNotEmpty)
          _OrderInfoRow('পেমেন্ট প্রুফ', 'জমা দেওয়া হয়েছে'),
        if (proofUrl != null && '$proofUrl'.trim().isNotEmpty)
          _PaymentProofPreview(url: '$proofUrl'),
        if (method == 'cash_on_delivery')
          const _PolicyNote(
            text:
                'রাইডার ডেলিভারির সময় টাকা সংগ্রহ করবে। খাবার নেওয়ার আগে টাকা দেওয়ার দরকার নেই।',
          ),
      ],
    );
  }
}

class _ManualPaymentProofCard extends StatelessWidget {
  const _ManualPaymentProofCard({
    required this.transactionId,
    required this.proof,
    required this.onPick,
    required this.onRemove,
  });

  final TextEditingController transactionId;
  final XFile? proof;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TinyIconBox(icon: Icons.verified_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ম্যানুয়াল পেমেন্ট প্রুফ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transactionId,
              decoration: const InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'যেমন: 9AB12CDE34',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      proof == null
                          ? 'স্ক্রিনশট প্রুফ optional, দিলে যাচাই করা সহজ হবে।'
                          : proof!.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (proof != null)
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Remove',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  proof == null
                      ? 'Screenshot proof যোগ করুন'
                      : 'Screenshot পরিবর্তন করুন',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProofPreview extends StatelessWidget {
  const _PaymentProofPreview({required this.url});
  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _open,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Text('প্রুফ ইমেজ লোড হয়নি'),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _OrderDeliveryInfoCard extends StatelessWidget {
  const _OrderDeliveryInfoCard({required this.order, required this.onOpenMap});
  final Map<String, dynamic> order;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final rider = order['rider'] is Map
        ? Map<String, dynamic>.from(order['rider'] as Map)
        : <String, dynamic>{};
    final hasRider = rider.isNotEmpty && rider['id'] != null;
    final distance =
        order['delivery_distance_km'] ?? order['route_distance_km'];
    final lastUpdated = _friendlyTime(rider['last_location_at']);

    return _SoftInfoCard(
      icon: Icons.delivery_dining_rounded,
      title: 'ডেলিভারি ও ট্র্যাকিং',
      children: [
        _OrderInfoRow(
          'রেস্টুরেন্ট থেকে দূরত্ব',
          distance == null ? 'হিসাব করা হয়নি' : '$distance KM',
        ),
        _OrderInfoRow('ডেলিভারি চার্জ', '৳${order['delivery_fee'] ?? 0}'),
        if (hasRider) ...[
          _OrderInfoRow('রাইডার', '${rider['name'] ?? 'নাম নেই'}'),
          _OrderInfoRow('ফোন', '${rider['phone'] ?? 'নেই'}'),
          _OrderInfoRow(
            'লাইভ লোকেশন',
            lastUpdated == null
                ? 'লোকেশন আপডেট অপেক্ষমাণ'
                : 'শেষ আপডেট $lastUpdated',
          ),
        ] else
          const _PolicyNote(
            text:
                'রেস্টুরেন্ট অর্ডার নেওয়ার পর কাছাকাছি রাইডারদের কাছে রিকোয়েস্ট যাবে। কেউ গ্রহণ করলে এখানে রাইডার তথ্য দেখা যাবে।',
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(hasRider ? 'লাইভ ম্যাপে দেখুন' : 'ডেলিভারি ম্যাপ দেখুন'),
        ),
      ],
    );
  }
}

class _OrderHelpCard extends StatelessWidget {
  const _OrderHelpCard({required this.order, required this.onReportIssue});
  final Map<String, dynamic> order;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    final tickets = (order['support_tickets'] as List?) ?? const [];
    final canCancel = ['pending', 'accepted'].contains('${order['status']}');

    return _SoftInfoCard(
      icon: Icons.help_outline_rounded,
      title: 'সাহায্য ও নীতিমালা',
      children: [
        _PolicyNote(
          text: canCancel
              ? 'রেস্টুরেন্ট খাবার প্রস্তুত শুরু করার আগে অর্ডার বাতিল করা যাবে।'
              : 'খাবার প্রস্তুত/রাইডার পিকআপের পর বাতিলের জন্য সাপোর্টে যোগাযোগ করুন।',
        ),
        const SizedBox(height: 10),
        _OrderInfoRow('সাপোর্ট রিকোয়েস্ট', '${tickets.length} টি'),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onReportIssue,
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('অর্ডার নিয়ে সাহায্য নিন'),
          ),
        ),
      ],
    );
  }
}

class _SoftInfoCard extends StatelessWidget {
  const _SoftInfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TinyIconBox(icon: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 22, color: scheme.outlineVariant),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PolicyNote extends StatelessWidget {
  const _PolicyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(text),
  );
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String? _friendlyTime(dynamic value) {
  if (value == null || '$value'.trim().isEmpty) return null;
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) return '$value';
  final diff = DateTime.now().difference(parsed.toLocal());
  if (diff.inSeconds < 60) return 'এইমাত্র';
  if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
  if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
  return '${parsed.day}/${parsed.month}/${parsed.year}';
}

class _FoodSectionHeader extends StatelessWidget {
  const _FoodSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _TinyIconBox(icon: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyIconBox extends StatelessWidget {
  const _TinyIconBox({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: scheme.primary),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });
  final Map<String, dynamic> item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _FoodImage(
              url: item['image_url']?.toString(),
              height: 64,
              width: 64,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u09f3${item['unit_price']} x ${item['quantity']}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if ((item['note'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item['note']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SmallCircleButton(
                      icon: Icons.remove_rounded,
                      onTap: onMinus,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _SmallCircleButton(icon: Icons.add_rounded, onTap: onPlus),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SmallCircleButton extends StatelessWidget {
  const _SmallCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17),
    ),
  );
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({required this.order, required this.onTap});
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order['order_no'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _FoodStatusChip(status: '${order['status'] ?? 'pending'}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order['restaurant']?['name'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '\u09f3${order['grand_total'] ?? 0}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\u09ac\u09bf\u09b8\u09cd\u09a4\u09be\u09b0\u09bf\u09a4',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: scheme.primary,
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

class _FoodStatusChip extends StatelessWidget {
  const _FoodStatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = status == 'delivered';
    final cancelled = status == 'cancelled' || status == 'rejected';
    final bg = cancelled
        ? scheme.errorContainer.withValues(alpha: 0.65)
        : (complete
              ? Colors.green.withValues(alpha: 0.12)
              : scheme.primaryContainer.withValues(alpha: 0.45));
    final fg = cancelled
        ? scheme.onErrorContainer
        : (complete ? Colors.green.shade800 : scheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _foodStatusLabels[status] ?? status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _OrderMiniMetric extends StatelessWidget {
  const _OrderMiniMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FoodStatusTimeline extends StatelessWidget {
  const _FoodStatusTimeline({
    required this.statuses,
    required this.labels,
    required this.currentIndex,
  });
  final List<String> statuses;
  final Map<String, String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < statuses.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: i <= currentIndex
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        i <= currentIndex
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 13,
                        color: i <= currentIndex
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (i != statuses.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: i < currentIndex
                            ? scheme.primary.withValues(alpha: 0.5)
                            : scheme.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 1,
                      bottom: i == statuses.length - 1 ? 0 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels[statuses[i]] ?? statuses[i],
                          style: TextStyle(
                            fontWeight: i <= currentIndex
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: i <= currentIndex
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          i <= currentIndex
                              ? '\u09b8\u09ae\u09cd\u09aa\u09a8\u09cd\u09a8/\u099a\u09b2\u09ae\u09be\u09a8'
                              : '\u0985\u09aa\u09c7\u0995\u09cd\u09b7\u09be\u09df',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderFoodLine extends StatelessWidget {
  const _OrderFoodLine({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item['name']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${item['quantity']} x \u09f3${item['unit_price']}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLocationCard extends StatelessWidget {
  const _DeliveryLocationCard({
    required this.locating,
    required this.lat,
    required this.lng,
    required this.status,
    required this.onTap,
    required this.onPickMap,
  });

  final bool locating;
  final double? lat;
  final double? lng;
  final String? status;
  final Future<bool> Function() onTap;
  final VoidCallback onPickMap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLocation = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(
          color: hasLocation
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.location_on_rounded
                    : Icons.my_location_rounded,
                color: hasLocation ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09bf\u09a8',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasLocation
                          ? '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09c7\u0993\u09df\u09be \u09b9\u09df\u09c7\u099b\u09c7\u0964'
                          : '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09a4\u09c7 \u098f\u099f\u09bf \u09ac\u09be\u09a7\u09cd\u09af\u09a4\u09be\u09ae\u09c2\u09b2\u0995\u0964',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            Text(
              status!,
              style: TextStyle(
                color: hasLocation ? scheme.primary : scheme.error,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: locating ? null : onTap,
                  icon: locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: LogoLoader(size: 18),
                        )
                      : const Icon(Icons.gps_fixed_rounded),
                  label: Text(
                    locating
                        ? 'নেওয়া হচ্ছে...'
                        : (hasLocation ? 'Current আপডেট' : 'Current location'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: locating ? null : onPickMap,
                  icon: const Icon(Icons.map_outlined),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCart, required this.cartCount});
  final VoidCallback onCart;
  final int cartCount;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F1D1D).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'ফুড ডেলিভারি',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "\u09ad\u09cb\u09b2\u09be\u09b0 \u0996\u09be\u09ac\u09be\u09b0 \u098f\u0996\u09a8 \u0986\u09b0\u0993 \u09b8\u09b9\u099c",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "\u09aa\u099b\u09a8\u09cd\u09a6\u09c7\u09b0 \u0996\u09be\u09ac\u09be\u09b0 \u09ac\u09be\u099b\u09be\u0987 \u0995\u09b0\u09c1\u09a8, \u09a6\u09cd\u09b0\u09c1\u09a4 \u0995\u09be\u09b0\u09cd\u099f\u09c7 \u09a8\u09bf\u09a8\u0964",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onCart,
                  color: const Color(0xFFB91C1C),
                  icon: _CartBadgeIcon(count: cartCount, size: 21),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodDiscoveryStrip extends StatelessWidget {
  const _FoodDiscoveryStrip({
    required this.onOrders,
    required this.onOwner,
    required this.onRider,
  });

  final VoidCallback onOrders;
  final VoidCallback onOwner;
  final VoidCallback onRider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FoodQuickAction(
            icon: Icons.receipt_long_rounded,
            label: 'অর্ডার',
            onTap: onOrders,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FoodQuickAction(
            icon: Icons.storefront_rounded,
            label: 'রেস্টুরেন্ট',
            onTap: onOwner,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FoodQuickAction(
            icon: Icons.delivery_dining_rounded,
            label: 'রাইডার',
            onTap: onRider,
          ),
        ),
      ],
    );
  }
}

class _FoodQuickAction extends StatelessWidget {
  const _FoodQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFD7C2).withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39150D).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFB91C1C), size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF23130F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodSectionTitle extends StatelessWidget {
  const _FoodSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFB91C1C),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF23130F),
          ),
        ),
      ],
    );
  }
}

class _CartBadgeIcon extends StatelessWidget {
  const _CartBadgeIcon({required this.count, this.size = 24});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.shopping_bag_outlined, size: size),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FoodBannerStrip extends StatelessWidget {
  const _FoodBannerStrip({
    required this.banners,
    required this.controller,
    required this.index,
    required this.onChanged,
    required this.onTap,
  });

  final List<dynamic> banners;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 146,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onChanged,
            itemBuilder: (context, i) {
              final banner = Map<String, dynamic>.from(banners[i] as Map);
              final title = '${banner['title'] ?? ''}';
              final subtitle =
                  '${banner['subtitle'] ?? banner['details'] ?? ''}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: scheme.surface,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(
                      color: const Color(0xFFFFD7C2).withValues(alpha: 0.85),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onTap(banner['link_url']?.toString()),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _FoodImage(
                          url: banner['image_url']?.toString(),
                          height: 146,
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFB91C1C,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFFB91C1C),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF23130F),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (subtitle.trim().isNotEmpty)
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFFB91C1C),
                                  size: 18,
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
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFB91C1C)
                    : scheme.outlineVariant.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FoodReviewsPanel extends StatefulWidget {
  const _FoodReviewsPanel({
    required this.reviews,
    required this.onChanged,
    this.restaurantId,
    this.foodItemId,
    this.foodOrderId,
    this.orderItems = const [],
    this.canSubmit = false,
    this.lockedMessage,
  });

  final int? restaurantId;
  final int? foodItemId;
  final int? foodOrderId;
  final List<dynamic> orderItems;
  final bool canSubmit;
  final String? lockedMessage;
  final List<dynamic> reviews;
  final Future<void> Function() onChanged;

  @override
  State<_FoodReviewsPanel> createState() => _FoodReviewsPanelState();
}

class _FoodReviewsPanelState extends State<_FoodReviewsPanel> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _comment = TextEditingController();
  int _rating = 5;
  int? _selectedFoodItemId;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.canSubmit || widget.foodOrderId == null) return;
    setState(() => _saving = true);
    try {
      await _api.post(
        '/food/reviews',
        body: {
          if (widget.restaurantId != null) 'restaurant_id': widget.restaurantId,
          if ((widget.foodItemId ?? _selectedFoodItemId) != null)
            'food_item_id': widget.foodItemId ?? _selectedFoodItemId,
          'food_order_id': widget.foodOrderId,
          'rating': _rating,
          'comment': _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        },
      );
      _comment.clear();
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u09b0\u09bf\u09ad\u09bf\u0989 \u09b8\u09c7\u09ad \u09b9\u09df\u09c7\u099b\u09c7',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleReviews = widget.reviews
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final orderedItems = widget.orderItems
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodSectionHeader(
            icon: Icons.rate_review_outlined,
            title:
                '\u09b0\u09bf\u09ad\u09bf\u0989 \u0993 \u09b0\u09c7\u099f\u09bf\u0982',
            subtitle: visibleReviews.isEmpty
                ? '\u098f\u0996\u09a8\u09cb \u09b0\u09bf\u09ad\u09bf\u0989 \u09a8\u09c7\u0987'
                : '${visibleReviews.length} \u099f\u09bf \u09b0\u09bf\u09ad\u09bf\u0989',
          ),
          const SizedBox(height: 14),
          if (!widget.canSubmit)
            _InfoNote(
              text:
                  widget.lockedMessage ??
                  '\u09b0\u09bf\u09ad\u09bf\u0989 \u09a6\u09bf\u09a4\u09c7 \u0986\u0997\u09c7 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09c7 \u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09b8\u09ae\u09cd\u09aa\u09a8\u09cd\u09a8 \u09b9\u09a4\u09c7 \u09b9\u09ac\u09c7\u0964',
            )
          else ...[
            if (orderedItems.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                initialValue: _selectedFoodItemId,
                decoration: const InputDecoration(
                  labelText:
                      '\u09b0\u09bf\u09ad\u09bf\u0989 \u0995\u09be\u09b0 \u099c\u09a8\u09cd\u09af',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f',
                    ),
                  ),
                  ...orderedItems.map(
                    (item) => DropdownMenuItem<int?>(
                      value: (item['food_item_id'] as num?)?.toInt(),
                      child: Text(
                        '${item['name'] ?? '\u0996\u09be\u09ac\u09be\u09b0'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedFoodItemId = value),
              ),
              const SizedBox(height: 10),
            ],
            _StarPicker(
              value: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText:
                    '\u0986\u09aa\u09a8\u09be\u09b0 \u09ae\u09a4\u09be\u09ae\u09a4',
                hintText:
                    '\u0996\u09be\u09ac\u09be\u09b0, \u09b8\u09c7\u09ac\u09be \u09ac\u09be \u0985\u09ad\u09bf\u099c\u09cd\u099e\u09a4\u09be \u09b2\u09bf\u0996\u09c1\u09a8',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _saving
                      ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                      : '\u09b0\u09bf\u09ad\u09bf\u0989 \u09a6\u09bf\u09a8',
                ),
              ),
            ),
          ],
          if (visibleReviews.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...visibleReviews.map((review) => _FoodReviewCard(review: review)),
          ],
        ],
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          '\u09b0\u09c7\u099f\u09bf\u0982',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        ...List.generate(5, (index) {
          final star = index + 1;
          return IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(star),
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber.shade700,
            ),
          );
        }),
      ],
    );
  }
}

class _FoodReviewCard extends StatelessWidget {
  const _FoodReviewCard({required this.review, this.action});
  final Map<String, dynamic> review;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = Map<String, dynamic>.from((review['user'] as Map?) ?? {});
    final item = Map<String, dynamic>.from((review['food_item'] as Map?) ?? {});
    final reply = '${review['owner_reply'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials('${user['name'] ?? 'U'}'),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user['name'] ?? '\u0995\u09be\u09b8\u09cd\u099f\u09ae\u09be\u09b0'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (item.isNotEmpty)
                      Text(
                        '${item['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _MiniPill('\u2605 ${review['rating'] ?? 0}'),
            ],
          ),
          if ('${review['comment'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Text('${review['comment']}', style: const TextStyle(height: 1.35)),
          ],
          if (review['is_verified_order'] == true) ...[
            const SizedBox(height: 8),
            _MiniPill(
              '\u09ad\u09c7\u09b0\u09bf\u09ab\u09be\u0987\u09a1 \u0985\u09b0\u09cd\u09a1\u09be\u09b0',
            ),
          ],
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f\u09c7\u09b0 \u0989\u09a4\u09cd\u09a4\u09b0',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reply, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      ),
    );
  }

  static String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'U';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}

class _RestaurantShowcaseCard extends StatelessWidget {
  const _RestaurantShowcaseCard({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39150D).withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _FoodImage(
                    url: data['image_url']?.toString(),
                    height: 64,
                    width: double.infinity,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '★ ${data['rating'] ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF23130F),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${data['address'] ?? 'ভোলা'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "${data['delivery_time'] ?? '৩০-৫০ মিনিট'}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFFB91C1C),
                          size: 18,
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

class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final price = item['discount_price'] ?? item['price'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _FoodImage(
            url: item['image_url']?.toString(),
            width: 72,
            height: 72,
          ),
        ),
        title: Text(
          '${item['name']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item['description'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "\u09f3$price",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.add_circle_outline),
          ],
        ),
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({
    this.url,
    this.width = double.infinity,
    required this.height,
  });
  final String? url;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.restaurant_menu_rounded, size: 34),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 16), label: Text(text));
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: options
            .map(
              (o) => ChoiceChip(
                selected: value == o,
                label: Text(o),
                onSelected: (_) => onChanged(o),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.cart});
  final Map<String, dynamic> cart;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _priceRow(
            "\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u09a6\u09be\u09ae",
            cart['items_total'],
          ),
          _priceRow(
            "\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u099a\u09be\u09b0\u09cd\u099c",
            cart['delivery_fee'],
          ),
          if ((num.tryParse("${cart['discount_amount'] ?? 0}") ?? 0) > 0)
            _priceRow("\u099b\u09be\u09dc", "-${cart['discount_amount']}"),
          const Divider(),
          _priceRow("\u09ae\u09cb\u099f", cart['grand_total'], strong: true),
        ],
      ),
    ),
  );
  Widget _priceRow(String label, dynamic value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Text(
              "\u09f3${value ?? 0}",
              style: TextStyle(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text),
  );
}

class _EmptyFoodState extends StatelessWidget {
  const _EmptyFoodState({
    this.text =
        "\u0995\u09cb\u09a8\u09cb \u09a4\u09a5\u09cd\u09af \u09aa\u09be\u0993\u09df\u09be \u09af\u09be\u09df\u09a8\u09bf",
  });
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(28), child: Text(text)),
  );
}
