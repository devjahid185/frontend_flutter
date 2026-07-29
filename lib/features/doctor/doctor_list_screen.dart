import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'doctor_details_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key, required this.categoryId, required this.categoryName});

  final int categoryId;
  final String categoryName;

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
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
      final res = await _api.get('/doctors', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        'category_id': widget.categoryId.toString(),
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
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
      appBar: ModernAppBar(title: widget.categoryName, subtitle: 'ডাক্তার তালিকা'),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'ডাক্তার সার্চ'),
              onSubmitted: (_) => _load(reset: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'জেলা'),
              onSubmitted: (_) => _load(reset: true),
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
                child: Center(child: Text('কোনো ডাক্তার পাওয়া যায়নি')),
              )
            else
              ...[
                ..._items.map((doc) => _doctorCard(context, doc)),
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

  Widget _doctorCard(BuildContext context, Map<String, dynamic> doc) {
    final scheme = Theme.of(context).colorScheme;
    final name = (doc['name'] ?? 'ডাক্তার').toString();
    final title = (doc['title'] ?? '').toString();
    final spec = (doc['specialization'] ?? '').toString();
    final hospital = (doc['hospital'] ?? '').toString();
    final fees = (doc['fees'] ?? '').toString();
    final imageUrl = (doc['image_url'] ?? '').toString();
    final available = doc['is_available'] == true || doc['is_available'] == 1;
    final id = (doc['id'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: id > 0 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: id))) : null,
      borderRadius: BorderRadius.circular(18),
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
              child: imageUrl.isEmpty ? Icon(Icons.medical_services_outlined, color: scheme.primary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (title.isNotEmpty) Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (spec.isNotEmpty) Text(spec, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (hospital.isNotEmpty) Text(hospital, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fees.isEmpty ? '-' : '৳ $fees', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: available ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(available ? 'সেবা চলছে' : 'সেবা বন্ধ', style: TextStyle(color: scheme.onPrimary, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
