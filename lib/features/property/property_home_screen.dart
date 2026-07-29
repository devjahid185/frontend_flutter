import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'property_details_screen.dart';
import 'property_post_form_screen.dart';
import 'my_properties_screen.dart';

class PropertyHomeScreen extends StatefulWidget {
  const PropertyHomeScreen({super.key});

  @override
  State<PropertyHomeScreen> createState() => _PropertyHomeScreenState();
}

class _PropertyHomeScreenState extends State<PropertyHomeScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _priceMin = TextEditingController();
  final TextEditingController _priceMax = TextEditingController();
  final TextEditingController _bedrooms = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  bool _loadingCategories = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _search.dispose();
    _location.dispose();
    _priceMin.dispose();
    _priceMax.dispose();
    _bedrooms.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/properties/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _categories = [];
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _openPost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PropertyPostFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'প্রোপার্টি', subtitle: 'ভাড়া ও বিক্রয়'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPost,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('পোস্ট করুন'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyPropertiesScreen()),
                        ),
                        icon: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('আমার পোস্ট'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'সার্চ'),
                        onSubmitted: (_) => setState(() {}),
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
                          key: const ValueKey('filters'),
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _location,
                                    decoration: const InputDecoration(labelText: 'এলাকা/ঠিকানা'),
                                    onSubmitted: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _categoryId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'ক্যাটাগরি', isDense: true),
                                    items: _loadingCategories
                                        ? const []
                                        : _categories
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c['id'].toString(),
                                                child: Text(c['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) => setState(() => _categoryId = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _priceMin,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'দাম (সর্বনিম্ন)'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _priceMax,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'দাম (সর্বোচ্চ)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _bedrooms,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'বেডরুম (মিনিমাম)'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => setState(() {}),
                                      icon: const Icon(Icons.filter_list),
                                      label: const Text('ফিল্টার'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TabBar(
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'ভাড়া'),
                  Tab(text: 'বিক্রয়'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                children: [
                  PropertyListTab(
                    purpose: 'rent',
                    search: _search.text.trim(),
                    location: _location.text.trim(),
                    categoryId: _categoryId,
                    priceMin: _priceMin.text.trim(),
                    priceMax: _priceMax.text.trim(),
                    bedrooms: _bedrooms.text.trim(),
                  ),
                  PropertyListTab(
                    purpose: 'sell',
                    search: _search.text.trim(),
                    location: _location.text.trim(),
                    categoryId: _categoryId,
                    priceMin: _priceMin.text.trim(),
                    priceMax: _priceMax.text.trim(),
                    bedrooms: _bedrooms.text.trim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyListTab extends StatefulWidget {
  const PropertyListTab({
    super.key,
    required this.purpose,
    required this.search,
    required this.location,
    required this.categoryId,
    required this.priceMin,
    required this.priceMax,
    required this.bedrooms,
  });

  final String purpose;
  final String search;
  final String location;
  final String? categoryId;
  final String priceMin;
  final String priceMax;
  final String bedrooms;

  @override
  State<PropertyListTab> createState() => _PropertyListTabState();
}

class _PropertyListTabState extends State<PropertyListTab> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _hasMore => _page < _lastPage;

  @override
  void didUpdateWidget(covariant PropertyListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search ||
        oldWidget.location != widget.location ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.priceMin != widget.priceMin ||
        oldWidget.priceMax != widget.priceMax ||
        oldWidget.bedrooms != widget.bedrooms ||
        oldWidget.purpose != widget.purpose) {
      _load(reset: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
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
      final res = await _api.get('/properties', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        'purpose': widget.purpose,
        if (widget.search.isNotEmpty) 'q': widget.search,
        if (widget.location.isNotEmpty) 'location': widget.location,
        if (widget.categoryId != null && widget.categoryId!.isNotEmpty) 'category_id': widget.categoryId!,
        if (widget.priceMin.isNotEmpty) 'price_min': widget.priceMin,
        if (widget.priceMax.isNotEmpty) 'price_max': widget.priceMax,
        if (widget.bedrooms.isNotEmpty) 'bedrooms': widget.bedrooms,
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
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Text(_error!, style: TextStyle(color: scheme.error))),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('কোনো প্রোপার্টি নেই')),
            )
          else
            ...[
              ..._items.map((item) => _propertyCard(context, item)),
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
    );
  }

  Widget _propertyCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? 'প্রোপার্টি').toString();
    final price = (item['price'] ?? '').toString();
    final category = (item['category_name'] ?? '').toString();
    final beds = (item['bedrooms'] ?? '').toString();
    final baths = (item['bathrooms'] ?? '').toString();
    final area = (item['area'] ?? '').toString();
    final areaUnit = (item['area_unit'] ?? '').toString();
    final id = (item['id'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: id > 0 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailsScreen(propertyId: id))) : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.home_work_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (category.isNotEmpty)
                    Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('বেড: $beds, বাথ: $baths', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (area.isNotEmpty)
                    Text('এরিয়া: $area ${areaUnit.isEmpty ? '' : areaUnit}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Text(price.isEmpty ? '-' : '৳ $price', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
