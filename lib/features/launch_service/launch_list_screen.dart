import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'launch_details_screen.dart';
import 'launch_form_screen.dart';

class LaunchListScreen extends StatefulWidget {
  const LaunchListScreen({super.key});

  @override
  State<LaunchListScreen> createState() => _LaunchListScreenState();
}

class _LaunchListScreenState extends State<LaunchListScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  bool _loading = true;
  bool _showFilters = false;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
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
    _from.dispose();
    _to.dispose();
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
        '/launches',
        query: {
          'page': reset ? '1' : (_page + 1).toString(),
          'per_page': '50',
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (_from.text.trim().isNotEmpty) 'route_from': _from.text.trim(),
          if (_to.text.trim().isNotEmpty) 'route_to': _to.text.trim(),
        },
      );
      final data = res is Map<String, dynamic> ? res['data'] : res;
      final nextItems = (data as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? nextItems : [..._items, ...nextItems];
      if (res is Map<String, dynamic>) {
        _page = (res['current_page'] as num?)?.toInt() ?? _page;
        _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
        _total = (res['total'] as num?)?.toInt() ?? _items.length;
      } else {
        _page = 1;
        _lastPage = 1;
        _total = _items.length;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'লঞ্চের তথ্য লোড করা যায়নি';
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

  Future<void> _call(String? phone) async {
    final value = phone?.trim();
    if (value == null || value.isEmpty) return;
    await launchUrl(
      Uri.parse('tel:$value'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'লঞ্চ সার্ভিস',
        subtitle: 'সময়, রুট, ভাড়া ও হটলাইন',
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
                      labelText: 'লঞ্চ/রুট সার্চ',
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: Icon(_showFilters ? Icons.tune : Icons.tune_outlined),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _field(_from, 'কোথা থেকে')),
                              const SizedBox(width: 10),
                              Expanded(child: _field(_to, 'কোথায় যাবে')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _load(reset: true),
                              icon: const Icon(Icons.search),
                              label: const Text('ফিল্টার করুন'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const LaunchFormScreen(),
                          ),
                        )
                        .then((_) => _load(reset: true)),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('লঞ্চ যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _search.clear();
                      _from.clear();
                      _to.clear();
                      _load(reset: true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('রিসেট'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                child: Center(child: Text('কোনো লঞ্চ তথ্য পাওয়া যায়নি')),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _total > 0
                      ? '$_totalটির মধ্যে ${_items.length}টি দেখানো হচ্ছে'
                      : '${_items.length}টি লঞ্চ তথ্য',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ..._items.map((item) => _launchCard(context, item)),
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

  Widget _launchCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final id = (item['id'] as num?)?.toInt() ?? 0;
    final name = _s(item, 'name', 'লঞ্চ');
    final route =
        '${_s(item, 'route_from', 'রুট নেই')} → ${_s(item, 'route_to', 'রুট নেই')}';
    final time = _s(item, 'departure_time', 'সময় দেওয়া নেই');
    final hotline = _s(item, 'hotline', '');
    final fare = _s(item, 'deck_fare', '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: id > 0
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LaunchDetailsScreen(launchId: id),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.directions_boat_filled_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hotline.isNotEmpty)
                    IconButton(
                      onPressed: () => _call(hotline),
                      icon: Icon(Icons.call_outlined, color: scheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(context, 'ছাড়বে $time', Icons.schedule),
                  if (fare.isNotEmpty && fare != 'null')
                    _chip(context, 'ডেক ৳$fare', Icons.payments_outlined),
                  if (item['has_cabin'] == true || item['has_cabin'] == 1)
                    _chip(context, 'কেবিন আছে', Icons.bed_outlined),
                  if (item['online_booking'] == true ||
                      item['online_booking'] == 1)
                    _chip(
                      context,
                      'অনলাইন বুকিং',
                      Icons.confirmation_number_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _chip(BuildContext context, String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _s(Map<String, dynamic> data, String key, [String fallback = '-']) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty || value == 'null' ? fallback : value;
  }
}
