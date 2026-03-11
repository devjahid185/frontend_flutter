import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'property_details_screen.dart';
import 'property_post_form_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/properties/my-posts');
      _items = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeProperty(int id) async {
    try {
      await _api.post('/properties/$id/close');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোপার্টি বন্ধ করা হয়েছে')));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বন্ধ করা যায়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'আমার প্রোপার্টি', subtitle: 'পোস্ট করা তালিকা'),
      body: RefreshIndicator(
        onRefresh: _load,
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
                child: Center(child: Text('কোনো পোস্ট নেই')),
              )
            else
              ..._items.map((item) => _propertyCard(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _propertyCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? 'প্রোপার্টি').toString();
    final price = (item['price'] ?? '').toString();
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
          Text(price.isEmpty ? '-' : '৳ $price', style: TextStyle(color: scheme.primary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'open' ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status == 'open' ? 'Open' : 'Closed', style: TextStyle(color: scheme.onPrimary, fontSize: 11)),
              ),
              const Spacer(),
              TextButton(
                onPressed: id > 0 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailsScreen(propertyId: id))) : null,
                child: const Text('দেখুন'),
              ),
              if (id > 0)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyPostFormScreen(initial: item)),
                  ),
                  child: const Text('এডিট'),
                ),
              if (status == 'open' && id > 0)
                TextButton(
                  onPressed: () => _closeProperty(id),
                  child: const Text('বন্ধ করুন'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
