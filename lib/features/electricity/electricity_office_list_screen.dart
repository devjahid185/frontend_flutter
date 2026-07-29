import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'electricity_office_details_screen.dart';
import 'electricity_office_form_screen.dart';
import 'my_electricity_offices_screen.dart';

class ElectricityOfficeListScreen extends StatefulWidget {
  const ElectricityOfficeListScreen({super.key});

  @override
  State<ElectricityOfficeListScreen> createState() => _ElectricityOfficeListScreenState();
}

class _ElectricityOfficeListScreenState extends State<ElectricityOfficeListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _provider = TextEditingController();
  final TextEditingController _officeType = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
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
    _provider.dispose();
    _officeType.dispose();
    _district.dispose();
    _upazila.dispose();
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
      final res = await _api.get('/electricity/offices', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_provider.text.trim().isNotEmpty) 'provider': _provider.text.trim(),
        if (_officeType.text.trim().isNotEmpty) 'office_type': _officeType.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_upazila.text.trim().isNotEmpty) 'upazila': _upazila.text.trim(),
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
      appBar: const ModernAppBar(title: 'বিদ্যুৎ অফিস', subtitle: 'বিদ্যুৎ অফিসের তালিকা'),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ElectricityOfficeFormScreen()),
                    ),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('অফিস যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyElectricityOfficesScreen()),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার অফিস'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'অফিস সার্চ'),
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
                      key: const ValueKey('electricity_filters'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _provider,
                          decoration: const InputDecoration(labelText: 'প্রোভাইডার'),
                          onSubmitted: (_) => _load(reset: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _officeType,
                          decoration: const InputDecoration(labelText: 'অফিস টাইপ'),
                          onSubmitted: (_) => _load(reset: true),
                        ),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _load(reset: true),
                            icon: const Icon(Icons.filter_list),
                            label: const Text('ফিল্টার প্রয়োগ'),
                          ),
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
                child: Center(child: Text('কোনো অফিস পাওয়া যায়নি')),
              )
            else
              ...[
                ..._items.map((office) => _officeCard(context, office, scheme)),
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

  Widget _officeCard(BuildContext context, Map<String, dynamic> office, ColorScheme scheme) {
    final name = (office['name'] ?? 'অফিস').toString();
    final provider = (office['provider'] ?? '').toString();
    final officeType = (office['office_type'] ?? '').toString();
    final district = (office['district'] ?? '').toString();
    final upazila = (office['upazila'] ?? '').toString();
    final address = (office['address'] ?? '').toString();
    final id = (office['id'] as num?)?.toInt() ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ElectricityOfficeDetailsScreen(officeId: id)))
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
              radius: 22,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.electrical_services_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (provider.isNotEmpty) Text(provider, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (officeType.isNotEmpty) Text(officeType, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (district.isNotEmpty || upazila.isNotEmpty)
                    Text(
                      [district, upazila].where((e) => e.isNotEmpty).join(', '),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  if (address.isNotEmpty) Text(address, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
