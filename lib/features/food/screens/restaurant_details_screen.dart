part of '../food_home_screen.dart';

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
      backgroundColor: const Color(0xFFF6F8F5),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _RestaurantMenuHero(
                  restaurant: _restaurant,
                  cartCount: _cartCount,
                  onBack: () => Navigator.of(context).maybePop(),
                  onCart: _openCart,
                ),
                _RestaurantMetricsBar(restaurant: _restaurant),
                _RestaurantMenuTabs(
                  activeSection: _activeSection,
                  onSelected: _scrollToSection,
                ),
                _RestaurantMenuBody(
                  key: _menuKey,
                  categories: categories,
                  selectedCategory: _category,
                  items: items,
                  onCategoryChanged: (value) =>
                      setState(() => _category = value),
                  onItemTap: (item) async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodItemDetailsScreen(item: item),
                      ),
                    );
                    _loadCartCount();
                  },
                ),
                Container(
                  key: _reviewsKey,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: _FoodReviewsPanel(
                    restaurantId: widget.id,
                    reviews: reviews,
                    onChanged: _load,
                  ),
                ),
                Container(
                  key: _infoKey,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _RestaurantInfoPanel(restaurant: _restaurant),
                ),
              ],
            ),
    );
  }
}

class _RestaurantMenuHero extends StatelessWidget {
  const _RestaurantMenuHero({
    required this.restaurant,
    required this.cartCount,
    required this.onBack,
    required this.onCart,
  });

  final Map<String, dynamic> restaurant;
  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final name = '${restaurant['name'] ?? 'রেস্টুরেন্ট'}';
    final subtitle = '${restaurant['cuisine'] ?? restaurant['address'] ?? ''}'
        .trim();

    return SizedBox(
      height: 286,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FoodImage(url: restaurant['image_url']?.toString(), height: 286),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F2F25).withValues(alpha: 0.18),
                  const Color(0xFF0F2F25).withValues(alpha: 0.08),
                  const Color(0xFF0F2F25).withValues(alpha: 0.74),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  _HeroCircleButton(
                    onPressed: onCart,
                    child: _CartBadgeIcon(count: cartCount, size: 28),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16392F).withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10231D),
                      fontSize: 26,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF00765B),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF647067),
                              fontSize: 14.5,
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0xFF16392F).withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Center(
            child:
                child ?? Icon(icon, color: const Color(0xFF1F2937), size: 28),
          ),
        ),
      ),
    );
  }
}

class _RestaurantMetricsBar extends StatelessWidget {
  const _RestaurantMetricsBar({required this.restaurant});

  final Map<String, dynamic> restaurant;

  @override
  Widget build(BuildContext context) {
    final reviews = (restaurant['reviews'] as List?) ?? const [];
    final reviewsCount =
        (restaurant['reviews_count'] as num?)?.toInt() ?? reviews.length;

    return Container(
      color: const Color(0xFFF6F8F5),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8E2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF153B31).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _RestaurantMetric(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFA51E),
                title: '${restaurant['rating'] ?? 0}',
                subtitle: '$reviewsCount রিভিউ',
              ),
            ),
            const _RestaurantMetricDivider(),
            Expanded(
              child: _RestaurantMetric(
                title: '${restaurant['delivery_time'] ?? '৩০-৫০ মিনিট'}',
                subtitle: 'ডেলিভারি সময়',
              ),
            ),
            const _RestaurantMetricDivider(),
            Expanded(
              child: _RestaurantMetric(
                title: '৳${restaurant['minimum_order'] ?? 0}',
                subtitle: 'মিনিমাম অর্ডার',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantMenuTabs extends StatelessWidget {
  const _RestaurantMenuTabs({
    required this.activeSection,
    required this.onSelected,
  });

  final String activeSection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8F5),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8E2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _RestaurantMenuTab(
                label: 'মেনু',
                active: activeSection == 'menu',
                onTap: () => onSelected('menu'),
              ),
            ),
            Expanded(
              child: _RestaurantMenuTab(
                label: 'রিভিউ',
                active: activeSection == 'reviews',
                onTap: () => onSelected('reviews'),
              ),
            ),
            Expanded(
              child: _RestaurantMenuTab(
                label: 'তথ্য',
                active: activeSection == 'info',
                onTap: () => onSelected('info'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantMetric extends StatelessWidget {
  const _RestaurantMetric({
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RestaurantMetricDivider extends StatelessWidget {
  const _RestaurantMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 46, color: const Color(0xFFE5E7EB));
  }
}

class _RestaurantMenuTab extends StatelessWidget {
  const _RestaurantMenuTab({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF00765B)
                      : const Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (active)
              Container(
                width: 54,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF00765B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantMenuBody extends StatelessWidget {
  const _RestaurantMenuBody({
    super.key,
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

    return Container(
      color: const Color(0xFFF6F8F5),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RestaurantCategoryRail(
            categories: categories,
            selectedCategory: selectedCategory,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10231D),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} আইটেম',
                  style: const TextStyle(
                    color: Color(0xFF00765B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _RestaurantEmptyMenu()
          else
            ...items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return _RestaurantMenuItemCard(
                item: item,
                onTap: () => onItemTap(item),
              );
            }),
        ],
      ),
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

    return Container(
      height: 44,
      color: const Color(0xFFF6F8F5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final row = rows[index];
          final selected = selectedCategory == row['id'];
          return Material(
            color: selected ? const Color(0xFF00765B) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(row['id']!),
              child: Container(
                constraints: const BoxConstraints(minWidth: 78),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00765B)
                        : const Color(0xFFE2E8E2),
                  ),
                ),
                child: Text(
                  row['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF3F4F47),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantMenuItemCard extends StatelessWidget {
  const _RestaurantMenuItemCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = item['discount_price'] ?? item['price'] ?? 0;
    final oldPrice = item['discount_price'] == null ? null : item['price'];
    final badge = '${item['tag'] ?? item['badge'] ?? ''}'.trim();
    final compact = MediaQuery.sizeOf(context).width < 390;
    final imageWidth = compact ? 86.0 : 104.0;
    final imageHeight = compact ? 80.0 : 92.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153B31).withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge.isNotEmpty) ...[
                        _RestaurantItemBadge(text: badge),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        '${item['name']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 17,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ('${item['description'] ?? ''}'.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${item['description']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14.5,
                            height: 1.32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '৳$price',
                            style: const TextStyle(
                              color: Color(0xFF00765B),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (oldPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '৳$oldPrice',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w700,
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
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _FoodImage(
                          url: item['image_url']?.toString(),
                          width: imageWidth,
                          height: imageHeight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00765B),
                          side: const BorderSide(
                            color: Color(0xFF00765B),
                            width: 1.4,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size(imageWidth, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'যোগ করুন',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
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

class _RestaurantItemBadge extends StatelessWidget {
  const _RestaurantItemBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFFF9F1C),
          fontSize: 12,
          fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'এই ক্যাটাগরিতে কোনো খাবার নেই',
        style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RestaurantInfoPanel extends StatelessWidget {
  const _RestaurantInfoPanel({required this.restaurant});

  final Map<String, dynamic> restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'রেস্টুরেন্ট তথ্য',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _RestaurantInfoRow(
            icon: Icons.location_on_outlined,
            text: '${restaurant['address'] ?? 'ঠিকানা দেওয়া নেই'}',
          ),
          const SizedBox(height: 8),
          _RestaurantInfoRow(
            icon: Icons.schedule_rounded,
            text: '${restaurant['delivery_time'] ?? '৩০-৫০ মিনিট'}',
          ),
        ],
      ),
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
        Icon(icon, color: const Color(0xFF00765B), size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
