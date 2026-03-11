import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'hospital_details_screen.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.categoryId, required this.categoryName});

  final int categoryId;
  final String categoryName;

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
  String? _type;
  bool _emergency = false;
  bool _icu = false;
  bool _ambulance = false;
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
      final res = await _api.get('/hospitals', query: {
        'category_id': widget.categoryId.toString(),
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        if (_type != null && _type!.isNotEmpty) 'type': _type!,
        if (_emergency) 'emergency_available': '1',
        if (_icu) 'icu_available': '1',
        if (_ambulance) 'ambulance_available': '1',
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
      appBar: ModernAppBar(title: widget.categoryName, subtitle: 'হাসপাতাল তালিকা'),
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
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'হাসপাতাল সার্চ'),
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
                      key: const ValueKey('hospital_filters'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _district,
                          decoration: const InputDecoration(labelText: 'জেলা'),
                          onSubmitted: (_) => _load(),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'টাইপ'),
                          items: const ['সরকারি', 'বেসরকারি', 'ডায়াগনস্টিক', 'ক্লিনিক']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _type = value),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('ইমার্জেন্সি'),
                              selected: _emergency,
                              onSelected: (v) => setState(() => _emergency = v),
                            ),
                            FilterChip(
                              label: const Text('আইসিইউ'),
                              selected: _icu,
                              onSelected: (v) => setState(() => _icu = v),
                            ),
                            FilterChip(
                              label: const Text('অ্যাম্বুলেন্স'),
                              selected: _ambulance,
                              onSelected: (v) => setState(() => _ambulance = v),
                            ),
                            TextButton(onPressed: _load, child: const Text('ফিল্টার প্রয়োগ')),
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
                child: Center(child: Text('কোনো হাসপাতাল পাওয়া যায়নি')),
              )
            else
              ..._items.map((hospital) => _hospitalCard(context, hospital, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _hospitalCard(BuildContext context, Map<String, dynamic> hospital, ColorScheme scheme) {
    final name = (hospital['name'] ?? 'হাসপাতাল').toString();
    final category = (hospital['category_name'] ?? '').toString();
    final district = (hospital['district'] ?? '').toString();
    final phone = (hospital['phone'] ?? '').toString();
    final imageUrl = (hospital['image_url'] ?? '').toString();
    final id = (hospital['id'] as num?)?.toInt() ?? 0;
    final emergency = hospital['emergency_available'] == true || hospital['emergency_available'] == 1;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HospitalDetailsScreen(hospitalId: id)))
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
              child: imageUrl.isEmpty ? Icon(Icons.local_hospital_outlined, color: scheme.primary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (district.isNotEmpty) Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (category.isNotEmpty) Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (emergency)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('ইমার্জেন্সি', style: TextStyle(color: scheme.onPrimary, fontSize: 10)),
                  ),
                if (phone.isNotEmpty) const SizedBox(height: 6),
                if (phone.isNotEmpty) Icon(Icons.call_outlined, color: scheme.primary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
