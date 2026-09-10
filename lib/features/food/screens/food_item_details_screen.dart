part of '../food_home_screen.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('কার্টে যোগ হয়েছে')));
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

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _FoodItemBottomBar(
        qty: _qty,
        total: total,
        saving: _saving,
        onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
        onPlus: () => setState(() => _qty++),
        onAdd: _saving ? null : _add,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _FoodItemHero(
              item: item,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FoodItemHeader(item: item, price: price),
                  if (sizes.isNotEmpty) ...[
                    const _FoodItemDivider(),
                    _FoodItemOptionSection(
                      title: 'সাইজ নির্বাচন করুন',
                      requiredLabel: true,
                      children: sizes.map((option) {
                        return _FoodItemRadioRow(
                          title: option.name,
                          price: option.price,
                          selected: _size == option.name,
                          onTap: () => setState(() => _size = option.name),
                        );
                      }).toList(),
                    ),
                  ],
                  if (spices.isNotEmpty) ...[
                    const _FoodItemDivider(),
                    _FoodItemOptionSection(
                      title: 'ঝাল নির্বাচন করুন',
                      children: spices.map((spice) {
                        return _FoodItemRadioRow(
                          title: spice,
                          selected: _spice == spice,
                          onTap: () => setState(() => _spice = spice),
                        );
                      }).toList(),
                    ),
                  ],
                  const _FoodItemDivider(),
                  const Text(
                    'বিশেষ নির্দেশনা',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'যেমন: ঝাল কম, পেঁয়াজ ছাড়া ইত্যাদি...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF00765B),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FoodReviewsPanel(
                    restaurantId: (item['restaurant_id'] as num?)?.toInt(),
                    foodItemId: (item['id'] as num?)?.toInt(),
                    reviews: (item['reviews'] as List?) ?? const [],
                    onChanged: _loadDetails,
                  ),
                  const SizedBox(height: 86),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItemHero extends StatelessWidget {
  const _FoodItemHero({required this.item, required this.onBack});

  final Map<String, dynamic> item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FoodImage(url: item['image_url']?.toString(), height: 318),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.16),
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.14),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1F2937),
                        size: 23,
                      ),
                    ),
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
  const _FoodItemHeader({required this.item, required this.price});

  final Map<String, dynamic> item;
  final num price;

  @override
  Widget build(BuildContext context) {
    final description = '${item['description'] ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item['name']}',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 25,
            height: 1.12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15.5,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          '৳$price',
          style: const TextStyle(
            color: Color(0xFF00765B),
            fontSize: 24,
            fontWeight: FontWeight.w700,
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
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
    );
  }
}

class _FoodItemOptionSection extends StatelessWidget {
  const _FoodItemOptionSection({
    required this.title,
    required this.children,
    this.requiredLabel = false,
  });

  final String title;
  final List<Widget> children;
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
                  color: Color(0xFF1F2937),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
                  color: const Color(0xFFEAF5F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'প্রয়োজনীয়',
                  style: TextStyle(
                    color: Color(0xFF00765B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _FoodItemRadioRow extends StatelessWidget {
  const _FoodItemRadioRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.price,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final num? price;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00765B)
                      : const Color(0xFF9CA3AF),
                  width: selected ? 2.5 : 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00765B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (price != null)
              Text(
                '৳${price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodItemBottomBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FoodItemQtyButton(
                    icon: Icons.remove_rounded,
                    onPressed: onMinus,
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _FoodItemQtyButton(
                    icon: Icons.add_rounded,
                    onPressed: onPlus,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00765B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  saving ? 'যোগ হচ্ছে...' : 'কার্টে যোগ করুন (৳$total)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
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

class _FoodItemQtyButton extends StatelessWidget {
  const _FoodItemQtyButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22),
      color: const Color(0xFF1F2937),
      disabledColor: const Color(0xFFB8C0BB),
    );
  }
}
