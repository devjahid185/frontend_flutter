import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'marketplace_item_details_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key, required this.sellerId});

  final int sellerId;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _seller;
  List<dynamic> _items = [];

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
      final res = await _api.get('/items/seller/${widget.sellerId}');
      if (res is Map<String, dynamic>) {
        _seller = res['seller'] as Map<String, dynamic>?;
        final items = res['items'];
        if (items is Map<String, dynamic> && items['data'] is List) {
          _items = items['data'] as List<dynamic>;
        } else if (items is List) {
          _items = items;
        }
      }
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
      appBar: const ModernAppBar(
        title: 'বিক্রেতা প্রোফাইল',
        subtitle: 'প্রোফাইল ও আইটেম',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, scheme),
                const SizedBox(height: 12),
                Text(
                  'বিক্রেতার আইটেম',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Text(
                    'কোনো আইটেম পাওয়া যায়নি',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                else
                  ..._items.map(
                    (item) => _itemCard(
                      context,
                      scheme,
                      item as Map<String, dynamic>,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    final name = _seller?['name']?.toString() ?? 'বিক্রেতা';
    final phone = _seller?['phone']?.toString() ?? '';
    final district = _seller?['district']?.toString() ?? '';
    final upazila = _seller?['upazila']?.toString() ?? '';
    final address = _seller?['address']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(
              name.characters.first,
              style: TextStyle(color: scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  [district, upazila].where((e) => e.isNotEmpty).join(', '),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () async {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: Icon(Icons.call_outlined, color: scheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    ColorScheme scheme,
    Map<String, dynamic> item,
  ) {
    final title = item['title']?.toString() ?? 'আইটেম';
    final price = item['price']?.toString() ?? '0';
    final category = item['category_name']?.toString() ?? '-';
    final id = (item['id'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$category • ৳ $price',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: id > 0
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MarketplaceItemDetailsScreen(itemId: id),
                ),
              )
            : null,
      ),
    );
  }
}
