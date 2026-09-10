import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'education_details_screen.dart';

class EducationListScreen extends StatefulWidget {
  const EducationListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  State<EducationListScreen> createState() => _EducationListScreenState();
}

class _EducationListScreenState extends State<EducationListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
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
      final res = await _api.get(
        '/education',
        query: {
          'page': reset ? '1' : (_page + 1).toString(),
          'per_page': '50',
          'category_id': widget.categoryId.toString(),
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (_district.text.trim().isNotEmpty)
            'district': _district.text.trim(),
          if (_upazila.text.trim().isNotEmpty) 'upazila': _upazila.text.trim(),
        },
      );
      final nextItems =
          (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
      appBar: ModernAppBar(
        title: widget.categoryName,
        subtitle: 'প্রতিষ্ঠান তালিকা',
      ),
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'প্রতিষ্ঠান সার্চ',
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showFilters ? 'লুকান' : 'ফিল্টার',
                          style: TextStyle(color: scheme.onSurface),
                        ),
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
                      key: const ValueKey('education_filters'),
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
                          decoration: const InputDecoration(
                            labelText: 'উপজেলা',
                          ),
                          onSubmitted: (_) => _load(reset: true),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _load(reset: true),
                            child: const Text('ফিল্টার প্রয়োগ'),
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
                child: const Center(child: LogoLoader(showLabel: true)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('কোনো প্রতিষ্ঠান পাওয়া যায়নি')),
              )
            else ...[
              ..._items.map((edu) => _educationCard(context, edu, scheme)),
              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 22),
                  child: OutlinedButton.icon(
                    onPressed: _loadingMore ? null : _loadMore,
                    icon: _loadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: LogoLoader(size: 16),
                          )
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

  Widget _educationCard(
    BuildContext context,
    Map<String, dynamic> edu,
    ColorScheme scheme,
  ) {
    final name = (edu['name'] ?? 'প্রতিষ্ঠান').toString();
    final category = (edu['category_name'] ?? '').toString();
    final district = (edu['district'] ?? '').toString();
    final imageUrl = (edu['image_url'] ?? '').toString();
    final id = (edu['id'] as num?)?.toInt() ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id > 0
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EducationDetailsScreen(instituteId: id),
              ),
            )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? Icon(Icons.school, color: scheme.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (district.isNotEmpty)
                    Text(
                      district,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
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
