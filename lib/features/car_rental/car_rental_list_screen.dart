import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'car_rental_details_screen.dart';

class CarRentalListScreen extends StatefulWidget {
  const CarRentalListScreen({super.key, required this.categoryId, required this.categoryName});

  final int categoryId;
  final String categoryName;

  @override
  State<CarRentalListScreen> createState() => _CarRentalListScreenState();
}

class _CarRentalListScreenState extends State<CarRentalListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
  String? _transmission;
  String? _fuel;
  String? _seats;
  bool _driver = false;
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
      final res = await _api.get('/car-rentals', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        'category_id': widget.categoryId.toString(),
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_transmission != null && _transmission!.isNotEmpty) 'transmission': _transmission!,
        if (_fuel != null && _fuel!.isNotEmpty) 'fuel_type': _fuel!,
        if (_seats != null && _seats!.isNotEmpty) 'seats': _seats!,
        if (_driver) 'driver_available': '1',
      });
      final nextItems = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? nextItems : [..._items, ...nextItems];
      _page = (res['current_page'] as num?)?.toInt() ?? _page;
      _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
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
      appBar: ModernAppBar(title: widget.categoryName, subtitle: 'গাড়ির তালিকা'),
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
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'গাড়ি সার্চ'),
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
                      key: const ValueKey('car_filters'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _district,
                          decoration: const InputDecoration(labelText: 'জেলা'),
                          onSubmitted: (_) => _load(reset: true),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _transmission,
                          decoration: const InputDecoration(labelText: 'ট্রান্সমিশন'),
                          items: const ['ম্যানুয়াল', 'অটো', 'সেমি-অটো']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _transmission = value),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _fuel,
                          decoration: const InputDecoration(labelText: 'ফুয়েল'),
                          items: const ['পেট্রোল', 'ডিজেল', 'সিএনজি', 'অকটেন', 'ইলেকট্রিক']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _fuel = value),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _seats,
                          decoration: const InputDecoration(labelText: 'সিট সংখ্যা'),
                          items: const ['4', '5', '7', '8', '10', '12', '20', '30', '40']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _seats = value),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('চালকসহ'),
                              selected: _driver,
                              onSelected: (v) => setState(() => _driver = v),
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
                child: Center(child: Text('কোনো গাড়ি পাওয়া যায়নি')),
              )
            else
              ...[
                ..._items.map((item) => _carCard(context, item, scheme)),
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

  Widget _carCard(BuildContext context, Map<String, dynamic> item, ColorScheme scheme) {
    final title = (item['title'] ?? 'গাড়ি').toString();
    final brand = (item['brand'] ?? '').toString();
    final district = (item['district'] ?? '').toString();
    final price = (item['price_per_day'] ?? '').toString();
    final imageUrl = (item['image_url'] ?? '').toString();
    final rating = double.tryParse((item['rating'] ?? '0').toString()) ?? 0;
    final id = (item['id'] as num?)?.toInt() ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarRentalDetailsScreen(rentalId: id)))
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
              child: imageUrl.isEmpty ? Icon(Icons.directions_car, color: scheme.primary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (brand.isNotEmpty) Text(brand, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (district.isNotEmpty) Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            if (price.isNotEmpty && price != 'null')
              Text('৳ $price/দিন', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
