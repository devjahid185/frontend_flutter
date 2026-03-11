import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'car_rental_booking_screen.dart';
import 'car_rental_form_screen.dart';
import 'car_rental_owner_bookings_screen.dart';

class CarRentalDetailsScreen extends StatefulWidget {
  const CarRentalDetailsScreen({super.key, required this.rentalId});

  final int rentalId;

  @override
  State<CarRentalDetailsScreen> createState() => _CarRentalDetailsScreenState();
}

class _CarRentalDetailsScreenState extends State<CarRentalDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _rental;
  List<String> _images = [];
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
      final res = await _api.get('/car-rentals/${widget.rentalId}');
      if (res is Map<String, dynamic>) _rental = res;
      await _loadImages();
      await _loadReviews();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadImages() async {
    try {
      final res = await _api.get('/media/list', query: {
        'target_type': 'car_rental',
        'target_id': widget.rentalId.toString(),
      });
      _images = (res as List?)
              ?.map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
    } catch (_) {
      _images = [];
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await _api.get('/reviews/car-rental/${widget.rentalId}');
      _reviews = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _reviews = [];
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'গাড়ি ডিটেইলস', subtitle: 'ভাড়া ও তথ্য'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _rental == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _gallery(scheme),
                        const SizedBox(height: 12),
                        _header(scheme),
                        const SizedBox(height: 12),
                        _info(scheme),
                        const SizedBox(height: 12),
                        _actions(scheme),
                        const SizedBox(height: 12),
                        _reviewsSection(scheme),
                      ],
                    ),
    );
  }

  Widget _gallery(ColorScheme scheme) {
    if (_images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Center(child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)),
      );
    }

    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(_images[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    final title = (_rental?['title'] ?? '').toString();
    final brand = (_rental?['brand'] ?? '').toString();
    final model = (_rental?['model'] ?? '').toString();
    final rating = double.tryParse((_rental?['rating'] ?? '0').toString()) ?? 0;
    final priceDay = (_rental?['price_per_day'] ?? '').toString();
    final priceHour = (_rental?['price_per_hour'] ?? '').toString();

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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (brand.isNotEmpty || model.isNotEmpty)
            Text('$brand $model'.trim(), style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (priceDay.isNotEmpty && priceDay != 'null')
                Text('৳ $priceDay/দিন', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              if (priceHour.isNotEmpty && priceHour != 'null') ...[
                const SizedBox(width: 8),
                Text('৳ $priceHour/ঘণ্টা', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) => (_rental?[key]?.toString().trim().isNotEmpty ?? false)
        ? _rental![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'ফুয়েল', 'value': getS('fuel_type')},
      {'label': 'ট্রান্সমিশন', 'value': getS('transmission')},
      {'label': 'সিট', 'value': getS('seats')},
      {'label': 'দরজা', 'value': getS('doors')},
      {'label': 'রং', 'value': getS('color')},
      {'label': 'রেজি নং', 'value': getS('reg_no')},
      {'label': 'পিকআপ', 'value': getS('pickup_location')},
      {'label': 'ড্রপ', 'value': getS('dropoff_location')},
      {'label': 'যোগাযোগ', 'value': getS('contact_phone')},
    ];

    final features = (_rental?['features'] as List?)?.cast<String>() ?? [];

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
          if (features.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ফিচার', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: features.map((e) => _chip(e, scheme)).toList()),
          ],
          if (getS('description') != '-') ...[
            const SizedBox(height: 8),
            Text('বিবরণ', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(getS('description')),
          ],
          if (getS('terms') != '-') ...[
            const SizedBox(height: 8),
            Text('শর্তাবলি', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(getS('terms')),
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
    final phone = (_rental?['contact_phone'] ?? '').toString();
    final isOwner = _rental?['is_owner'] == true;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CarRentalBookingScreen(rentalId: widget.rentalId)),
                ),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('বুকিং করুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: phone.isNotEmpty ? () => _call(phone) : null,
                icon: const Icon(Icons.call),
                label: const Text('কল করুন'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isOwner) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CarRentalFormScreen(initial: _rental)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('তথ্য আপডেট'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CarRentalOwnerBookingsScreen(rentalId: widget.rentalId)),
            ),
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('বুকিং তালিকা'),
          ),
        ] else
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
                    '/reviews/car-rental',
                    body: {
                      'target_id': widget.rentalId,
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
