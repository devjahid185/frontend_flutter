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
import '../common/image_upload_preview.dart';
import 'rider_dashboard_screen.dart';
import 'widgets/cart_fly_overlay.dart';
import 'widgets/checkout_payment_section.dart';
import 'widgets/food_product_card.dart';

part 'screens/restaurant_details_screen.dart';
part 'screens/food_item_details_screen.dart';
part 'screens/cart_checkout_screens.dart';

const _restaurantManageBg = AppColors.surfaceAlt;
const _restaurantManageGreen = AppColors.teal;
const _restaurantManageBorder = AppColors.border;

bool _isTruthy(dynamic value) {
  if (value == true || value == 1) return true;
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}

InputDecorationTheme _restaurantManageInputDecorationTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: _restaurantManageBorder),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: _restaurantManageGreen, width: 1.4),
    ),
    labelStyle: const TextStyle(color: AppColors.inkMuted5, fontSize: 13),
    hintStyle: const TextStyle(color: AppColors.inkMuted7, fontSize: 13),
  );
}

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
    final categories = (_home['categories'] as List?) ?? [];
    final banners = (_home['banners'] as List?) ?? [];
    final featuredRestaurants = (_home['featured_restaurants'] as List?) ?? [];
    final promotedItems = (_home['promoted_items'] as List?) ?? [];
    final areas = ((_home['areas'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ---- Flat, pinned header --------------------------------------
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: AppColors.ink.withValues(alpha: 0.08),
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              toolbarHeight: 72,
              titleSpacing: 16,
              title: const _FoodAppBarTitle(),
              actions: [
                _HeaderIconButton(
                  tooltip: 'অর্ডার',
                  icon: Icons.receipt_long_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'আরও',
                  color: AppColors.surface,
                  surfaceTintColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.ink,
                  ),
                  onSelected: (value) {
                    if (value == 'owner') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FoodOwnerDashboardScreen(),
                        ),
                      );
                    } else if (value == 'rider') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RiderDashboardScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'owner',
                      child: _FoodAppBarMenuItem(
                        icon: Icons.storefront_outlined,
                        label: 'রেস্টুরেন্ট ম্যানেজ',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rider',
                      child: _FoodAppBarMenuItem(
                        icon: Icons.delivery_dining_rounded,
                        label: 'রাইডার',
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _HeaderIconButton(
                    tooltip: 'কার্ট',
                    onPressed: _openCart,
                    child: AnimatedScale(
                      key: _cartButtonKey,
                      scale: _cartPulse ? 1.18 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: _CartBadgeIcon(count: _cartCount),
                    ),
                  ),
                ),
              ],
            ),

            // ---- Hero promo card -------------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: _HeroCard(onCart: _openCart, cartCount: _cartCount),
                ),
              ),
            ),

            // ---- Quick actions ----------------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _FoodDiscoveryStrip(
                  onOrders: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodOrdersScreen()),
                  ),
                  onOwner: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FoodOwnerDashboardScreen(),
                    ),
                  ),
                  onRider: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RiderDashboardScreen(),
                    ),
                  ),
                ),
              ),
            ),

            // ---- Search + filter toggle --------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadow.card,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.inkMuted,
                        size: 20,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _loadItemsRealtime(),
                          style: const TextStyle(fontSize: 14.5),
                          decoration: const InputDecoration(
                            hintText: 'রেস্টুরেন্ট বা খাবার খুঁজুন',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      PressableScale(
                        onTap: () =>
                            setState(() => _filtersOpen = !_filtersOpen),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _filtersOpen
                                ? AppColors.primary
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: Icon(
                              _filtersOpen
                                  ? Icons.close_rounded
                                  : Icons.tune_rounded,
                              key: ValueKey(_filtersOpen),
                              size: 19,
                              color: _filtersOpen
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Collapsible filter panel ------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: !_filtersOpen
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _area.isEmpty ? null : _area,
                                  decoration: const InputDecoration(
                                    labelText: 'এলাকা',
                                  ),
                                  items: areas
                                      .map(
                                        (a) => DropdownMenuItem(
                                          value: a,
                                          child: Text(a),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _area = v ?? ''),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue: _categoryId.isEmpty
                                      ? null
                                      : _categoryId,
                                  decoration: const InputDecoration(
                                    labelText: 'খাবার ক্যাটাগরি',
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
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.ink,
                                          side: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => setState(() {
                                          _area = '';
                                          _categoryId = '';
                                        }),
                                        child: const Text('ক্লিয়ার'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: _load,
                                        child: const Text('দেখুন'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // ---- Sticky category bar ------------------------------------------
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryBar(
                height: 62,
                child: Container(
                  color: AppColors.surfaceAlt,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: SizedBox(
                    height: 40,
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
                          label: Text(isAll ? "সব" : "${item['name']}"),
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink,
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
                ),
              ),
            ),

            // ---- Banner carousel ------------------------------------------------
            if (banners.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _FoodBannerStrip(
                    banners: banners,
                    controller: _bannerController,
                    index: _bannerIndex,
                    onChanged: (value) => setState(() => _bannerIndex = value),
                    onTap: _openExternal,
                  ),
                ),
              ),

            // ---- Featured restaurants -------------------------------------------
            if (featuredRestaurants.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FoodSectionTitle(title: 'ফিচার্ড রেস্টুরেন্ট'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 156,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredRestaurants.take(10).length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final r = Map<String, dynamic>.from(
                              featuredRestaurants[index] as Map,
                            );
                            return SizedBox(
                              width: 232,
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
                  ),
                ),
              ),

            // ---- Today's promotions ---------------------------------------------
            if (promotedItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FoodSectionTitle(title: 'আজকের প্রমোশন'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 228,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: promotedItems.take(12).length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = Map<String, dynamic>.from(
                              promotedItems[index] as Map,
                            );
                            final restaurant = item['restaurant'] is Map
                                ? Map<String, dynamic>.from(
                                    item['restaurant'] as Map,
                                  )
                                : <String, dynamic>{};
                            return SizedBox(
                              width: 178,
                              child: FoodProductCard(
                                item: item,
                                heroTagPrefix: 'food-promo-image',
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FoodItemDetailsScreen(
                                        item: item,
                                        heroTagPrefix: 'food-promo-image',
                                      ),
                                    ),
                                  );
                                  _loadCartCount();
                                },
                                onRestaurantTap: restaurant['id'] == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FoodRestaurantDetailsScreen(
                                                id: (restaurant['id'] as num)
                                                    .toInt(),
                                              ),
                                        ),
                                      ),
                                onAdd: (buttonContext) =>
                                    _addItemToCart(buttonContext, item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ---- "খাবার" heading + live count ------------------------------------
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'খাবার',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Flexible(
                      child: AnimatedCountLabel(
                        value: _items.length,
                        suffix: ' টি পাওয়া গেছে',
                        style: const TextStyle(
                          color: AppColors.inkMuted2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Food grid --------------------------------------------------------
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: LogoLoader(size: 22),
                  ),
                ),
              ),
            if (!_loading && _items.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptyFoodState(text: 'খাবার পাওয়া যায়নি'),
              ),
            if (!_loading && _items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 228,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = Map<String, dynamic>.from(
                      _items[index] as Map,
                    );
                    final restaurant = item['restaurant'] is Map
                        ? Map<String, dynamic>.from(item['restaurant'] as Map)
                        : <String, dynamic>{};
                    return FoodProductCard(
                      item: item,
                      heroTagPrefix: 'food-grid-image',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FoodItemDetailsScreen(
                              item: item,
                              heroTagPrefix: 'food-grid-image',
                            ),
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
                  }, childCount: _items.length),
                ),
              ),

            // ---- Nearby restaurants -------------------------------------------------
            if (_restaurants.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// Pinned category-chip bar used at the top of the food grid — kept on
/// screen while the list scrolls beneath it so switching categories never
/// requires scrolling back up.
class _StickyCategoryBar extends SliverPersistentHeaderDelegate {
  const _StickyCategoryBar({required this.child, required this.height});

  final Widget child;
  final double height;

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
      color: AppColors.surfaceAlt,
      elevation: overlapsContent ? 1.5 : 0,
      shadowColor: AppColors.ink.withValues(alpha: 0.1),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryBar oldDelegate) => true;
}

class FoodOwnerDashboardScreen extends StatefulWidget {
  const FoodOwnerDashboardScreen({super.key});

  @override
  State<FoodOwnerDashboardScreen> createState() =>
      _FoodOwnerDashboardScreenState();
}

class _RestaurantManageHeader extends StatelessWidget {
  const _RestaurantManageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FadeSlideIn(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OwnerHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _OwnerHeaderButton(icon: icon),
          ],
        ),
      ),
    );
  }
}

class _OwnerHeaderButton extends StatelessWidget {
  const _OwnerHeaderButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _restaurantManageBorder),
          boxShadow: AppShadow.card,
        ),
        child: Icon(icon, size: 19, color: _restaurantManageGreen),
      ),
    );
  }
}

