import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class MyCarRentalBookingsScreen extends StatefulWidget {
  const MyCarRentalBookingsScreen({super.key});

  @override
  State<MyCarRentalBookingsScreen> createState() => _MyCarRentalBookingsScreenState();
}

class _MyCarRentalBookingsScreenState extends State<MyCarRentalBookingsScreen> {
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
      final res = await _api.get('/car-rental-bookings/my', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
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
      appBar: const ModernAppBar(title: 'আমার বুকিং', subtitle: 'গাড়ি ভাড়া তালিকা'),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                child: Center(child: Text('কোনো বুকিং নেই')),
              )
            else
              ...[
                ..._items.map((item) => _card(item, scheme)),
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

  Widget _card(Map<String, dynamic> item, ColorScheme scheme) {
    final start = (item['start_date'] ?? '').toString();
    final end = (item['end_date'] ?? '').toString();
    final pickup = (item['pickup_location'] ?? '').toString();
    final status = (item['status'] ?? 'pending').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('তারিখ: $start${end.isNotEmpty ? ' - $end' : ''}'),
          if (pickup.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('পিকআপ: $pickup')),
          const SizedBox(height: 6),
          Text('স্ট্যাটাস: ${_statusLabel(status)}'),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'নিশ্চিত';
      case 'cancelled':
        return 'বাতিল';
      case 'completed':
        return 'সম্পন্ন';
      default:
        return 'অপেক্ষমান';
    }
  }
}
