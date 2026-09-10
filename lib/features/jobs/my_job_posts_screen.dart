import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'job_details_screen.dart';

class MyJobPostsScreen extends StatefulWidget {
  const MyJobPostsScreen({super.key});

  @override
  State<MyJobPostsScreen> createState() => _MyJobPostsScreenState();
}

class _MyJobPostsScreenState extends State<MyJobPostsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
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
        '/jobs/my-posts',
        query: {'page': reset ? '1' : (_page + 1).toString(), 'per_page': '50'},
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

  Future<void> _closeJob(int id) async {
    try {
      await _api.post('/jobs/$id/close');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('জব বন্ধ করা হয়েছে')));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('বন্ধ করা যায়নি')));
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
      appBar: const ModernAppBar(
        title: 'আমার পোস্ট',
        subtitle: 'পোস্ট করা চাকরি',
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: const Center(child: LogoLoader(showLabel: true)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('কোনো পোস্ট নেই')),
              )
            else ...[
              ..._items.map((item) => _jobCard(context, item)),
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

  Widget _jobCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? 'চাকরি').toString();
    final company = (item['company'] ?? '').toString();
    final status = (item['status'] ?? 'open').toString();
    final id = (item['id'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            company.isEmpty ? 'কোম্পানি নেই' : company,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'open'
                      ? scheme.primary
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'open' ? 'Open' : 'Closed',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: id > 0
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(jobId: id),
                        ),
                      )
                    : null,
                child: const Text('দেখুন'),
              ),
              if (status == 'open' && id > 0)
                TextButton(
                  onPressed: () => _closeJob(id),
                  child: const Text('বন্ধ করুন'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
