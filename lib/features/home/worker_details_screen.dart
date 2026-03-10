import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class WorkerDetailsScreen extends StatefulWidget {
  const WorkerDetailsScreen({super.key, required this.workerId});

  final int workerId;

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _worker;
  List<dynamic> _reviews = [];

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
      final worker = await _api.get('/workers/${widget.workerId}');
      final reviews = await _api.get('/reviews/worker/${widget.workerId}');

      if (worker is Map<String, dynamic>) {
        _worker = worker;
      }
      if (reviews is List) {
        _reviews = reviews;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _normalizeImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value == '-') return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        final uri = Uri.parse(value);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final apiUri = Uri.parse(AppConfig.apiBaseUrl);
          final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
          return '$origin${uri.path}';
        }
      } catch (_) {}
      return value;
    }

    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    if (value.startsWith('/')) return '$origin$value';

    return '$origin/storage/$value';
  }

  Future<void> _showPhoneDialog(String phone) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text('কর্মীর ফোন নম্বর', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বন্ধ করুন', style: TextStyle(color: scheme.onSurface)),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নম্বর কপি হয়েছে')));
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('কপি করুন'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRatingDialog() async {
    int selected = 5;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text('রেটিং দিন', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
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
                    '/reviews/worker',
                    body: {
                      'target_id': widget.workerId,
                      'rating': selected,
                      'comment': commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    },
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়েছে')));
                    _load();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'কর্মী ডিটেইলস', subtitle: 'প্রোফাইল ও রিভিউ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _worker == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(context, scheme),
                        const SizedBox(height: 12),
                        _buildInfo(context, scheme),
                        const SizedBox(height: 12),
                        _buildActions(context),
                        const SizedBox(height: 12),
                        _buildReviews(context, scheme),
                      ],
                    ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    final rawName = _worker?['worker_name']?.toString() ?? '';
    final name = rawName.trim().isEmpty ? 'কর্মী' : rawName.trim();
    final photo = _normalizeImageUrl(_worker?['worker_photo_url']?.toString() ?? _worker?['photo']?.toString());
    final category = _worker?['category_name']?.toString() ?? '-';
    final rating = double.tryParse((_worker?['user_rating'] ?? _worker?['rating'] ?? '0').toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: photo == null
                ? Container(
                    width: 72,
                    height: 72,
                    color: scheme.primary.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Text(name.characters.first, style: TextStyle(color: scheme.primary, fontSize: 22)),
                  )
                : Image.network(photo, width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(category, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context, ColorScheme scheme) {
    final experience = _worker?['experience']?.toString() ?? '-';
    final price = _worker?['hourly_price']?.toString() ?? '-';
    final area = _worker?['service_area']?.toString() ?? '-';
    final address = _worker?['address']?.toString() ?? '-';
    final skills = _worker?['skills']?.toString() ?? '-';
    final desc = _worker?['description']?.toString() ?? '-';

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
          _infoRow('অভিজ্ঞতা', '$experience বছর'),
          _infoRow('ঘন্টা প্রতি মূল্য', '৳ $price'),
          _infoRow('সার্ভিস এরিয়া', area),
          _addressRow(context, scheme, address),
          _infoRow('স্কিলস', skills),
          const SizedBox(height: 8),
          Text('বিবরণ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(desc),
        ],
      ),
    );
  }

  Widget _addressRow(BuildContext context, ColorScheme scheme, String address) {
    final coords = _parseLatLng(address);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 110, child: Text('ঠিকানা', style: TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address),
                if (coords != null || address.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: coords != null
                          ? () => _openMap(context, coords.$1, coords.$2)
                          : () => _openMapByAddress(context, address),
                      child: const Text('লোকেশন দেখুন'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (double, double)? _parseLatLng(String raw) {
    final cleaned = raw.replaceAll(' ', '');
    final parts = cleaned.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat, lng);
  }

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('লোকেশন খোলা যায়নি')));
    }
  }

  Future<void> _openMapByAddress(BuildContext context, String address) async {
    final query = Uri.encodeComponent(address);
    final geoUri = Uri.parse('geo:0,0?q=$query');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('লোকেশন খোলা যায়নি')));
    }
  }

  Widget _buildActions(BuildContext context) {
    final phone = _worker?['phone']?.toString() ?? '';
    final isOwner = _worker?['is_owner'] == true;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: phone.isNotEmpty ? () => _showPhoneDialog(phone) : null,
                icon: const Icon(Icons.call),
                label: const Text('কল করুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOwner ? null : _showRatingDialog,
                icon: const Icon(Icons.star_rate_rounded),
                label: const Text('রেটিং দিন'),
              ),
            ),
          ],
        ),
        if (isOwner) ...[
          const SizedBox(height: 8),
          Text('নিজের কর্মী প্রোফাইলে রেটিং দেওয়া যাবে না', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }

  Widget _buildReviews(BuildContext context, ColorScheme scheme) {
    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Text('এখনো কোনো রিভিউ নেই', style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }

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
          const Text('রিভিউ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ..._reviews.map((r) {
            final user = r['user_name']?.toString() ?? 'ইউজার';
            final ratingRaw = r['rating'];
            final rating = ratingRaw is num ? ratingRaw.toDouble() : double.tryParse(ratingRaw?.toString() ?? '') ?? 0;
            final comment = r['comment']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(comment, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
