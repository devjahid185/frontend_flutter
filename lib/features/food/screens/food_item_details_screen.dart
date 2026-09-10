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
      ).showSnackBar(const SnackBar(content: Text("কার্টে যোগ হয়েছে")));
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

    return Scaffold(
      appBar: ModernAppBar(
        title: "${item['name']}",
        subtitle: "সহজে অর্ডার করুন",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _add,
            child: Text(
              _saving
                  ? "যোগ হচ্ছে..."
                  : "কার্টে যোগ করুন - ৳${((num.tryParse('$price') ?? 0) * _qty).toStringAsFixed(0)}",
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
            "৳$price",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          if (sizes.isNotEmpty) ...[
            _OptionSection(
              title: "সাইজ",
              options: sizes.map((option) => option.name).toList(),
              value: _size,
              onChanged: (v) => setState(() => _size = v),
              labelFor: (v) {
                final option = _firstFoodSizeOption(sizes, v);
                return option == null
                    ? v
                    : '$v - ৳${option.price.toStringAsFixed(0)}';
              },
            ),
            const SizedBox(height: 12),
          ],
          if (spices.isNotEmpty) ...[
            _OptionSection(
              title: "ঝাল",
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
              labelText: "রেস্টুরেন্টের জন্য নোট",
              hintText: "যেমন: ঝাল কম, সস বেশি",
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
