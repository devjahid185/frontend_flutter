import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/state/notification_manager.dart';
import '../../core/storage/session_storage.dart';
import '../auth/auth_manager.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading || _loadingMore) return;
    setState(() {
      _error = null;
      if (refresh) {
        _loading = true;
      }
    });

    try {
      if (refresh) {
        _items.clear();
        _page = 1;
        _hasMore = true;
      }

      final res = await _api.get('/notifications', query: {
        'page': _page.toString(),
        'per_page': '20',
      });

      if (res is Map<String, dynamic>) {
        final data = res['data'];
        if (data is List) {
          _items.addAll(data.cast<Map<String, dynamic>>());
        }
        final currentPage = res['current_page'] as int? ?? _page;
        final lastPage = res['last_page'] as int? ?? currentPage;
        _hasMore = currentPage < lastPage;
        _page = currentPage + 1;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'নোটিফিকেশন লোড করা যাচ্ছে না।';
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadingMore = true;
      _load();
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _api.post('/notifications/$id/read');
      final index = _items.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        final updated = Map<String, dynamic>.from(_items[index]);
        updated['read_at'] = updated['read_at'] ?? DateTime.now().toIso8601String();
        setState(() {
          _items[index] = updated;
        });
      }
      if (mounted) {
        context.read<NotificationManager>().decrement();
      }
    } catch (_) {}
  }

  void _openDetails(Map<String, dynamic> item) {
    final id = item['id'] as int?;
    if (id != null) {
      _markRead(id);
    }

    final imageUrl = (item['image_url'] ?? item['data']?['image_url']) as String?;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Text('ইমেজ লোড হয়নি'),
                        ),
                      ),
                    ),
                  if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 12),
                  Text(
                    item['title']?.toString().isNotEmpty == true
                        ? item['title'].toString()
                        : 'নোটিফিকেশন',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['message']?.toString().isNotEmpty == true
                        ? item['message'].toString()
                        : 'বিস্তারিত নেই',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['created_at']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthManager>();
    final notifier = context.watch<NotificationManager>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('নোটিফিকেশন'),
          centerTitle: true,
        ),
        body: const Center(child: Text('দয়া করে লগইন করুন।')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটিফিকেশন'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : () async {
              await notifier.markAllRead();
              setState(() {
                for (var i = 0; i < _items.length; i++) {
                  final updated = Map<String, dynamic>.from(_items[i]);
                  updated['read_at'] = updated['read_at'] ?? DateTime.now().toIso8601String();
                  _items[i] = updated;
                }
              });
            },
            child: const Text('সব পড়া'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _items[index];
                  final title = item['title']?.toString();
                  final message = item['message']?.toString();
                  final imageUrl = (item['image_url'] ?? item['data']?['image_url']) as String?;
                  final readAt = item['read_at'];

                  return InkWell(
                    onTap: () => _openDetails(item),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                        color: readAt == null ? scheme.primaryContainer : scheme.surface,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported, size: 20),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: scheme.surfaceContainerHighest,
                              ),
                              child: Icon(Icons.notifications, color: scheme.primary),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title?.isNotEmpty == true ? title! : 'নোটিফিকেশন',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: readAt == null ? scheme.onPrimaryContainer : scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message?.isNotEmpty == true ? message! : 'বিস্তারিত নেই',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: readAt == null
                                        ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['created_at']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: readAt == null
                                        ? scheme.onPrimaryContainer.withValues(alpha: 0.7)
                                        : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _error != null
          ? FloatingActionButton.extended(
              onPressed: () => _load(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('রিফ্রেশ'),
            )
          : null,
    );
  }
}
