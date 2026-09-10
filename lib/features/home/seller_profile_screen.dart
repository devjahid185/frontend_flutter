import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
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
      backgroundColor: const Color(0xfff4f7f6),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const _SellerHeader(title: 'বিক্রেতা প্রোফাইল'),
                const SizedBox(height: 16),
                _buildHeader(context, scheme),
                const SizedBox(height: 12),
                const Text(
                  'বিক্রেতার আইটেম',
                  style: TextStyle(
                    color: Color(0xff006a4e),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Text(
                    'কোনো আইটেম পাওয়া যায়নি',
                    style: const TextStyle(color: Color(0xff4b5563)),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffe6f1ee),
            child: Text(
              name.characters.first,
              style: const TextStyle(color: Color(0xff006a4e)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xff1f2937),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [district, upazila].where((e) => e.isNotEmpty).join(', '),
                  style: const TextStyle(
                    color: Color(0xff4b5563),
                    fontSize: 12,
                  ),
                ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
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
              icon: const Icon(Icons.call_outlined, color: Color(0xff006a4e)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xff1f2937),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '$category • ৳ $price',
          style: const TextStyle(color: Color(0xff4b5563), fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xff9ca3af),
        ),
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

class _SellerHeader extends StatelessWidget {
  const _SellerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff1f2937),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
