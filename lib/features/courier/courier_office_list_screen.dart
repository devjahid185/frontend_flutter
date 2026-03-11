import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'courier_office_details_screen.dart';

class CourierOfficeListScreen extends StatefulWidget {
  const CourierOfficeListScreen({super.key, required this.companyId, required this.companyName});

  final int companyId;
  final String companyName;

  @override
  State<CourierOfficeListScreen> createState() => _CourierOfficeListScreenState();
}

class _CourierOfficeListScreenState extends State<CourierOfficeListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
  bool _showFilters = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/couriers/offices', query: {
        'company_id': widget.companyId.toString(),
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
      });
      _items = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ModernAppBar(title: widget.companyName, subtitle: 'অফিস তালিকা'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'অফিস সার্চ'),
                    onSubmitted: (_) => _load(),
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
                      key: const ValueKey('courier_filters'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _district,
                          decoration: const InputDecoration(labelText: 'জেলা'),
                          onSubmitted: (_) => _load(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _load,
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
              ..._items.map((office) => _officeCard(context, office, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _officeCard(BuildContext context, Map<String, dynamic> office, ColorScheme scheme) {
    final name = (office['name'] ?? 'অফিস').toString();
    final address = (office['address'] ?? '').toString();
    final district = (office['district'] ?? '').toString();
    final rating = double.tryParse((office['rating'] ?? '0').toString()) ?? 0;
    final id = (office['id'] as num?)?.toInt() ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierOfficeDetailsScreen(officeId: id)))
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
              child: Icon(Icons.local_shipping, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (district.isNotEmpty) Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (address.isNotEmpty) Text(address, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
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
    );
  }
}