class _RestaurantManageStickyTabBar extends SliverPersistentHeaderDelegate {
  const _RestaurantManageStickyTabBar({
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

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
    return SizedBox(
      height: height,
      child: Material(
        color: _restaurantManageBg,
        elevation: overlapsContent ? 1.5 : 0,
        shadowColor: AppColors.ink.withValues(alpha: 0.1),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RestaurantManageStickyTabBar oldDelegate) =>
      true;
}

class _OwnerDashboardCard extends StatelessWidget {
  const _OwnerDashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _restaurantManageGreen),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerDashboardSectionHeader extends StatelessWidget {
  const _OwnerDashboardSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _restaurantManageGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _OwnerDashboardMiniStat extends StatelessWidget {
  const _OwnerDashboardMiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('owner-mini-$label-$value'),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.pop,
      builder: (context, v, child) => Transform.scale(
        scale: v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt3,
          border: Border.all(color: _restaurantManageBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: _restaurantManageGreen),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerTabActionButton extends StatelessWidget {
  const _OwnerTabActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _restaurantManageGreen, size: 18),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: _restaurantManageGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerActionPanel extends StatelessWidget {
  const _OwnerActionPanel({required this.children});

  final List<_OwnerQuickAction> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Column(
        children: children
            .map(
              (child) => Padding(
                padding: EdgeInsets.only(
                  bottom: child == children.last ? 0 : 10,
                ),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OwnerQuickAction extends StatelessWidget {
  const _OwnerQuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt3,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _restaurantManageGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.inkMuted5,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodOwnerDashboardScreenState extends State<FoodOwnerDashboardScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _data = {};
  int _tabIndex = 0;

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
      backgroundColor: _restaurantManageBg,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              color: _restaurantManageGreen,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    elevation: 0,
                    scrolledUnderElevation: 1,
                    shadowColor: AppColors.ink.withValues(alpha: 0.08),
                    backgroundColor: _restaurantManageBg,
                    surfaceTintColor: _restaurantManageBg,
                    titleSpacing: 4,
                    leadingWidth: 62,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _OwnerHeaderButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    title: const Text(
                      'রেস্টুরেন্ট ম্যানেজ',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _OwnerHeaderButton(
                          icon: Icons.storefront_rounded,
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ownerHeroPanel(stats, restaurants.length),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _RestaurantManageStickyTabBar(
                      height: 74,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _ownerTabSwitcher(),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverToBoxAdapter(
                      child: _ownerTabContent(
                        stats: stats,
                        restaurants: restaurants,
                        recentOrders: recentOrders,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openRestaurantForm([Map<String, dynamic>? initial]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodOwnerRestaurantFormScreen(initial: initial),
      ),
    );
    _load();
  }

  Widget _ownerHeroPanel(Map<String, dynamic> stats, int restaurantCount) {
    final pendingOrders = '${stats['pending_orders'] ?? 0}';
    return FadeSlideIn(
      index: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _restaurantManageGreen,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.raised,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'রেস্টুরেন্ট অপারেশন',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'মেনু, অর্ডার, প্রোফাইল ও কাস্টমার ফিডব্যাক',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _OwnerTabActionButton(
                  icon: Icons.add_business_outlined,
                  label: 'যোগ',
                  onTap: () => _openRestaurantForm(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ownerHeroStat(
                      'রেস্টুরেন্ট',
                      '${stats['restaurants'] ?? restaurantCount}',
                    ),
                  ),
                  _ownerHeroDivider(),
                  Expanded(child: _ownerHeroStat('পেন্ডিং', pendingOrders)),
                  _ownerHeroDivider(),
                  Expanded(
                    child: _ownerHeroStat(
                      'সেলস',
                      '৳${stats['sales_total'] ?? 0}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownerHeroDivider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: 0.25),
  );

  Widget _ownerHeroStat(String label, String value) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('owner-hero-$label-$value'),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.pop,
      builder: (context, v, child) =>
          Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerTabSwitcher() {
    const tabs = [
      (Icons.dashboard_customize_outlined, 'ওভারভিউ'),
      (Icons.storefront_outlined, 'রেস্টুরেন্ট'),
      (Icons.receipt_long_outlined, 'অর্ডার'),
      (Icons.build_circle_outlined, 'টুলস'),
    ];
    if (_tabIndex >= tabs.length) _tabIndex = 0;
    return Container(
      color: _restaurantManageBg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _tabIndex == index;
          final tab = tabs[index];
          return Expanded(
            child: PressableScale(
              onTap: () => setState(() => _tabIndex = index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.$1,
                    size: 19,
                    color: selected
                        ? _restaurantManageGreen
                        : AppColors.inkMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? _restaurantManageGreen
                          : AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 3,
                    width: selected ? 30 : 0,
                    decoration: BoxDecoration(
                      color: _restaurantManageGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _ownerTabContent({
    required Map<String, dynamic> stats,
    required List<dynamic> restaurants,
    required List<dynamic> recentOrders,
  }) {
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.enter,
      switchOutCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey(_tabIndex),
        child: switch (_tabIndex) {
          0 => _ownerOverviewTab(stats, restaurants, recentOrders),
          1 => _ownerRestaurantsTab(restaurants),
          2 => _ownerOrdersTab(recentOrders),
          _ => _ownerToolsTab(),
        },
      ),
    );
  }

  Widget _ownerOverviewTab(
    Map<String, dynamic> stats,
    List<dynamic> restaurants,
    List<dynamic> recentOrders,
  ) {
    return Column(
      children: [
        FadeSlideIn(
          index: 0,
          child: _OwnerDashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _OwnerDashboardSectionHeader(
                  icon: Icons.monitor_heart_outlined,
                  title: 'আজকের সারাংশ',
                  subtitle: 'রেস্টুরেন্ট, মেনু, অর্ডার ও সেলস',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OwnerDashboardMiniStat(
                      label: 'রেস্টুরেন্ট',
                      value: '${stats['restaurants'] ?? restaurants.length}',
                      icon: Icons.storefront_outlined,
                    ),
                    _OwnerDashboardMiniStat(
                      label: 'মেনু আইটেম',
                      value: '${stats['menu_items'] ?? 0}',
                      icon: Icons.restaurant_menu_outlined,
                    ),
                    _OwnerDashboardMiniStat(
                      label: 'পেন্ডিং অর্ডার',
                      value: '${stats['pending_orders'] ?? 0}',
                      icon: Icons.pending_actions_outlined,
                    ),
                    _OwnerDashboardMiniStat(
                      label: 'সেলস',
                      value: '৳${stats['sales_total'] ?? 0}',
                      icon: Icons.payments_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(index: 1, child: _ownerQuickToolsCard()),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 2,
          child: _ownerRecentOrdersCard(recentOrders.take(3).toList()),
        ),
      ],
    );
  }

  Widget _ownerQuickToolsCard() {
    return _OwnerDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OwnerDashboardSectionHeader(
            icon: Icons.grid_view_rounded,
            title: 'দ্রুত কাজ',
            subtitle: 'মেনু, অর্ডার ও রিভিউতে দ্রুত যান',
          ),
          _OwnerActionPanel(
            children: [
              _OwnerQuickAction(
                icon: Icons.menu_book_outlined,
                label: 'মেনু',
                subtitle: 'আইটেম যোগ/এডিট',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FoodOwnerMenuScreen(),
                  ),
                ),
              ),
              _OwnerQuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'অর্ডার',
                subtitle: 'স্ট্যাটাস আপডেট',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FoodOwnerOrdersScreen(),
                  ),
                ),
              ),
              _OwnerQuickAction(
                icon: Icons.rate_review_outlined,
                label: 'রিভিউ',
                subtitle: 'কাস্টমার ফিডব্যাক',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FoodOwnerReviewsScreen(),
                  ),
                ),
              ),
              _OwnerQuickAction(
                icon: Icons.local_offer_outlined,
                label: 'কুপন',
                subtitle: 'রেস্টুরেন্ট funded discount',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FoodOwnerCouponsScreen(),
                  ),
                ),
              ),
              _OwnerQuickAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'সেটেলমেন্ট',
                subtitle: 'পেআউট, কমিশন ও ডিসকাউন্ট',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FoodOwnerSettlementScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerRestaurantsTab(List<dynamic> restaurants) {
    return _OwnerDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OwnerDashboardSectionHeader(
            icon: Icons.store_mall_directory_outlined,
            title: 'আমার রেস্টুরেন্ট',
            subtitle: 'অ্যাডমিন active করলে food page এ দেখাবে',
            trailing: _OwnerTabActionButton(
              icon: Icons.add_business_outlined,
              label: 'যোগ',
              onTap: () => _openRestaurantForm(),
            ),
          ),
          if (restaurants.isEmpty)
            const _EmptyFoodState(text: 'এখনো রেস্টুরেন্ট নেই'),
          ...restaurants.asMap().entries.map((entry) {
            final r = Map<String, dynamic>.from(entry.value as Map);
            return FadeSlideIn(
              index: entry.key,
              child: _OwnerRestaurantCard(
                data: r,
                onEdit: () => _openRestaurantForm(r),
                onMenu: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FoodOwnerMenuScreen(
                      restaurantId: (r['id'] as num).toInt(),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _ownerOrdersTab(List<dynamic> recentOrders) {
    return _ownerRecentOrdersCard(recentOrders);
  }

  Widget _ownerRecentOrdersCard(List<dynamic> recentOrders) {
    return _OwnerDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OwnerDashboardSectionHeader(
            icon: Icons.history_rounded,
            title: 'সাম্প্রতিক অর্ডার',
            subtitle: recentOrders.isEmpty
                ? 'এখনো কোনো অর্ডার নেই'
                : 'শেষ ${recentOrders.length} টি',
            trailing: recentOrders.isEmpty
                ? null
                : _OwnerTabActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'সব',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoodOwnerOrdersScreen(),
                      ),
                    ),
                  ),
          ),
          if (recentOrders.isEmpty)
            const _EmptyFoodState(text: 'অর্ডার নেই')
          else
            ...recentOrders.asMap().entries.map(
              (entry) => FadeSlideIn(
                index: entry.key,
                child: _OwnerOrderCard(
                  order: Map<String, dynamic>.from(entry.value as Map),
                  onChanged: _load,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ownerToolsTab() {
    return Column(
      children: [
        FadeSlideIn(index: 0, child: _ownerQuickToolsCard()),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 1,
          child: _OwnerDashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _OwnerDashboardSectionHeader(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'প্রোফাইল টিপস',
                  subtitle: 'লোকেশন, ছবি ও পেমেন্ট তথ্য ঠিক রাখুন',
                ),
                const _InfoNote(
                  text:
                      'রেস্টুরেন্ট লোকেশন, ছবি, COD ও manual payment number আপডেট থাকলে অর্ডার নেওয়া সহজ হয়।',
                ),
              ],
            ),
          ),
        ),
      ],
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
      backgroundColor: _restaurantManageBg,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _RestaurantManageHeader(
                    title: 'ফুড রিভিউ',
                    subtitle: 'মালিকের ফিডব্যাক',
                    icon: Icons.rate_review_rounded,
                  ),
                  const SizedBox(height: 18),
                  _OwnerDetailCard(
                    child: Row(
                      children: [
                        const _TinyIconBox(icon: Icons.star_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _reviews.isEmpty
                                ? 'এখনো কোনো রিভিউ আসেনি'
                                : '${_reviews.length} টি কাস্টমার রিভিউ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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

class FoodOwnerCouponsScreen extends StatefulWidget {
  const FoodOwnerCouponsScreen({super.key});

  @override
  State<FoodOwnerCouponsScreen> createState() => _FoodOwnerCouponsScreenState();
}

class _FoodOwnerCouponsScreenState extends State<FoodOwnerCouponsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  List<dynamic> _coupons = [];
  List<dynamic> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final coupons = await _api.get('/food/owner/coupons');
      final restaurants = await _api.get('/food/owner/restaurants');
      var restaurantList = _listFromApi(restaurants);
      if (restaurantList.isEmpty) {
        final dashboard = await _api.get('/food/owner/dashboard');
        restaurantList = _listFromApi(
          dashboard is Map ? dashboard['restaurants'] : null,
        );
      }
      if (!mounted) return;
      setState(() {
        _coupons = _listFromApi(coupons);
        _restaurants = restaurantList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _listFromApi(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
    if (value is Map && value['restaurants'] is List) {
      return value['restaurants'] as List;
    }
    return const [];
  }

  Future<void> _openForm([Map<String, dynamic>? coupon]) async {
    if (_restaurants.isEmpty) {
      await _load();
      if (_restaurants.isNotEmpty) {
        return _openForm(coupon);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'এই account-এর সাথে কোনো restaurant linked পাওয়া যায়নি। Restaurant form থেকে save করুন বা admin panel-এ owner user ঠিক করুন।',
          ),
        ),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OwnerCouponFormSheet(
        api: _api,
        restaurants: _restaurants,
        initial: coupon,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> coupon) async {
    await _api.delete('/food/owner/coupons/${coupon['id']}');
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _restaurantManageBg,
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: _restaurantManageGreen,
      foregroundColor: Colors.white,
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('কুপন'),
    ),
    body: _loading
        ? const Center(child: LogoLoader(showLabel: true))
        : RefreshIndicator(
            onRefresh: _load,
            color: _restaurantManageGreen,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _RestaurantManageHeader(
                  title: 'রেস্টুরেন্ট কুপন',
                  subtitle: 'এই discount restaurant payout থেকে সমন্বয় হবে',
                  icon: Icons.local_offer_rounded,
                ),
                const SizedBox(height: 18),
                _OwnerDetailCard(
                  child: Row(
                    children: [
                      const _TinyIconBox(icon: Icons.local_offer_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _coupons.isEmpty
                              ? 'এখনো কুপন নেই'
                              : '${_coupons.length} টি কুপন',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_coupons.isEmpty)
                  const _EmptyFoodState(text: 'এখনো কোনো কুপন নেই'),
                ..._coupons.map((raw) {
                  final coupon = Map<String, dynamic>.from(raw as Map);
                  return _OwnerCouponCard(
                    coupon: coupon,
                    onEdit: () => _openForm(coupon),
                    onDelete: () => _delete(coupon),
                  );
                }),
                const SizedBox(height: 90),
              ],
            ),
          ),
  );
}

class _OwnerCouponFormSheet extends StatefulWidget {
  const _OwnerCouponFormSheet({
    required this.api,
    required this.restaurants,
    this.initial,
  });

  final ApiClient api;
  final List<dynamic> restaurants;
  final Map<String, dynamic>? initial;

  @override
  State<_OwnerCouponFormSheet> createState() => _OwnerCouponFormSheetState();
}

class _OwnerCouponFormSheetState extends State<_OwnerCouponFormSheet> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _value = TextEditingController();
  final _max = TextEditingController();
  final _minimum = TextEditingController(text: '0');
  final _usage = TextEditingController();
  int? _restaurantId;
  String _type = 'fixed';
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _restaurantId =
        (initial?['restaurant_id'] as num?)?.toInt() ??
        (widget.restaurants.first['id'] as num).toInt();
    _code.text = '${initial?['code'] ?? ''}';
    _title.text = '${initial?['title'] ?? ''}';
    _type = '${initial?['discount_type'] ?? 'fixed'}';
    _value.text = '${initial?['discount_value'] ?? ''}';
    _max.text = '${initial?['max_discount'] ?? ''}';
    _minimum.text = '${initial?['minimum_order'] ?? 0}';
    _usage.text = '${initial?['usage_limit'] ?? ''}';
    _active =
        initial == null ||
        initial['is_active'] == true ||
        initial['is_active'] == 1;
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _value.dispose();
    _max.dispose();
    _minimum.dispose();
    _usage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_restaurantId == null ||
        _code.text.trim().isEmpty ||
        _title.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.post(
        '/food/owner/coupons',
        body: {
          'id': widget.initial?['id'],
          'restaurant_id': _restaurantId,
          'code': _code.text.trim(),
          'title': _title.text.trim(),
          'discount_type': _type,
          'discount_value': _type == 'free_delivery'
              ? 0
              : (num.tryParse(_value.text.trim()) ?? 0),
          'max_discount': _max.text.trim().isEmpty
              ? null
              : num.tryParse(_max.text.trim()),
          'minimum_order': num.tryParse(_minimum.text.trim()) ?? 0,
          'usage_limit': _usage.text.trim().isEmpty
              ? null
              : int.tryParse(_usage.text.trim()),
          'per_user_limit': 1,
          'is_active': _active,
        },
      );
      if (mounted) Navigator.pop(context, true);
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      8,
      16,
      MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initial == null ? 'নতুন কুপন' : 'কুপন এডিট',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _restaurantId,
            decoration: const InputDecoration(labelText: 'রেস্টুরেন্ট'),
            items: widget.restaurants
                .map(
                  (r) => DropdownMenuItem(
                    value: (r['id'] as num).toInt(),
                    child: Text('${r['name']}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _restaurantId = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Coupon Code'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Offer Title'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Discount Type'),
            items: const [
              DropdownMenuItem(value: 'fixed', child: Text('Fixed amount')),
              DropdownMenuItem(value: 'percent', child: Text('Percent')),
              DropdownMenuItem(
                value: 'free_delivery',
                child: Text('Free delivery'),
              ),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'fixed'),
          ),
          if (_type != 'free_delivery') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount Value'),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _max,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Max Discount'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _minimum,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minimum Order'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _usage,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Usage Limit'),
          ),
          SwitchListTile(
            value: _active,
            onChanged: (value) => setState(() => _active = value),
            title: const Text('Active'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'সেভ হচ্ছে...' : 'সেভ করুন'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OwnerCouponCard extends StatelessWidget {
  const _OwnerCouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = coupon['is_active'] == true || coupon['is_active'] == 1;
    final type = '${coupon['discount_type'] ?? 'fixed'}';
    final value = type == 'free_delivery'
        ? 'Free delivery'
        : (type == 'percent'
              ? '${coupon['discount_value'] ?? 0}%'
              : '৳${coupon['discount_value'] ?? 0}');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Row(
        children: [
          _TinyIconBox(icon: Icons.local_offer_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${coupon['code'] ?? ''} - ${coupon['title'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '$value • Min ৳${coupon['minimum_order'] ?? 0} • Used ${coupon['used_count'] ?? 0}/${coupon['usage_limit'] ?? '∞'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _MiniPill(active ? 'Active' : 'Paused'),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class FoodOwnerSettlementScreen extends StatefulWidget {
  const FoodOwnerSettlementScreen({super.key});

  @override
  State<FoodOwnerSettlementScreen> createState() =>
      _FoodOwnerSettlementScreenState();
}

class _FoodOwnerSettlementScreenState extends State<FoodOwnerSettlementScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/food/owner/settlement');
      if (!mounted) return;
      setState(() {
        _summary = Map<String, dynamic>.from((data['summary'] as Map?) ?? {});
        _orders = (data['orders'] as List?) ?? [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _restaurantManageBg,
    body: _loading
        ? const Center(child: LogoLoader(showLabel: true))
        : RefreshIndicator(
            onRefresh: _load,
            color: _restaurantManageGreen,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _RestaurantManageHeader(
                  title: 'সেটেলমেন্ট লেজার',
                  subtitle: 'অর্ডারভিত্তিক আয়, কমিশন, ডিসকাউন্ট ও পেআউট',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 18),
                _OwnerDetailCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OwnerDashboardMiniStat(
                        label: 'অর্ডার',
                        value: '${_summary['orders_count'] ?? 0}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Owner Payable',
                        value: _ownerMoney(_summary['owner_payable_total']),
                        icon: Icons.payments_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Pending',
                        value: _ownerMoney(_summary['pending_payout_total']),
                        icon: Icons.pending_actions_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Paid',
                        value: _ownerMoney(_summary['paid_out_total']),
                        icon: Icons.verified_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Owner Received',
                        value: _ownerMoney(_summary['owner_received_total']),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Admin Receivable',
                        value: _ownerMoney(_summary['admin_receivable_total']),
                        icon: Icons.request_quote_outlined,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Commission',
                        value: _ownerMoney(_summary['commission_total']),
                        icon: Icons.percent_rounded,
                      ),
                      _OwnerDashboardMiniStat(
                        label: 'Discount',
                        value: _ownerMoney(
                          _summary['restaurant_discount_total'],
                        ),
                        icon: Icons.local_offer_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FoodSectionHeader(
                  icon: Icons.history_rounded,
                  title: 'অর্ডারভিত্তিক হিসাব',
                  subtitle: _orders.isEmpty
                      ? 'এখনো delivered order নেই'
                      : '${_orders.length} টি delivered order',
                ),
                const SizedBox(height: 12),
                if (_orders.isEmpty)
                  const _EmptyFoodState(text: 'এখনো কোনো settlement নেই'),
                ..._orders.map((raw) {
                  final order = Map<String, dynamic>.from(raw as Map);
                  return _OwnerSettlementOrderCard(order: order);
                }),
              ],
            ),
          ),
  );
}

class _OwnerSettlementOrderCard extends StatelessWidget {
  const _OwnerSettlementOrderCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = '${order['restaurant_payout_status'] ?? 'pending'}';
    final paid = status == 'paid';
    final method = '${order['payment_method'] ?? ''}';
    final ownerDue = num.tryParse('${order['owner_net_due_amount'] ?? 0}') ?? 0;
    final adminReceivable =
        num.tryParse('${order['admin_receivable_amount'] ?? 0}') ?? 0;
    final cashNote = adminReceivable > 0
        ? 'Owner received বেশি: admin পাবে ${_ownerMoney(adminReceivable)}'
        : (ownerDue > 0
              ? 'Owner পাবে ${_ownerMoney(ownerDue)}'
              : 'Balance clear');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order['order_no'] ?? '#${order['id']}'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _MiniPill(paid ? 'Paid' : 'Pending'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order['restaurant_name'] ?? 'রেস্টুরেন্ট'} • ${order['payment_method'] ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt3,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _restaurantManageBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'হিসাব',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _OwnerSettlementLine(
                  label: 'Gross item sale',
                  value: _ownerMoney(order['items_total']),
                ),
                _OwnerSettlementLine(
                  label: 'Admin commission',
                  value:
                      '-${_ownerMoney(order['restaurant_commission_amount'])}',
                  valueColor: AppColors.danger,
                ),
                _OwnerSettlementLine(
                  label: 'Restaurant discount',
                  value: '-${_ownerMoney(order['restaurant_discount_amount'])}',
                  valueColor: AppColors.danger,
                ),
                const Divider(height: 16, color: AppColors.divider),
                _OwnerSettlementLine(
                  label: 'Owner payable',
                  value: _ownerMoney(order['restaurant_owner_payable']),
                  strong: true,
                  valueColor: _restaurantManageGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _PolicyNote(
            text:
                '${method == 'cash_on_delivery' ? 'COD order' : 'Manual/online payment'} • $cashNote',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SettlementPill(
                label: 'আইটেম',
                value: _ownerMoney(order['items_total']),
              ),
              _SettlementPill(
                label: 'কমিশন',
                value: _ownerMoney(order['restaurant_commission_amount']),
              ),
              _SettlementPill(
                label: 'Discount',
                value: _ownerMoney(order['restaurant_discount_amount']),
              ),
              _SettlementPill(
                label: 'Owner Payable',
                value: _ownerMoney(order['restaurant_owner_payable']),
              ),
              _SettlementPill(
                label: 'Owner Received',
                value: _ownerMoney(order['owner_received_amount']),
              ),
              _SettlementPill(
                label: 'Admin Receivable',
                value: _ownerMoney(order['admin_receivable_amount']),
              ),
            ],
          ),
          if ((order['restaurant_payout_reference'] ?? '')
              .toString()
              .isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ref: ${order['restaurant_payout_reference']}',
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettlementPill extends StatelessWidget {
  const _SettlementPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _restaurantManageBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _OwnerSettlementLine extends StatelessWidget {
  const _OwnerSettlementLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.ink,
            fontSize: 12.5,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
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
    backgroundColor: _restaurantManageBg,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _restaurantManageGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                : '\u09b8\u09c7\u09ad \u0995\u09b0\u09c1\u09a8',
          ),
        ),
      ),
    ),
    body: Theme(
      data: Theme.of(
        context,
      ).copyWith(inputDecorationTheme: _restaurantManageInputDecorationTheme()),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _RestaurantManageHeader(
              title: 'রেস্টুরেন্ট ফর্ম',
              subtitle: 'প্রোফাইল, লোকেশন ও পেমেন্ট',
              icon: Icons.add_business_rounded,
            ),
            const SizedBox(height: 18),
            _OwnerDetailCard(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(
                        _image == null
                            ? '\u09b2\u09cb\u0997\u09cb/\u099b\u09ac\u09bf \u09a6\u09bf\u09a8'
                            : '\u099b\u09ac\u09bf \u09b8\u09bf\u09b2\u09c7\u0995\u09cd\u099f \u09b9\u09df\u09c7\u099b\u09c7',
                      ),
                    ),
                  ),
                  if (_image != null) ...[
                    const SizedBox(height: 12),
                    PickedImageHeroPreview(
                      image: _image,
                      height: 150,
                      onTap: _pick,
                      onRemove: () => setState(() => _image = null),
                    ),
                  ],
                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasLocation
              ? AppColors.tealMuted
              : scheme.error.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on_rounded : Icons.location_off,
                color: hasLocation ? _restaurantManageGreen : scheme.error,
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
                style: FilledButton.styleFrom(
                  backgroundColor: _restaurantManageGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
    backgroundColor: _restaurantManageBg,
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: _restaurantManageGreen,
      foregroundColor: Colors.white,
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
                _RestaurantManageHeader(
                  title: 'মেনু ম্যানেজ',
                  subtitle: widget.restaurantId == null
                      ? 'খাবার যোগ/এডিট'
                      : 'শুধু এই রেস্টুরেন্টের মেনু',
                  icon: Icons.restaurant_menu_rounded,
                ),
                const SizedBox(height: 18),
                _OwnerDetailCard(
                  child: Row(
                    children: [
                      const _TinyIconBox(icon: Icons.menu_book_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _items.isEmpty
                              ? 'মেনু আইটেম নেই'
                              : '${_items.length} টি মেনু আইটেম',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
  final _spiceOptions = TextEditingController();
  final List<_OwnerSizeOptionInput> _sizeOptions = [];
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
    _spiceOptions.text = ((d?['spice_options'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .join(', ');
    for (final option in _parseFoodSizeOptions(
      d?['size_options'],
      d?['discount_price'] ?? d?['price'],
    )) {
      _sizeOptions.add(
        _OwnerSizeOptionInput(
          name: option.name,
          price: option.price.toStringAsFixed(0),
        ),
      );
    }
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
          'size_options': _sizeOptions
              .map(
                (option) => {
                  'name': option.name.text.trim(),
                  'price': num.tryParse(option.price.text.trim()) ?? 0,
                },
              )
              .where((option) => '${option['name']}'.trim().isNotEmpty)
              .toList(),
          'spice_options': _spiceOptions.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
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
    _spiceOptions.dispose();
    for (final option in _sizeOptions) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _restaurantManageBg,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _restaurantManageGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                : '\u09b8\u09c7\u09ad',
          ),
        ),
      ),
    ),
    body: Theme(
      data: Theme.of(
        context,
      ).copyWith(inputDecorationTheme: _restaurantManageInputDecorationTheme()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _RestaurantManageHeader(
            title: 'মেনু আইটেম',
            subtitle: 'দাম, ছবি ও স্ট্যাটাস',
            icon: Icons.ramen_dining_rounded,
          ),
          const SizedBox(height: 18),
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
              labelText:
                  '\u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
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
          const SizedBox(height: 14),
          _OwnerOptionCard(
            title: 'সাইজ অনুযায়ী দাম',
            subtitle: 'প্রয়োজন না হলে খালি রাখুন। যেমন: Small 100, Large 180',
            action: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _sizeOptions.add(_OwnerSizeOptionInput())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('সাইজ যোগ'),
            ),
            children: [
              if (_sizeOptions.isEmpty)
                const _InfoNote(text: 'এই আইটেমে সাইজ অপশন নেই।'),
              ..._sizeOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: option.name,
                          decoration: const InputDecoration(labelText: 'সাইজ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: option.price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'দাম'),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _sizeOptions.removeAt(index).dispose();
                        }),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _spiceOptions,
            decoration: const InputDecoration(
              labelText: 'ঝাল অপশন',
              hintText: 'Normal, Medium, Hot',
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
          if (_image != null) ...[
            const SizedBox(height: 12),
            PickedImageHeroPreview(
              image: _image,
              height: 150,
              onTap: _pick,
              onRemove: () => setState(() => _image = null),
            ),
          ],
        ],
      ),
    ),
  );
}

class _OwnerSizeOptionInput {
  _OwnerSizeOptionInput({String name = '', String price = ''})
    : name = TextEditingController(text: name),
      price = TextEditingController(text: price);

  final TextEditingController name;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _OwnerOptionCard extends StatelessWidget {
  const _OwnerOptionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _restaurantManageBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.inkMuted5,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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
    backgroundColor: _restaurantManageBg,
    body: _loading
        ? const Center(child: LogoLoader(showLabel: true))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _RestaurantManageHeader(
                  title: 'রেস্টুরেন্ট অর্ডার',
                  subtitle: 'স্ট্যাটাস আপডেট',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 18),
                _OwnerDetailCard(
                  child: Row(
                    children: [
                      const _TinyIconBox(icon: Icons.assignment_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _orders.isEmpty
                              ? 'অর্ডার নেই'
                              : '${_orders.length} টি অর্ডার',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
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
                        fontSize: 15,
                        color: AppColors.ink2,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FoodOwnerOrderDetailsScreen(
                order: order,
                onChanged: onChanged,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: _restaurantManageGreen,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order['order_no'] ?? '#${order['id']}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink2,
                              ),
                            ),
                          ),
                          _FoodStatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${order['receiver_name'] ?? ''}  •  ৳${order['grand_total'] ?? 0}',
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
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted6,
                ),
              ],
            ),
          ),
        ),
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

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    await launchUrl(Uri.parse('tel:${phone.trim()}'));
  }

  List<MapEntry<String, String>> _actionsFor(String status) =>
      _OwnerOrderCard(order: order, onChanged: onChanged)._actionsFor(status);

  @override
  Widget build(BuildContext context) {
    final status = '${order['status'] ?? 'pending'}';
    const progressStatuses = [
      'pending',
      'accepted',
      'preparing',
      'picked_up',
      'on_the_way',
      'delivered',
    ];
    final progressIndex = progressStatuses.indexOf(status);
    final items = (order['items'] as List?) ?? [];
    final actions = _actionsFor(status);
    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final rider = order['rider'] is Map
        ? Map<String, dynamic>.from(order['rider'] as Map)
        : <String, dynamic>{};
    final distance =
        order['delivery_distance_km'] ?? order['route_distance_km'];
    final restaurantPhone =
        restaurant['phone']?.toString() ??
        restaurant['owner_phone']?.toString();
    final hasMap =
        order['delivery_lat'] != null && order['delivery_lng'] != null;
    final proofUrl = (order['payment_proof_photo_url'] ?? '').toString();

    return Scaffold(
      backgroundColor: _restaurantManageBg,
      body: RefreshIndicator(
        onRefresh: onChanged,
        color: _restaurantManageGreen,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RestaurantManageHeader(
              title: 'অর্ডার ডিটেইলস',
              subtitle: '${order['order_no'] ?? '#${order['id']}'}',
              icon: Icons.fact_check_rounded,
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              index: 0,
              child: _OwnerDetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: _restaurantManageGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${order['order_no'] ?? '#${order['id']}'}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _foodStatusLabels[status] ?? status,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OwnerStatusPill(status: status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerMiniMetric(
                            label: 'মোট বিল',
                            value: _ownerMoney(order['grand_total']),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OwnerMiniMetric(
                            label: 'ডেলিভারি',
                            value: _ownerMoney(order['delivery_fee']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 1,
              child: _OwnerDetailCard(
                title: 'অর্ডার প্রগ্রেস',
                subtitle: _foodStatusLabels[status] ?? status,
                child: _FoodStatusTimeline(
                  statuses: progressStatuses,
                  labels: _foodStatusLabels,
                  currentIndex: progressIndex < 0 ? 0 : progressIndex,
                  timeline: (order['status_timeline'] as List?) ?? [],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 2,
              child: _OwnerDetailCard(
                title: 'রুট ও লোকেশন',
                subtitle: distance == null
                    ? 'রেস্টুরেন্ট থেকে কাস্টমারের লোকেশন'
                    : 'রেস্টুরেন্ট থেকে কাস্টমার: $distance KM',
                child: Column(
                  children: [
                    _OwnerInfoTile(
                      icon: Icons.restaurant_rounded,
                      title: restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
                      subtitle: restaurant['address']?.toString() ?? '',
                    ),
                    const Divider(height: 18),
                    _OwnerInfoTile(
                      icon: Icons.location_on_rounded,
                      title: order['receiver_name']?.toString() ?? 'কাস্টমার',
                      subtitle: order['delivery_address']?.toString() ?? '',
                    ),
                    if (hasMap) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeliveryMap(context),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('পিকআপ ও ডেলিভারি ম্যাপে দেখুন'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 3,
              child: _OwnerDetailCard(
                title: 'রেস্টুরেন্ট',
                child: Column(
                  children: [
                    _OwnerDetailRow('নাম', restaurant['name']),
                    _OwnerDetailRow('মোবাইল', restaurantPhone),
                    _OwnerDetailRow('ঠিকানা', restaurant['address']),
                    if (restaurantPhone != null && restaurantPhone.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _call(restaurantPhone),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('রেস্টুরেন্টে কল করুন'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 4,
              child: _OwnerDetailCard(
                title: 'কাস্টমার',
                child: Column(
                  children: [
                    _OwnerDetailRow('নাম', order['receiver_name']),
                    _OwnerDetailRow('মোবাইল', order['receiver_phone']),
                    _OwnerDetailRow(
                      'ডেলিভারি ঠিকানা',
                      order['delivery_address'],
                    ),
                    _OwnerDetailRow('এরিয়া', order['delivery_area']),
                    if (order['receiver_phone']?.toString().isNotEmpty == true)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              _call(order['receiver_phone']?.toString()),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('কাস্টমারকে কল করুন'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 5,
              child: _OwnerDetailCard(
                title: 'খাবারের তালিকা',
                subtitle: '${items.length} টি আইটেম',
                child: Column(
                  children: items.isEmpty
                      ? [const Text('আইটেম পাওয়া যায়নি')]
                      : items
                            .map(
                              (raw) => _OwnerItemLine(
                                item: Map<String, dynamic>.from(raw as Map),
                              ),
                            )
                            .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 6,
              child: _OwnerDetailCard(
                title: 'বিল ও পেমেন্ট',
                child: Column(
                  children: [
                    _OwnerDetailRow(
                      'আইটেম মোট',
                      _ownerMoney(order['items_total']),
                    ),
                    _OwnerDetailRow(
                      'ডেলিভারি ফি',
                      _ownerMoney(order['delivery_fee']),
                    ),
                    _OwnerDetailRow(
                      'ডিসকাউন্ট',
                      _ownerMoney(order['discount_amount'] ?? 0),
                    ),
                    const Divider(height: 18),
                    _OwnerDetailRow(
                      'গ্র্যান্ড টোটাল',
                      _ownerMoney(order['grand_total']),
                      strong: true,
                    ),
                    _OwnerDetailRow(
                      'পেমেন্ট মেথড',
                      order['payment_method'] ?? 'cash_on_delivery',
                    ),
                    _OwnerDetailRow(
                      'পেমেন্ট স্ট্যাটাস',
                      order['payment_status'] ?? 'pending',
                    ),
                    _OwnerDetailRow(
                      'ট্রানজেকশন আইডি',
                      order['manual_transaction_id'],
                    ),
                    if (proofUrl.isNotEmpty)
                      _PaymentProofPreview(url: proofUrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 7,
              child: _OwnerDetailCard(
                title: 'ডেলিভারি ও রাইডার',
                child: Column(
                  children: [
                    _OwnerDetailRow('রাইডার', rider['name']),
                    _OwnerDetailRow('রাইডার মোবাইল', rider['phone']),
                    _OwnerDetailRow('নোট', order['order_note']),
                    if (rider['phone']?.toString().isNotEmpty == true)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _call(rider['phone']?.toString()),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('রাইডারকে কল করুন'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 8,
                child: _OwnerDetailCard(
                  title: 'অর্ডার অ্যাকশন',
                  subtitle: 'পরবর্তী স্ট্যাটাস এখান থেকে আপডেট করুন',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions
                        .map(
                          (action) => action.key == 'rejected'
                              ? OutlinedButton(
                                  onPressed: () =>
                                      _setStatus(context, action.key),
                                  child: Text(action.value),
                                )
                              : FilledButton.tonal(
                                  onPressed: () =>
                                      _setStatus(context, action.key),
                                  child: Text(action.value),
                                ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _ownerMoney(dynamic value) => '৳${value ?? 0}';

class _OwnerStatusPill extends StatelessWidget {
  const _OwnerStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = _foodStatusLabels[status] ?? status;
    return TweenAnimationBuilder<double>(
      key: ValueKey(label),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.pop,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 128),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _restaurantManageGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _restaurantManageGreen),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerMiniMetric extends StatelessWidget {
  const _OwnerMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerInfoTile extends StatelessWidget {
  const _OwnerInfoTile({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _restaurantManageGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerItemLine extends StatelessWidget {
  const _OwnerItemLine({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qty = item['quantity'] ?? 1;
    final unit = item['unit_price'] ?? item['price'] ?? 0;
    final total = item['total_price'] ?? item['line_total'] ?? unit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'আইটেম',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$qty x ৳$unit',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text('৳$total', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _OwnerDetailRow extends StatelessWidget {
  const _OwnerDetailRow(this.label, this.value, {this.strong = false});

  final String label;
  final dynamic value;
  final bool strong;

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
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
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

  int _countOrders(String status) => _orders.where((raw) {
    if (raw is! Map) return false;
    return '${raw['status'] ?? ''}' == status;
  }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _restaurantManageBg,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              color: _restaurantManageGreen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _RestaurantManageHeader(
                    title: 'আমার অর্ডার',
                    subtitle: 'খাবারের অর্ডার স্ট্যাটাস ও ট্র্যাকিং',
                    icon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    child: _OwnerDetailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _OwnerDashboardSectionHeader(
                            icon: Icons.delivery_dining_rounded,
                            title: 'ফুড ডেলিভারি ট্র্যাকিং',
                            subtitle: 'লাইভ স্ট্যাটাস, পেমেন্ট ও রাইডার আপডেট',
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OwnerDashboardMiniStat(
                                label: 'মোট অর্ডার',
                                value: '${_orders.length}',
                                icon: Icons.receipt_long_outlined,
                              ),
                              _OwnerDashboardMiniStat(
                                label: 'চলমান',
                                value:
                                    '${_orders.length - _countOrders('delivered') - _countOrders('cancelled') - _countOrders('rejected')}',
                                icon: Icons.route_outlined,
                              ),
                              _OwnerDashboardMiniStat(
                                label: 'ডেলিভার্ড',
                                value: '${_countOrders('delivered')}',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OwnerDetailCard(
                    title: 'অর্ডার লিস্ট',
                    subtitle: _orders.isEmpty
                        ? 'এখনো কোনো অর্ডার নেই'
                        : '${_orders.length} টি অর্ডার',
                    child: Column(
                      children: [
                        if (_orders.isEmpty)
                          const _EmptyFoodState(text: 'এখনো কোনো অর্ডার নেই'),
                        ..._orders.asMap().entries.map((entry) {
                          final order = Map<String, dynamic>.from(
                            entry.value as Map,
                          );
                          return FadeSlideIn(
                            index: entry.key,
                            child: _OrderListCard(
                              order: order,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FoodOrderDetailsScreen(
                                    orderId: (order['id'] as num).toInt(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
  final _paymentTransactionId = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  Map<String, dynamic> _order = {};
  bool _loading = true;
  bool _paymentSubmitting = false;
  XFile? _paymentProofPhoto;
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
    _paymentTransactionId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _api.get('/food/orders/${widget.orderId}');
    if (!mounted) return;
    setState(() {
      _order = Map<String, dynamic>.from(res as Map);
      if (_paymentTransactionId.text.trim().isEmpty) {
        _paymentTransactionId.text = '${_order['manual_transaction_id'] ?? ''}'
            .trim();
      }
      _loading = false;
    });
  }

  Map<String, dynamic>? _manualPaymentOption() {
    final method = '${_order['payment_method'] ?? ''}';
    if (method != 'manual_bkash' && method != 'manual_nagad') return null;
    final restaurant = _order['restaurant'] is Map
        ? Map<String, dynamic>.from(_order['restaurant'] as Map)
        : <String, dynamic>{};
    final options = (restaurant['payment_options'] as List?) ?? const [];
    for (final raw in options) {
      if (raw is Map && '${raw['method']}' == method) {
        return Map<String, dynamic>.from(raw);
      }
    }
    return null;
  }

  bool get _shouldShowPayNow {
    final method = '${_order['payment_method'] ?? ''}';
    final orderStatus = '${_order['status'] ?? ''}';
    final paymentStatus = '${_order['payment_status'] ?? 'unpaid'}';
    if (['delivered', 'cancelled', 'rejected'].contains(orderStatus)) {
      return false;
    }
    return (method == 'manual_bkash' || method == 'manual_nagad') &&
        paymentStatus != 'paid';
  }

  Future<void> _pickOrderPaymentProof() async {
    final image = await _paymentProofPicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    setState(() => _paymentProofPhoto = image);
  }

  Future<void> _submitOrderPaymentProof() async {
    if (_paymentTransactionId.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction ID দিন')));
      return;
    }
    setState(() => _paymentSubmitting = true);
    try {
      final fields = {
        'manual_transaction_id': _paymentTransactionId.text.trim(),
      };
      final res = _paymentProofPhoto == null
          ? await _api.post(
              '/food/orders/${widget.orderId}/payment-proof',
              body: fields,
            )
          : await _api.postMultipart(
              '/food/orders/${widget.orderId}/payment-proof',
              fields: fields,
              files: {'payment_proof_photo': _paymentProofPhoto!.path},
            );
      if (!mounted) return;
      final order = res['order'] is Map
          ? Map<String, dynamic>.from(res['order'] as Map)
          : null;
      setState(() {
        if (order != null) _order = {..._order, ...order};
        _paymentProofPhoto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পেমেন্ট তথ্য যাচাইয়ের জন্য পাঠানো হয়েছে'),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _paymentSubmitting = false);
    }
  }

  Future<void> _openOrderMap() async {
    final deliveryLat = readDouble(_order['delivery_lat']);
    final deliveryLng = readDouble(_order['delivery_lng']);
    if (deliveryLat == null || deliveryLng == null) return;

    final restaurant = _order['restaurant'] is Map
        ? Map<String, dynamic>.from(_order['restaurant'] as Map)
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: deliveryLat,
          initialLng: deliveryLng,
          title: 'ডেলিভারি ম্যাপ',
          readOnly: true,
          markers: markers,
        ),
      ),
    );
  }

  Future<void> _openRiderLiveMap() async {
    final rider = _order['rider'] is Map
        ? Map<String, dynamic>.from(_order['rider'] as Map)
        : <String, dynamic>{};
    final riderLat = readDouble(rider['last_lat']);
    final riderLng = readDouble(rider['last_lng']);
    if (riderLat == null || riderLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('রাইডারের লাইভ লোকেশন এখনো পাওয়া যায়নি')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: riderLat,
          initialLng: riderLng,
          title: 'রাইডারের লাইভ লোকেশন',
          readOnly: true,
          markers: [
            AppMapMarker(
              lat: riderLat,
              lng: riderLng,
              label: rider['name']?.toString() ?? 'রাইডার',
              icon: Icons.delivery_dining,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderSupportSheet() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var saving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              void updateSheet(VoidCallback callback) {
                if (sheetContext.mounted) {
                  setSheetState(callback);
                }
              }

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
                                updateSheet(() => saving = true);
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
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
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
                                    ).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                } finally {
                                  updateSheet(() => saving = false);
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        subject.dispose();
        message.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'pending',
      'accepted',
      'preparing',
      'picked_up',
      'on_the_way',
      'delivered',
    ];
    final labels = _foodStatusLabels;
    final status = '${_order['status'] ?? 'pending'}';
    final current = statuses.indexOf(status);
    final items = (_order['items'] as List?) ?? [];
    final existingReview = _order['review'] is Map
        ? Map<String, dynamic>.from(_order['review'] as Map)
        : null;
    final delivered = '${_order['status']}' == 'delivered';
    final hasMap =
        (_order['delivery_map_url']?.toString().isNotEmpty == true) ||
        (_order['delivery_lat'] != null && _order['delivery_lng'] != null);
    final rider = _order['rider'] is Map
        ? Map<String, dynamic>.from(_order['rider'] as Map)
        : <String, dynamic>{};
    final hasRider = rider.isNotEmpty && rider['id'] != null;
    final restaurant = _order['restaurant'] is Map
        ? Map<String, dynamic>.from(_order['restaurant'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: _restaurantManageBg,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              color: _restaurantManageGreen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RestaurantManageHeader(
                    title: 'অর্ডার ট্র্যাকিং',
                    subtitle: '${_order['order_no'] ?? '#${_order['id']}'}',
                    icon: Icons.route_rounded,
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    index: 0,
                    child: _OwnerDetailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.tealSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: _restaurantManageGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_order['order_no'] ?? '#${_order['id']}'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant['name']?.toString() ??
                                          'রেস্টুরেন্ট',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _OwnerStatusPill(status: status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _OwnerMiniMetric(
                                  label: 'মোট বিল',
                                  value: _ownerMoney(_order['grand_total']),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _OwnerMiniMetric(
                                  label: 'ডেলিভারি',
                                  value: _ownerMoney(_order['delivery_fee']),
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
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 1,
                    child: _OwnerDetailCard(
                      title: 'অর্ডার প্রগ্রেস',
                      subtitle: labels[status] ?? status,
                      child: _FoodStatusTimeline(
                        statuses: statuses,
                        labels: labels,
                        currentIndex: current < 0 ? 0 : current,
                        timeline: (_order['status_timeline'] as List?) ?? [],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 2,
                    child: _OwnerDetailCard(
                      title: 'অর্ডারের খাবার',
                      subtitle: '${items.length} টি item',
                      child: Column(
                        children: items.isEmpty
                            ? [const Text('আইটেম পাওয়া যায়নি')]
                            : items
                                  .map(
                                    (raw) => _OwnerItemLine(
                                      item: Map<String, dynamic>.from(
                                        raw as Map,
                                      ),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 3,
                    child: _OwnerDetailCard(
                      title: 'বিল সারাংশ',
                      child: _PriceBox(cart: _order),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_shouldShowPayNow) ...[
                    FadeSlideIn(
                      index: 4,
                      child: _OrderPayNowCard(
                        order: _order,
                        paymentOption: _manualPaymentOption(),
                        transactionId: _paymentTransactionId,
                        proof: _paymentProofPhoto,
                        submitting: _paymentSubmitting,
                        onPick: _pickOrderPaymentProof,
                        onRemove: () =>
                            setState(() => _paymentProofPhoto = null),
                        onSubmit: _submitOrderPaymentProof,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FadeSlideIn(
                    index: 5,
                    child: _OrderPaymentInfoCard(order: _order),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 6,
                    child: _OrderDeliveryInfoCard(
                      order: _order,
                      onOpenMap: _openOrderMap,
                    ),
                  ),
                  if (hasRider) ...[
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: 7,
                      child: _OrderRiderLiveCard(
                        rider: rider,
                        onOpenMap: _openRiderLiveMap,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 8,
                    child: _OrderHelpCard(
                      order: _order,
                      onReportIssue: _showOrderSupportSheet,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 9,
                    child: _FoodReviewsPanel(
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
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

const Map<String, String> _foodStatusLabels = {
  'pending': 'রেস্টুরেন্ট গ্রহণের অপেক্ষায়',
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

class _OrderPayNowCard extends StatelessWidget {
  const _OrderPayNowCard({
    required this.order,
    required this.paymentOption,
    required this.transactionId,
    required this.proof,
    required this.submitting,
    required this.onPick,
    required this.onRemove,
    required this.onSubmit,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic>? paymentOption;
  final TextEditingController transactionId;
  final XFile? proof;
  final bool submitting;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final method = '${order['payment_method'] ?? ''}';
    final title = method == 'manual_nagad'
        ? 'Nagad পেমেন্ট সম্পন্ন করুন'
        : 'bKash পেমেন্ট সম্পন্ন করুন';
    final number = '${paymentOption?['number'] ?? ''}'.trim();
    final instructions = '${paymentOption?['instructions'] ?? ''}'.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TinyIconBox(icon: Icons.account_balance_wallet_outlined),
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
            const SizedBox(height: 10),
            _PolicyNote(
              text:
                  'এই অর্ডারটি এখনো unpaid আছে। নিচের নম্বরে ৳${order['grand_total'] ?? 0} পাঠিয়ে Transaction ID দিন। স্ক্রিনশট দিলে যাচাই আরও সহজ হবে।',
            ),
            if (number.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_android_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => launchUrl(Uri.parse('tel:$number')),
                      icon: const Icon(Icons.call_rounded),
                      tooltip: 'Call',
                    ),
                  ],
                ),
              ),
            ],
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(instructions, style: const TextStyle(height: 1.45)),
            ],
            const SizedBox(height: 12),
            _ManualPaymentProofCard(
              transactionId: transactionId,
              proof: proof,
              onPick: onPick,
              onRemove: onRemove,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  submitting ? 'পাঠানো হচ্ছে...' : 'পেমেন্ট তথ্য জমা দিন',
                ),
              ),
            ),
          ],
        ),
      ),
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
            if (proof != null) ...[
              const SizedBox(height: 10),
              PickedImageHeroPreview(
                image: proof,
                height: 150,
                onTap: onPick,
                onRemove: onRemove,
              ),
            ],
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
    final distance =
        order['delivery_distance_km'] ?? order['route_distance_km'];

    return _SoftInfoCard(
      icon: Icons.location_on_outlined,
      title: 'ডেলিভারি লোকেশন',
      children: [
        _OrderInfoRow(
          'রেস্টুরেন্ট থেকে দূরত্ব',
          distance == null ? 'হিসাব করা হয়নি' : '$distance KM',
        ),
        _OrderInfoRow('ডেলিভারি চার্জ', '৳${order['delivery_fee'] ?? 0}'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('ডেলিভারি ম্যাপ দেখুন'),
        ),
      ],
    );
  }
}

class _OrderRiderLiveCard extends StatelessWidget {
  const _OrderRiderLiveCard({required this.rider, required this.onOpenMap});
  final Map<String, dynamic> rider;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final riderLat = readDouble(rider['last_lat']);
    final riderLng = readDouble(rider['last_lng']);
    final hasLocation = riderLat != null && riderLng != null;
    final lastUpdated = _friendlyTime(rider['last_location_at']);

    return _SoftInfoCard(
      icon: Icons.delivery_dining_rounded,
      title: 'রাইডার',
      children: [
        _OrderInfoRow('নাম', '${rider['name'] ?? 'নাম নেই'}'),
        _OrderInfoRow('ফোন', '${rider['phone'] ?? 'নেই'}'),
        _OrderInfoRow(
          'লাইভ লোকেশন',
          hasLocation
              ? (lastUpdated == null
                    ? 'লোকেশন পাওয়া গেছে'
                    : 'শেষ আপডেট $lastUpdated')
              : 'লোকেশন আপডেট অপেক্ষমাণ',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenMap,
          icon: const Icon(Icons.my_location_rounded, size: 18),
          label: const Text('শুধু রাইডার লোকেশন দেখুন'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _restaurantManageGreen),
            Expanded(
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 22, color: scheme.outlineVariant),
                    ...children,
                  ],
                ),
              ),
            ),
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

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({required this.order, required this.onTap});
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final status = '${order['status'] ?? 'pending'}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _restaurantManageBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: _restaurantManageGreen,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order['order_no'] ?? '#${order['id']}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink2,
                              ),
                            ),
                          ),
                          _FoodStatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${restaurant['name'] ?? 'রেস্টুরেন্ট'}  •  ${_ownerMoney(order['grand_total'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted6,
                ),
              ],
            ),
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

class _FoodStatusTimeline extends StatelessWidget {
  const _FoodStatusTimeline({
    required this.statuses,
    required this.labels,
    required this.currentIndex,
    this.timeline = const [],
  });
  final List<String> statuses;
  final Map<String, String> labels;
  final int currentIndex;
  final List<dynamic> timeline;

  Map<String, dynamic>? _timelineFor(String status) {
    for (final raw in timeline) {
      if (raw is Map && '${raw['status']}' == status) {
        return Map<String, dynamic>.from(raw);
      }
    }
    return null;
  }

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
            Builder(
              builder: (context) {
                final item = _timelineFor(statuses[i]);
                final completed =
                    item?['completed'] == true || i <= currentIndex;
                final current = item?['current'] == true || i == currentIndex;
                final timestamp = item?['timestamp']?.toString();
                final timeText = _orderTimelineTime(timestamp);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: completed
                                ? (current
                                      ? _restaurantManageGreen
                                      : scheme.primary)
                                : scheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            boxShadow: current
                                ? [
                                    BoxShadow(
                                      color: _restaurantManageGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            completed
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 14,
                            color: completed
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        if (i != statuses.length - 1)
                          Container(
                            width: 2,
                            height: 42,
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
                          bottom: i == statuses.length - 1 ? 0 : 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item?['label']?.toString() ??
                                        labels[statuses[i]] ??
                                        statuses[i],
                                    style: TextStyle(
                                      fontWeight: completed
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: completed
                                          ? scheme.onSurface
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (current)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tealSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: _restaurantManageGreen,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  completed
                                      ? Icons.schedule_rounded
                                      : Icons.hourglass_empty_rounded,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    timeText ??
                                        (completed
                                            ? 'সময় পাওয়া যায়নি'
                                            : 'অপেক্ষায়'),
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11.5,
                                      fontWeight: completed
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

String? _orderTimelineTime(String? value) {
  if (value == null || value.trim().isEmpty || value == 'null') return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day}/${local.month}/${local.year} • $hour:$minute $amPm';
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.onCart, required this.cartCount});
  final VoidCallback onCart;
  final int cartCount;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with TickerProviderStateMixin {
  // A slow, restrained breathing pulse on the decorative circle — the one
  // deliberate ambient motion on the whole screen, not scattered everywhere.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final AnimationController _cartBump = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );

  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.cartCount;
  }

  @override
  void didUpdateWidget(covariant _HeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cartCount != _lastCount) {
      _lastCount = widget.cartCount;
      _cartBump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _cartBump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        // Flat, deliberate brand colour — no gradient wash.
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
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
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale = 1 + (_pulse.value * 0.06);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      child: Container(
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
                    ),
                    const SizedBox(height: 7),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        "\u09ad\u09cb\u09b2\u09be\u09b0 \u0996\u09be\u09ac\u09be\u09b0 \u098f\u0996\u09a8 \u0986\u09b0\u0993 \u09b8\u09b9\u099c",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    FadeSlideIn(
                      index: 2,
                      child: Text(
                        "\u09aa\u099b\u09a8\u09cd\u09a6\u09c7\u09b0 \u0996\u09be\u09ac\u09be\u09b0 \u09ac\u09be\u099b\u09be\u0987 \u0995\u09b0\u09c1\u09a8, \u09a6\u09cd\u09b0\u09c1\u09a4 \u0995\u09be\u09b0\u09cd\u099f\u09c7 \u09a8\u09bf\u09a8\u0964",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PressableScale(
                onTap: widget.onCart,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _cartBump,
                  builder: (context, child) {
                    final t = _cartBump.value;
                    final bump = t < 0.5 ? t * 0.4 : (1 - t) * 0.4;
                    return Transform.scale(scale: 1 + bump, child: child);
                  },
                  child: Container(
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
                      onPressed: widget.onCart,
                      color: AppColors.primary,
                      icon: _CartBadgeIcon(count: widget.cartCount, size: 21),
                    ),
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
          child: FadeSlideIn(
            index: 0,
            child: _FoodQuickAction(
              icon: Icons.receipt_long_rounded,
              label: 'অর্ডার',
              onTap: onOrders,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FadeSlideIn(
            index: 1,
            child: _FoodQuickAction(
              icon: Icons.storefront_rounded,
              label: 'রেস্টুরেন্ট',
              onTap: onOwner,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FadeSlideIn(
            index: 2,
            child: _FoodQuickAction(
              icon: Icons.delivery_dining_rounded,
              label: 'রাইডার',
              onTap: onRider,
            ),
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
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.peach.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.inkSoftBrown.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _FoodAppBarTitle extends StatelessWidget {
  const _FoodAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ফুড ডেলিভারি',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            height: 1.05,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'ভোলায় সহজে খাবার অর্ডার করুন',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.inkMuted2,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final IconData? icon;
  final Widget? child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceAlt2,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: child ?? Icon(icon, color: AppColors.ink, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodAppBarMenuItem extends StatelessWidget {
  const _FoodAppBarMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
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
            child: TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.base,
              curve: AppMotion.pop,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
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
              return FadeSlideIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: scheme.surface,
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: AppColors.peach.withValues(alpha: 0.85),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onTap(banner['link_url']?.toString()),
                      splashColor: AppColors.primary.withValues(alpha: 0.06),
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: AppColors.primary,
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
                                            color: AppColors.ink,
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
                                    color: AppColors.primary,
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
                    ? AppColors.primary
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
    final visibleReviews = widget.reviews
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final orderedItems = widget.orderItems
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border2),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDeep.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewPanelHeader(
            count: visibleReviews.length,
            canSubmit: widget.canSubmit,
          ),
          const SizedBox(height: 16),
          if (!widget.canSubmit)
            _ReviewLockedNote(
              text:
                  widget.lockedMessage ??
                  '\u09b0\u09bf\u09ad\u09bf\u0989 \u09a6\u09bf\u09a4\u09c7 \u0986\u0997\u09c7 \u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09c7 \u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09b8\u09ae\u09cd\u09aa\u09a8\u09cd\u09a8 \u09b9\u09a4\u09c7 \u09b9\u09ac\u09c7\u0964',
            )
          else ...[
            if (orderedItems.isNotEmpty) ...[
              _ReviewTargetSelector(
                value: _selectedFoodItemId,
                orderedItems: orderedItems,
                onChanged: (value) =>
                    setState(() => _selectedFoodItemId = value),
              ),
              const SizedBox(height: 14),
            ],
            _ReviewRatingCard(
              rating: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            _ReviewCommentField(controller: _comment),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _saving
                      ? '\u09b8\u09c7\u09ad \u09b9\u099a\u09cd\u099b\u09c7...'
                      : '\u09b0\u09bf\u09ad\u09bf\u0989 \u099c\u09ae\u09be \u09a6\u09bf\u09a8',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (visibleReviews.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              '\u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u09b0\u09bf\u09ad\u09bf\u0989',
              style: TextStyle(
                color: AppColors.ink3,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...visibleReviews.asMap().entries.map(
              (entry) => FadeSlideIn(
                index: entry.key,
                child: _FoodReviewCard(review: entry.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewPanelHeader extends StatelessWidget {
  const _ReviewPanelHeader({required this.count, required this.canSubmit});

  final int count;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.amberSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.rate_review_outlined,
            color: AppColors.amber,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canSubmit ? 'মতামত ও রিভিউ' : 'রিভিউ ও রেটিং',
                style: const TextStyle(
                  color: AppColors.ink3,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == 0 ? 'এখনো কোনো রিভিউ নেই' : '$count টি রিভিউ',
                style: const TextStyle(
                  color: AppColors.inkMuted2,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewLockedNote extends StatelessWidget {
  const _ReviewLockedNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt5,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.inkMuted2,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.inkMuted2,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTargetSelector extends StatelessWidget {
  const _ReviewTargetSelector({
    required this.value,
    required this.orderedItems,
    required this.onChanged,
  });

  final int? value;
  final List<Map<String, dynamic>> orderedItems;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'রিভিউ কার জন্য',
        filled: true,
        fillColor: AppColors.surfaceAlt2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.3),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('রেস্টুরেন্ট')),
        ...orderedItems.map(
          (item) => DropdownMenuItem<int?>(
            value: (item['food_item_id'] as num?)?.toInt(),
            child: Text(
              '${item['name'] ?? 'খাবার'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ReviewRatingCard extends StatelessWidget {
  const _ReviewRatingCard({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'আপনার রেটিং',
              style: TextStyle(
                color: AppColors.ink3,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...List.generate(5, (index) {
            final value = index + 1;
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onChanged(value),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('star-$value-${value <= rating}'),
                  tween: Tween(begin: value <= rating ? 0.6 : 1, end: 1),
                  duration: AppMotion.fast,
                  curve: AppMotion.pop,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Icon(
                    value <= rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.amber,
                    size: 29,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewCommentField extends StatelessWidget {
  const _ReviewCommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'আপনার বিস্তারিত মতামত লিখুন',
          style: TextStyle(
            color: AppColors.ink3,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'খাবার, সার্ভিস বা অভিজ্ঞতা সম্পর্কে লিখুন...',
            hintStyle: const TextStyle(color: AppColors.inkMuted4),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.3),
            ),
          ),
        ),
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
    final user = Map<String, dynamic>.from((review['user'] as Map?) ?? {});
    final item = Map<String, dynamic>.from((review['food_item'] as Map?) ?? {});
    final reply = '${review['owner_reply'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.tealSoft2,
                child: Text(
                  _initials('${user['name'] ?? 'U'}'),
                  style: const TextStyle(
                    color: AppColors.teal,
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
                      style: const TextStyle(
                        color: AppColors.ink3,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.isNotEmpty)
                      Text(
                        '${item['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted2,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _ReviewScorePill(rating: review['rating'] ?? 0),
            ],
          ),
          if ('${review['comment'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${review['comment']}',
              style: const TextStyle(
                color: AppColors.inkMuted3,
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
          if (review['is_verified_order'] == true) ...[
            const SizedBox(height: 10),
            const _ReviewMetaPill(text: 'ভেরিফাইড অর্ডার'),
          ],
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\u09b0\u09c7\u09b8\u09cd\u099f\u09c1\u09b0\u09c7\u09a8\u09cd\u099f\u09c7\u09b0 \u0989\u09a4\u09cd\u09a4\u09b0',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: const TextStyle(
                      color: AppColors.inkMuted3,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
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

class _ReviewScorePill extends StatelessWidget {
  const _ReviewScorePill({required this.rating});

  final dynamic rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
          const SizedBox(width: 3),
          Text(
            '$rating',
            style: const TextStyle(
              color: AppColors.ink3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewMetaPill extends StatelessWidget {
  const _ReviewMetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tealSoft2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RestaurantShowcaseCard extends StatelessWidget {
  const _RestaurantShowcaseCard({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPromoted = _isTruthy(
      data['is_currently_promoted'] ?? data['is_promoted'],
    );
    final promotionLabel = data['promotion_label']?.toString().trim();

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.inkSoftBrown.withValues(alpha: 0.045),
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
                    Hero(
                      tag: 'restaurant-image-${data['id'] ?? data.hashCode}',
                      flightShuttleBuilder:
                          (
                            context,
                            animation,
                            direction,
                            fromContext,
                            toContext,
                          ) => FadeTransition(
                            opacity: animation,
                            child: toContext.widget,
                          ),
                      child: _FoodImage(
                        url: data['image_url']?.toString(),
                        height: 64,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.slow,
                        curve: AppMotion.pop,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
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
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isPromoted)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: AppMotion.slow,
                          curve: AppMotion.pop,
                          builder: (context, value, child) => Transform.scale(
                            scale: value,
                            alignment: Alignment.centerLeft,
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  promotionLabel == null ||
                                          promotionLabel.isEmpty
                                      ? 'Featured'
                                      : promotionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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
                          color: AppColors.ink,
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
                            color: AppColors.primary,
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
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return AnimatedSwitcher(duration: AppMotion.base, child: child);
        }
        return AppShimmer(width: width, height: height, child: placeholder);
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
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

class _FoodSizeOption {
  const _FoodSizeOption({required this.name, required this.price});
  final String name;
  final num price;
}

List<_FoodSizeOption> _parseFoodSizeOptions(
  dynamic raw,
  dynamic fallbackPrice,
) {
  final fallback = num.tryParse('$fallbackPrice') ?? 0;
  final rows = raw is List ? raw : const [];
  return rows
      .map((row) {
        if (row is Map) {
          final name = '${row['name'] ?? row['label'] ?? ''}'.trim();
          if (name.isEmpty) return null;
          return _FoodSizeOption(
            name: name,
            price: num.tryParse('${row['price'] ?? fallback}') ?? fallback,
          );
        }
        final name = '$row'.trim();
        if (name.isEmpty) return null;
        return _FoodSizeOption(name: name, price: fallback);
      })
      .whereType<_FoodSizeOption>()
      .toList();
}

_FoodSizeOption? _firstFoodSizeOption(
  List<_FoodSizeOption> options,
  String? name,
) {
  if (name == null) return null;
  for (final option in options) {
    if (option.name == name) return option;
  }
  return null;
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.cart});
  final Map<String, dynamic> cart;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _priceRow(
        "\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u09a6\u09be\u09ae",
        cart['items_total'],
      ),
      _priceRow(
        "\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u099a\u09be\u09b0\u09cd\u099c",
        cart['delivery_fee'],
        pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
      ),
      if (cart['delivery_distance_km'] != null ||
          cart['delivery_charge_label'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              [
                if (cart['delivery_distance_km'] != null)
                  'দূরত্ব ${cart['delivery_distance_km']} KM',
                if (cart['delivery_charge_label'] != null)
                  '${cart['delivery_charge_label']}',
              ].join(' • '),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      if ((num.tryParse("${cart['discount_amount'] ?? 0}") ?? 0) > 0)
        _priceRow("\u099b\u09be\u09dc", "-${cart['discount_amount']}"),
      const Divider(),
      _priceRow("\u09ae\u09cb\u099f", cart['grand_total'], strong: true),
    ],
  );
  Widget _priceRow(
    String label,
    dynamic value, {
    bool strong = false,
    String? pendingText,
  }) => Padding(
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
          pendingText ?? (value == '...' ? '...' : "\u09f3${value ?? 0}"),
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
