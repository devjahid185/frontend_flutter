import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'restaurant_details_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key, required this.categoryId, required this.categoryName});

  final int categoryId;
  final String categoryName;

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _minPrice = TextEditingController();
  final TextEditingController _maxPrice = TextEditingController();
  bool _delivery = false;
  bool _takeaway = false;
  bool _dineIn = false;
  bool _showFilters = false;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _district.dispose();
    _upazila.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _page = 1;
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final res = await _api.get('/restaurants', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        'category_id': widget.categoryId.toString(),
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_upazila.text.trim().isNotEmpty) 'upazila': _upazila.text.trim(),
        if (_minPrice.text.trim().isNotEmpty) 'min_price': _minPrice.text.trim(),
        if (_maxPrice.text.trim().isNotEmpty) 'max_price': _maxPrice.text.trim(),
        if (_delivery) 'delivery_available': '1',
        if (_takeaway) 'takeaway_available': '1',
        if (_dineIn) 'dine_in_available': '1',
      });
      final nextItems = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? nextItems : [..._items, ...nextItems];
      _page = (res['current_page'] as num?)?.toInt() ?? _page;
      _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডাটা লোড করা যায়নি';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ModernAppBar(title: widget.categoryName, subtitle: 'রেস্টুরেন্ট তালিকা'),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'রেস্টুরেন্ট সার্চ'),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(_showFilters ? 'লুকান' : 'ফিল্টার', style: TextStyle(color: scheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: _showFilters
                  ? Column(
                      key: const ValueKey('restaurant_filters'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _district,
                          decoration: const InputDecoration(labelText: 'জেলা'),
                          onSubmitted: (_) => _load(reset: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _upazila,
                          decoration: const InputDecoration(labelText: 'উপজেলা'),
                          onSubmitted: (_) => _load(reset: true),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPrice,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'সর্বনিম্ন মূল্য'),
                                onSubmitted: (_) => _load(reset: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _maxPrice,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'সর্বোচ্চ মূল্য'),
                                onSubmitted: (_) => _load(reset: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('ডেলিভারি'),
                              selected: _delivery,
                              onSelected: (v) => setState(() => _delivery = v),
                            ),
                            FilterChip(
                              label: const Text('টেকঅ্যাওয়ে'),
                              selected: _takeaway,
                              onSelected: (v) => setState(() => _takeaway = v),
                            ),
                            FilterChip(
                              label: const Text('ডাইন-ইন'),
                              selected: _dineIn,
                              onSelected: (v) => setState(() => _dineIn = v),
                            ),
                            TextButton(onPressed: () => _load(reset: true), child: const Text('ফিল্টার প্রয়োগ')),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(child: Text(_error!, style: TextStyle(color: scheme.error))),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('কোনো রেস্টুরেন্ট পাওয়া যায়নি')),
              )
            else
              ...[
                ..._items.map((restaurant) => _restaurantCard(context, restaurant, scheme)),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 22),
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _loadMore,
                      icon: _loadingMore
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(_loadingMore ? 'লোড হচ্ছে...' : 'আরও দেখুন'),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _restaurantCard(BuildContext context, Map<String, dynamic> restaurant, ColorScheme scheme) {
    final name = (restaurant['name'] ?? 'রেস্টুরেন্ট').toString();
    final category = (restaurant['category_name'] ?? '').toString();
    final district = (restaurant['district'] ?? '').toString();
    final phone = (restaurant['phone'] ?? '').toString();
    final imageUrl = (restaurant['image_url'] ?? '').toString();
    final id = (restaurant['id'] as num?)?.toInt() ?? 0;
    final minPrice = restaurant['min_price'];
    final maxPrice = restaurant['max_price'];

    String priceText = '';
    if (minPrice != null || maxPrice != null) {
      final minVal = minPrice?.toString() ?? '';
      final maxVal = maxPrice?.toString() ?? '';
      priceText = '৳$minVal - ৳$maxVal';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantDetailsScreen(restaurantId: id)))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? Icon(Icons.restaurant_menu, color: scheme.primary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (district.isNotEmpty) Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (category.isNotEmpty) Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (priceText.isNotEmpty) Text(priceText, style: TextStyle(color: scheme.primary, fontSize: 12)),
                ],
              ),
            ),
            if (phone.isNotEmpty) Icon(Icons.call_outlined, color: scheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
