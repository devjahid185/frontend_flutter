import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'restaurant_form_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _restaurant;
  List<Map<String, dynamic>> _reviews = [];

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
      final res = await _api.get('/restaurants/${widget.restaurantId}');
      if (res is Map<String, dynamic>) _restaurant = res;
      await _loadReviews();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডাটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await _api.get('/reviews/restaurant/${widget.restaurantId}');
      _reviews = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _reviews = [];
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap() async {
    final lat = _restaurant?['lat'];
    final lng = _restaurant?['lng'];
    final address = (_restaurant?['address'] ?? '').toString();
    final query = (lat != null && lng != null) ? '$lat,$lng' : Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'রেস্টুরেন্ট বিস্তারিত', subtitle: 'সেবা ও যোগাযোগ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _restaurant == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _header(scheme),
                        const SizedBox(height: 12),
                        _info(scheme),
                        const SizedBox(height: 12),
                        _cuisines(scheme),
                        const SizedBox(height: 12),
                        _actions(scheme),
                        const SizedBox(height: 12),
                        _reviewsSection(scheme),
                      ],
                    ),
    );
  }

  Widget _header(ColorScheme scheme) {
    final name = (_restaurant?['name'] ?? '').toString();
    final type = (_restaurant?['type'] ?? '').toString();
    final category = (_restaurant?['category_name'] ?? '').toString();
    final imageUrl = (_restaurant?['image_url'] ?? '').toString();
    final rating = double.tryParse((_restaurant?['rating'] ?? '0').toString()) ?? 0;

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
            radius: 28,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.restaurant_menu, color: scheme.primary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (type.isNotEmpty) Text(type, style: TextStyle(color: scheme.onSurfaceVariant)),
                if (category.isNotEmpty) Text(category, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) => (_restaurant?[key]?.toString().trim().isNotEmpty ?? false)
        ? _restaurant![key].toString()
        : fallback;

    final priceMin = _restaurant?['min_price'];
    final priceMax = _restaurant?['max_price'];
    String priceText = '-';
    if (priceMin != null || priceMax != null) {
      priceText = '৳${priceMin ?? ''} - ৳${priceMax ?? ''}';
    }

    final info = <Map<String, String>>[
      {'label': 'ফোন', 'value': getS('phone')},
      {'label': 'ইমেইল', 'value': getS('email')},
      {'label': 'ওয়েবসাইট', 'value': getS('website')},
      {'label': 'ফেসবুক', 'value': getS('facebook')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'খোলার সময়', 'value': getS('opening_hours')},
      {'label': 'প্রাইস রেঞ্জ', 'value': priceText},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('তথ্য', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...info.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(width: 110, child: Text(e['label']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(child: Text(e['value']!)),
                  ],
                ),
              )),
          if (getS('description') != '-') ...[
            const SizedBox(height: 8),
            Text('বিবরণ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(getS('description')),
          ],
        ],
      ),
    );
  }

  Widget _cuisines(ColorScheme scheme) {
    final cuisines = (_restaurant?['cuisines'] as List?)?.cast<String>() ?? [];
    final features = (_restaurant?['features'] as List?)?.cast<String>() ?? [];

    if (cuisines.isEmpty && features.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('মেনু ও ফিচার', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (cuisines.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 8, children: cuisines.map((e) => _chip(e, scheme)).toList()),
            const SizedBox(height: 10),
          ],
          if (features.isNotEmpty) ...[
            Text('ফিচার', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: features.map((e) => _chip(e, scheme)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _actions(ColorScheme scheme) {
    final phone = (_restaurant?['phone'] ?? '').toString();
    final website = (_restaurant?['website'] ?? '').toString();
    final facebook = (_restaurant?['facebook'] ?? '').toString();
    final isOwner = _restaurant?['is_owner'] == true;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: phone.isNotEmpty ? () => _call(phone) : null,
                icon: const Icon(Icons.call),
                label: const Text('কল করুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('লোকেশন দেখুন'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: website.isNotEmpty ? () => _openUrl(website) : null,
                icon: const Icon(Icons.language_outlined),
                label: const Text('ওয়েবসাইট'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: facebook.isNotEmpty ? () => _openUrl(facebook) : null,
                icon: const Icon(Icons.facebook_outlined),
                label: const Text('ফেসবুক'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isOwner)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RestaurantFormScreen(initial: _restaurant)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('তথ্য আপডেট'),
          )
        else
          FilledButton.icon(
            onPressed: _showRatingDialog,
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('রেটিং দিন'),
          ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: phone.isNotEmpty
              ? () async {
                  await Clipboard.setData(ClipboardData(text: phone));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নম্বর কপি হয়েছে')));
                  }
                }
              : null,
          icon: const Icon(Icons.copy),
          label: const Text('নম্বর কপি'),
        ),
      ],
    );
  }

  Widget _reviewsSection(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('রিভিউ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_reviews.isEmpty)
            Text('কোনো রিভিউ নেই', style: TextStyle(color: scheme.onSurfaceVariant))
          else
            ..._reviews.map((r) => _reviewTile(r, scheme)),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r, ColorScheme scheme) {
    final name = (r['user_name'] ?? 'ব্যবহারকারী').toString();
    final ratingRaw = r['rating'];
    final rating = ratingRaw is num ? ratingRaw.toDouble() : double.tryParse(ratingRaw?.toString() ?? '') ?? 0;
    final comment = (r['comment'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(color: scheme.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1)),
                  ],
                ),
                if (comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(comment, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    int selected = 5;
    final commentController = TextEditingController();
    final scheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('রেটিং দিন'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final idx = index + 1;
                      return IconButton(
                        onPressed: () => setState(() => selected = idx),
                        icon: Icon(
                          idx <= selected ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber.shade700,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'কমেন্ট (ঐচ্ছিক)',
                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বাতিল', style: TextStyle(color: scheme.onSurface)),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _api.post(
                    '/reviews/restaurant',
                    body: {
                      'target_id': widget.restaurantId,
                      'rating': selected,
                      'comment': commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    },
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়েছে')));
                    await _load();
                    if (mounted) setState(() {});
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়নি')));
                  }
                }
              },
              child: const Text('সাবমিট'),
            ),
          ],
        );
      },
    );
  }
}
