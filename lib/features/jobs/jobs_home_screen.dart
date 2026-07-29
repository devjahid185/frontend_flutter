import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'job_details_screen.dart';
import 'job_post_form_screen.dart';
import 'my_job_applications_screen.dart';
import 'my_job_posts_screen.dart';

class JobsHomeScreen extends StatefulWidget {
  const JobsHomeScreen({super.key});

  @override
  State<JobsHomeScreen> createState() => _JobsHomeScreenState();
}

class _JobsHomeScreenState extends State<JobsHomeScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _location = TextEditingController();
  final TextEditingController _search = TextEditingController();

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
    _location.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/jobs/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _categories = [];
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _openPostSheet() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 42, height: 4, decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('চাকরি পোস্ট করুন'),
                  subtitle: const Text('কর্মী নিয়োগের জন্য'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobPostFormScreen(postType: 'hiring')),
                    );
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.person_search_outlined),
                  title: const Text('চাকরি প্রার্থী পোস্ট করুন'),
                  subtitle: const Text('নিজের প্রোফাইল/স্কিল'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobPostFormScreen(postType: 'seeking')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ModernAppBar(title: 'চাকরি', subtitle: 'পোস্ট ও আবেদন'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openPostSheet,
          icon: const Icon(Icons.add),
          label: const Text('পোস্ট করুন'),
        ),
        body: Column(
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
                            MaterialPageRoute(builder: (_) => const MyJobPostsScreen()),
                          ),
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('আমার পোস্ট'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyJobApplicationsScreen()),
                          ),
                          icon: const Icon(Icons.fact_check_outlined, size: 18),
                          label: const Text('আমার আবেদন'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'জব সার্চ'),
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
                            key: const ValueKey('job_filters'),
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _location,
                                      decoration: const InputDecoration(labelText: 'কর্মস্থল/ঠিকানা'),
                                      onSubmitted: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _categoryId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'ক্যাটাগরি',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      items: _loadingCategories
                                          ? const []
                                          : _categories
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c['id'].toString(),
                                                  child: Text(
                                                    c['name'].toString(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      selectedItemBuilder: (context) {
                                        return _categories
                                            .map(
                                              (c) => Text(
                                                c['name'].toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                            .toList();
                                      },
                                      onChanged: (value) => setState(() => _categoryId = value),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => setState(() {}),
                                  icon: const Icon(Icons.filter_list),
                                  label: const Text('ফিল্টার'),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
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
                  Tab(text: 'চাকরি'),
                  Tab(text: 'চাকরি প্রার্থী'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  JobListTab(
                    postType: 'hiring',
                    search: _search.text.trim(),
                    location: _location.text.trim(),
                    categoryId: _categoryId,
                  ),
                  JobListTab(
                    postType: 'seeking',
                    search: _search.text.trim(),
                    location: _location.text.trim(),
                    categoryId: _categoryId,
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

class JobListTab extends StatefulWidget {
  const JobListTab({
    super.key,
    required this.postType,
    required this.search,
    required this.location,
    required this.categoryId,
  });

  final String postType;
  final String search;
  final String location;
  final String? categoryId;

  @override
  State<JobListTab> createState() => _JobListTabState();
}

class _JobListTabState extends State<JobListTab> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _hasMore => _page < _lastPage;

  @override
  void didUpdateWidget(covariant JobListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search || oldWidget.location != widget.location || oldWidget.categoryId != widget.categoryId) {
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
      final res = await _api.get('/jobs', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
        'post_type': widget.postType,
        if (widget.search.isNotEmpty) 'q': widget.search,
        if (widget.location.isNotEmpty) 'location': widget.location,
        if (widget.categoryId != null && widget.categoryId!.isNotEmpty) 'category_id': widget.categoryId!,
      });
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? list : [..._items, ...list];
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
              child: Center(child: Text('কোনো জব নেই')),
            )
          else
            ...[
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 220 + (index * 25)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
                  ),
                  child: _jobCard(context, item),
                );
              }),
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

  Widget _jobCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? 'চাকরি').toString();
    final company = (item['company'] ?? '').toString();
    final location = (item['location'] ?? '').toString();
    final salary = (item['salary'] ?? '').toString();
    final categoryName = (item['category_name'] ?? '').toString();
    final id = (item['id'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: id > 0 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobDetailsScreen(jobId: id))) : null,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.work_outline, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(company.isEmpty ? 'কোম্পানি নেই' : company, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (categoryName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(categoryName, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Text(salary.isEmpty ? '-' : salary, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
