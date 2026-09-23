part of '../food_home_screen.dart';

/// ---------------------------------------------------------------------------
/// FoodRestaurantDetailsScreen
/// ---------------------------------------------------------------------------
/// Rebuilt again to share the same design language introduced for the rider
/// dashboard: a solid-colour identity hero (name + avatar-style initial +
/// a divided stats row) instead of a photo sheet, icon-over-label tabs with
/// a sliding underline instead of plain text tabs, and left-accent-stripe
/// cards for every section instead of bordered boxes. The restaurant photo
/// now lives in a collapsing SliverAppBar instead of being pinned behind a
/// sliding sheet. All state and API calls are unchanged.
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
  String _activeSection = 'menu';
  final _menuKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  final _infoKey = GlobalKey();

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

  Future<void> _scrollToSection(String section) async {
    final key = switch (section) {
      'reviews' => _reviewsKey,
      'info' => _infoKey,
      _ => _menuKey,
    };
    setState(() => _activeSection = section);
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ((_restaurant['menu_items'] as List?) ?? []).where((item) {
      if (_category == 'all') return true;
      return '${item['food_category_id']}' == _category;
    }).toList();
    final categories = (_restaurant['menu_categories'] as List?) ?? [];
    final reviews = (_restaurant['reviews'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight: 208,
                    backgroundColor: AppColors.surface,
                    surfaceTintColor: AppColors.surface,
                    elevation: 0,
                    scrolledUnderElevation: 1,
                    shadowColor: AppColors.ink.withValues(alpha: 0.1),
                    leadingWidth: 62,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _HeroCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _HeroCircleButton(
                          onPressed: _openCart,
                          child: _CartBadgeIcon(count: _cartCount, size: 21),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag:
                            'restaurant-image-${_restaurant['id'] ?? widget.id}',
                        child: _FoodImage(
                          url: _restaurant['image_url']?.toString(),
                          height: 208,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeSlideIn(
                        child: _RestaurantHeroPanel(restaurant: _restaurant),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryBar(
                      height: 74,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _RestaurantMenuTabs(
                          activeSection: _activeSection,
                          onSelected: _scrollToSection,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        key: _menuKey,
                        child: _RestaurantMenuBody(
                          categories: categories,
                          selectedCategory: _category,
                          items: items,
                          onCategoryChanged: (value) =>
                              setState(() => _category = value),
                          onItemTap: (item) async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FoodItemDetailsScreen(item: item),
                              ),
                            );
                            _loadCartCount();
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        key: _reviewsKey,
                        child: _RestaurantSectionCard(
                          title: 'রিভিউ',
                          icon: Icons.star_rounded,
                          child: _FoodReviewsPanel(
                            restaurantId: widget.id,
                            reviews: reviews,
                            onChanged: _load,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        key: _infoKey,
                        child: _RestaurantSectionCard(
                          title: 'রেস্টুরেন্ট তথ্য',
                          icon: Icons.info_outline_rounded,
                          child: _RestaurantInfoPanel(restaurant: _restaurant),
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

/// Solid-colour identity card — mirrors the rider dashboard's hero panel:
/// a circular initial avatar, name/subtitle, and a divided stats row.
class _RestaurantHeroPanel extends StatelessWidget {
  const _RestaurantHeroPanel({required this.restaurant});

  final Map<String, dynamic> restaurant;

  @override
  Widget build(BuildContext context) {
    final name = '${restaurant['name'] ?? 'রেস্টুরেন্ট'}';
    final subtitle = '${restaurant['cuisine'] ?? restaurant['address'] ?? ''}'
        .trim();
    final initial = name.trim().isEmpty ? 'র' : name.trim().substring(0, 1);
    final reviews = (restaurant['reviews'] as List?) ?? const [];
    final reviewsCount =
        (restaurant['reviews_count'] as num?)?.toInt() ?? reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
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
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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
                  child: _RestaurantHeroStat(
                    label: '$reviewsCount রিভিউ',
                    value: '${restaurant['rating'] ?? 0}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _RestaurantHeroStat(
                    label: 'ডেলিভারি',
                    value: '${restaurant['delivery_time'] ?? '৩০-৫০ মিঃ'}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _RestaurantHeroStat(
                    label: 'মিনিমাম',
                    value: '৳${restaurant['minimum_order'] ?? 0}',
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

class _RestaurantHeroStat extends StatelessWidget {
  const _RestaurantHeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('restaurant-hero-stat-$label-$value'),
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
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.onPressed, this.icon, this.child});

  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadow.raised,
        ),
        child: child ?? Icon(icon, color: AppColors.ink, size: 19),
      ),
    );
  }
}

/// Icon-over-label tabs with a sliding underline — the same mechanism used
/// for the rider dashboard's tab switcher, applied here to menu/reviews/info.
class _RestaurantMenuTabs extends StatelessWidget {
  const _RestaurantMenuTabs({
    required this.activeSection,
    required this.onSelected,
  });

  final String activeSection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('menu', Icons.restaurant_menu_rounded, 'মেনু'),
      ('reviews', Icons.star_rounded, 'রিভিউ'),
      ('info', Icons.info_outline_rounded, 'তথ্য'),
    ];
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tabs.map((tab) {
          final selected = activeSection == tab.$1;
          return Expanded(
            child: PressableScale(
              onTap: () => onSelected(tab.$1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.$2,
                    size: 19,
                    color: selected ? AppColors.primary : AppColors.inkMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.primary : AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 3,
                    width: selected ? 30 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RestaurantMenuBody extends StatelessWidget {
  const _RestaurantMenuBody({
    required this.categories,
    required this.selectedCategory,
    required this.items,
    required this.onCategoryChanged,
    required this.onItemTap,
  });

  final List<dynamic> categories;
  final String selectedCategory;
  final List<dynamic> items;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Map<String, dynamic>> onItemTap;

  @override
  Widget build(BuildContext context) {
    final selectedName = _selectedCategoryName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RestaurantCategoryRail(
          categories: categories,
          selectedCategory: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                selectedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.tealSoft2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length} আইটেম',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _RestaurantEmptyMenu()
        else
          ...items.asMap().entries.map((entry) {
            final item = Map<String, dynamic>.from(entry.value as Map);
            return FadeSlideIn(
              index: entry.key,
              child: _RestaurantMenuItemCard(
                item: item,
                onTap: () => onItemTap(item),
              ),
            );
          }),
      ],
    );
  }

  String _selectedCategoryName() {
    if (selectedCategory == 'all') return 'সব মেনু';
    for (final raw in categories) {
      final category = Map<String, dynamic>.from(raw as Map);
      if ('${category['id']}' == selectedCategory) return '${category['name']}';
    }
    return 'মেনু';
  }
}

class _RestaurantCategoryRail extends StatelessWidget {
  const _RestaurantCategoryRail({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<dynamic> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = [
      const {'id': 'all', 'name': 'সব মেনু'},
      ...categories.map((raw) {
        final category = Map<String, dynamic>.from(raw as Map);
        return {'id': '${category['id']}', 'name': '${category['name']}'};
      }),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final row = rows[index];
          final selected = selectedCategory == row['id'];
          return PressableScale(
            onTap: () => onChanged(row['id']!),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              constraints: const BoxConstraints(minWidth: 78),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                row['name']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Left-accent-stripe card, matching the rider dashboard's `_card()` helper
/// — a solid colour bar down the left edge instead of an all-round border.
class _RestaurantSectionCard extends StatelessWidget {
  const _RestaurantSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.primary, size: 19),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

/// A menu row — left-accent stripe (matching the section-card language)
/// plus a photo with a floating circular add button overlapping its
/// bottom-right corner, matching the FoodProductCard language.
class _RestaurantMenuItemCard extends StatefulWidget {
  const _RestaurantMenuItemCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  State<_RestaurantMenuItemCard> createState() =>
      _RestaurantMenuItemCardState();
}

class _RestaurantMenuItemCardState extends State<_RestaurantMenuItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _addButton = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );

  @override
  void dispose() {
    _addButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final price = item['discount_price'] ?? item['price'] ?? 0;
    final oldPrice = item['discount_price'] == null ? null : item['price'];
    final badge = '${item['tag'] ?? item['badge'] ?? ''}'.trim();
    final compact = MediaQuery.sizeOf(context).width < 390;
    final imageWidth = compact ? 92.0 : 108.0;
    final imageHeight = compact ? 84.0 : 96.0;

    return PressableScale(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (badge.isNotEmpty) ...[
                              _RestaurantItemBadge(text: badge),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              '${item['name']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15.5,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if ('${item['description'] ?? ''}'.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${item['description']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '৳$price',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (oldPrice != null) ...[
                                  const SizedBox(width: 7),
                                  Text(
                                    '৳$oldPrice',
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 12.5,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _FoodImage(
                                url: item['image_url']?.toString(),
                                width: imageWidth,
                                height: imageHeight,
                              ),
                            ),
                            Positioned(
                              right: -6,
                              bottom: -10,
                              child: Builder(
                                builder: (buttonContext) => AnimatedBuilder(
                                  animation: _addButton,
                                  builder: (context, child) {
                                    final t = _addButton.value;
                                    final scale = t < 0.5
                                        ? 1 - (t * 0.34)
                                        : 0.83 + ((t - 0.5) * 0.34);
                                    return Transform.scale(
                                      scale: t == 0 ? 1 : scale,
                                      child: child,
                                    );
                                  },
                                  child: Material(
                                    color: AppColors.primary,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        _addButton.forward(from: 0);
                                        widget.onTap();
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
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
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _RestaurantItemBadge extends StatelessWidget {
  const _RestaurantItemBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RestaurantEmptyMenu extends StatelessWidget {
  const _RestaurantEmptyMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.inkMuted4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: const Text(
                  'এই ক্যাটাগরিতে কোনো খাবার নেই',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
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

class _RestaurantInfoPanel extends StatelessWidget {
  const _RestaurantInfoPanel({required this.restaurant});

  final Map<String, dynamic> restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RestaurantInfoRow(
          icon: Icons.location_on_outlined,
          text: '${restaurant['address'] ?? 'ঠিকানা দেওয়া নেই'}',
        ),
        const SizedBox(height: 10),
        _RestaurantInfoRow(
          icon: Icons.schedule_rounded,
          text: '${restaurant['delivery_time'] ?? '৩০-৫০ মিনিট'}',
        ),
      ],
    );
  }
}

class _RestaurantInfoRow extends StatelessWidget {
  const _RestaurantInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.teal, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.ink3,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}