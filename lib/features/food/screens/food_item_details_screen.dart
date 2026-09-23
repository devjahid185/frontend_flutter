part of '../food_home_screen.dart';

/// ---------------------------------------------------------------------------
/// FoodItemDetailsScreen
/// ---------------------------------------------------------------------------
/// A from-scratch composition: the photo stays pinned behind the scroll and
/// a white, rounded-top sheet slides up over it — rather than a plain image
/// banner sitting above a flat list. Size/spice options are now selectable
/// chip cards instead of radio rows, and the bottom bar floats as its own
/// elevated pill above the page. All state, API calls and navigation are
/// unchanged from before — only how it's presented.
class FoodItemDetailsScreen extends StatefulWidget {
  const FoodItemDetailsScreen({
    super.key,
    required this.item,
    this.heroTagPrefix = 'food-image',
  });

  final Map<String, dynamic> item;
  final String heroTagPrefix;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('কার্টে যোগ হয়েছে')));
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
    final item = _item;
    final sizes = _parseFoodSizeOptions(
      item['size_options'],
      item['discount_price'] ?? item['price'],
    );
    final spices = ((item['spice_options'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final basePrice =
        num.tryParse('${item['discount_price'] ?? item['price']}') ?? 0;
    if (sizes.isEmpty) _size = null;
    if (sizes.isNotEmpty && _size == null) _size = sizes.first.name;
    if (spices.isEmpty) _spice = null;
    final selectedSize = _firstFoodSizeOption(sizes, _size);
    final price = selectedSize?.price ?? basePrice;
    final total = ((num.tryParse('$price') ?? 0) * _qty).toStringAsFixed(0);
    final description = '${item['description'] ?? ''}'.trim();

    const heroHeight = 300.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: _FoodItemBottomBar(
        qty: _qty,
        total: total,
        saving: _saving,
        onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
        onPlus: () => setState(() => _qty++),
        onAdd: _saving ? null : _add,
      ),
      body: Stack(
        children: [
          // ---- Photo, pinned behind the scroll -----------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Hero(
              tag: '${widget.heroTagPrefix}-${item['id'] ?? item.hashCode}',
              child: _FoodImage(
                url: item['image_url']?.toString(),
                height: heroHeight,
                width: double.infinity,
              ),
            ),
          ),

          // ---- Rounded sheet that slides up over the photo -----------------
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: heroHeight - 26),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FoodItemHeader(
                                item: item,
                                description: description,
                                price: price,
                              ),
                              if (sizes.isNotEmpty) ...[
                                const _FoodItemDivider(),
                                _FoodItemOptionSection(
                                  title: 'সাইজ নির্বাচন করুন',
                                  requiredLabel: true,
                                  child: _FoodItemChoiceWrap(
                                    items: [
                                      for (final option in sizes)
                                        _FoodItemChoiceData(
                                          label: option.name,
                                          price: option.price,
                                          selected: _size == option.name,
                                          onTap: () => setState(
                                            () => _size = option.name,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              if (spices.isNotEmpty) ...[
                                const _FoodItemDivider(),
                                _FoodItemOptionSection(
                                  title: 'ঝাল নির্বাচন করুন',
                                  child: _FoodItemChoiceWrap(
                                    items: [
                                      for (final spice in spices)
                                        _FoodItemChoiceData(
                                          label: spice,
                                          selected: _spice == spice,
                                          onTap: () =>
                                              setState(() => _spice = spice),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              const _FoodItemDivider(),
                              const Text(
                                'বিশেষ নির্দেশনা',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: TextField(
                                  controller: _note,
                                  minLines: 2,
                                  maxLines: 3,
                                  style: const TextStyle(fontSize: 14.5),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'যেমন: ঝাল কম, পেঁয়াজ ছাড়া ইত্যাদি...',
                                    hintStyle: TextStyle(
                                      color: AppColors.inkMuted,
                                    ),
                                    filled: false,
                                    contentPadding: EdgeInsets.all(14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _FoodReviewsPanel(
                                restaurantId: (item['restaurant_id'] as num?)
                                    ?.toInt(),
                                foodItemId: (item['id'] as num?)?.toInt(),
                                reviews: (item['reviews'] as List?) ?? const [],
                                onChanged: _loadDetails,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ---- Floating back button ------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: PressableScale(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.raised,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.ink,
                    size: 19,
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

class _FoodItemHeader extends StatelessWidget {
  const _FoodItemHeader({
    required this.item,
    required this.description,
    required this.price,
  });

  final Map<String, dynamic> item;
  final String description;
  final num price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item['name']}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.slow,
          curve: AppMotion.pop,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            alignment: Alignment.centerLeft,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sell_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '৳$price',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodItemDivider extends StatelessWidget {
  const _FoodItemDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _FoodItemOptionSection extends StatelessWidget {
  const _FoodItemOptionSection({
    required this.title,
    required this.child,
    this.requiredLabel = false,
  });

  final String title;
  final Widget child;
  final bool requiredLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (requiredLabel)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'প্রয়োজনীয়',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Plain data holder for one selectable chip — not a widget itself.
class _FoodItemChoiceData {
  const _FoodItemChoiceData({
    required this.label,
    required this.selected,
    required this.onTap,
    this.price,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final num? price;
}

/// Size/spice options as a wrap of tactile chip cards instead of a list of
/// radio rows — each one animates its own selection state independently.
class _FoodItemChoiceWrap extends StatelessWidget {
  const _FoodItemChoiceWrap({required this.items});

  final List<_FoodItemChoiceData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final data in items) _FoodItemChoiceChip(data: data)],
    );
  }
}

class _FoodItemChoiceChip extends StatelessWidget {
  const _FoodItemChoiceChip({required this.data});

  final _FoodItemChoiceData data;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${data.label}-${data.selected}'),
        tween: Tween(begin: data.selected ? 0.86 : 1, end: 1),
        duration: AppMotion.fast,
        curve: AppMotion.pop,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: data.selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: data.selected ? AppColors.primary : AppColors.border,
              width: data.selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: TextStyle(
                  color: data.selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              if (data.price != null) ...[
                const SizedBox(height: 2),
                Text(
                  '৳${data.price!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: data.selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.inkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating, elevated action bar — deliberately not the flat top-bordered
/// bar the file used to have. Rises into place, and both the quantity and
/// the price/label animate whenever they change instead of snapping.
class _FoodItemBottomBar extends StatefulWidget {
  const _FoodItemBottomBar({
    required this.qty,
    required this.total,
    required this.saving,
    required this.onPlus,
    required this.onAdd,
    this.onMinus,
  });

  final int qty;
  final String total;
  final bool saving;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onAdd;

  @override
  State<_FoodItemBottomBar> createState() => _FoodItemBottomBarState();
}

class _FoodItemBottomBarState extends State<_FoodItemBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _entrance, curve: AppMotion.enter);
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, child) => Opacity(
          opacity: curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - curve.value) * 24),
            child: child,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.raised,
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md + 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FoodItemQtyButton(
                      icon: Icons.remove_rounded,
                      onPressed: widget.onMinus,
                    ),
                    SizedBox(
                      width: 32,
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Text(
                          '${widget.qty}',
                          key: ValueKey(widget.qty),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _FoodItemQtyButton(
                      icon: Icons.add_rounded,
                      onPressed: widget.onPlus,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PressableScale(
                  onTap: widget.onAdd,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.onAdd == null
                          ? AppColors.inkMuted4
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.base,
                      child: Text(
                        widget.saving
                            ? 'যোগ হচ্ছে...'
                            : 'কার্টে যোগ করুন (৳${widget.total})',
                        key: ValueKey('${widget.saving}-${widget.total}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _FoodItemQtyButton extends StatelessWidget {
  const _FoodItemQtyButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return PressableScale(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.ink : AppColors.inkMuted4,
        ),
      ),
    );
  }
}
