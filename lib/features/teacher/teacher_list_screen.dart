import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'teacher_details_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _medium = TextEditingController();
  final TextEditingController _mode = TextEditingController();
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
    _medium.dispose();
    _mode.dispose();
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
        '/teachers',
        query: {
          'page': reset ? '1' : (_page + 1).toString(),
          'per_page': '50',
          'category_id': widget.categoryId.toString(),
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (_district.text.trim().isNotEmpty)
            'district': _district.text.trim(),
          if (_medium.text.trim().isNotEmpty) 'medium': _medium.text.trim(),
          if (_mode.text.trim().isNotEmpty) 'mode': _mode.text.trim(),
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
      appBar: ModernAppBar(
        title: widget.categoryName,
        subtitle: 'টিউটর তালিকা',
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'টিউটর সার্চ',
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _district,
                    decoration: const InputDecoration(labelText: 'জেলা'),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _medium,
                    decoration: const InputDecoration(labelText: 'মাধ্যম'),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mode,
              decoration: const InputDecoration(
                labelText: 'মোড (অনলাইন/অফলাইন/দুইটাই)',
              ),
              onSubmitted: (_) => _load(reset: true),
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
                child: Center(child: Text('কোনো টিউটর পাওয়া যায়নি')),
              )
            else ...[
              ..._items.map((teacher) => _teacherCard(context, teacher)),
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

  Widget _teacherCard(BuildContext context, Map<String, dynamic> t) {
    final scheme = Theme.of(context).colorScheme;
    final name = (t['name'] ?? 'টিউটর').toString();
    final title = (t['title'] ?? '').toString();
    final medium = (t['medium'] ?? '').toString();
    final rating = double.tryParse((t['rating'] ?? '0').toString()) ?? 0;
    final imageUrl = (t['image_url'] ?? '').toString();
    final id = (t['id'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: id > 0
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TeacherDetailsScreen(teacherId: id),
              ),
            )
          : null,
      borderRadius: BorderRadius.circular(18),
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
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  if (medium.isNotEmpty)
                    Text(
                      medium,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
