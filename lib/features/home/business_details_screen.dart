import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key, required this.businessId});

  final int businessId;

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _business;
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
      final res = await _api.get('/businesses/${widget.businessId}');
      final reviews = await _api.get('/reviews/business/${widget.businessId}');
      if (res is Map<String, dynamic>) {
        _business = res;
      }
      if (reviews is List) {
        _reviews = reviews;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডাটা লোড করা যায়নি';
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
          title: Text('ফোন নম্বর', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
          content: Container(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বন্ধ করুন', style: TextStyle(color: scheme.onSurface)),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কপি করা হয়েছে')));
                }
              },
              child: const Text('কপি করুন'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMapByAddress(String address) async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ম্যাপ খোলা যায়নি')));
    }
  }

  Future<void> _openMap(double lat, double lng) async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ম্যাপ খোলা যায়নি')));
    }
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
                      labelText: 'মন্তব্য (ঐচ্ছিক)',
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
                    '/reviews/business',
                    body: {
                      'target_id': widget.businessId,
                      'rating': selected,
                      'comment': commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    },
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়েছে')));
                    _load();
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা ব্যর্থ')));
                  }
                }
              },
              child: const Text('জমা দিন'),
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
      appBar: const ModernAppBar(title: 'ব্যবসা বিস্তারিত', subtitle: 'ঠিকানা ও যোগাযোগ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _business == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(context, scheme),
                        const SizedBox(height: 12),
                        _buildInfo(context, scheme),
                        const SizedBox(height: 12),
                        _buildReviews(context, scheme),
                      ],
                    ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    final name = _business?['name']?.toString().trim().isEmpty ?? true
        ? 'ব্যবসা'
        : _business?['name']?.toString() ?? 'ব্যবসা';
    final logo = _normalizeImageUrl(_business?['logo_url']?.toString() ?? _business?['logo']?.toString());
    final category = _business?['category_name']?.toString() ?? '-';
    final ratingRaw = _business?['rating']?.toString() ?? '0';
    final rating = double.tryParse(ratingRaw) ?? 0;

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
            child: logo == null
                ? Container(
                    width: 72,
                    height: 72,
                    color: scheme.primary.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Text(name.characters.first, style: TextStyle(color: scheme.primary, fontSize: 22)),
                  )
                : Image.network(logo, width: 72, height: 72, fit: BoxFit.cover),
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
    final address = _business?['address']?.toString() ?? '-';
    final phone = _business?['phone']?.toString() ?? '';
    final hours = _business?['opening_hours']?.toString() ?? '-';
    final website = _business?['website']?.toString() ?? '';
    final facebook = _business?['facebook_page']?.toString() ?? '';
    final desc = _business?['description']?.toString() ?? '-';
    final isOwner = _business?['is_owner'] == true;
    final lat = _business?['latitude'];
    final lng = _business?['longitude'];
    final latNum = lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
    final lngNum = lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');

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
          _infoRow('ঠিকানা', address),
          if (address.trim().isNotEmpty && address != '-')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: (latNum != null && lngNum != null)
                    ? () => _openMap(latNum, lngNum)
                    : () => _openMapByAddress(address),
                child: const Text('ম্যাপ খুলুন'),
              ),
            ),
          _infoRow('খোলা সময়', hours),
          _infoRow('ফোন', phone.isEmpty ? '-' : phone),
          _infoRow('ওয়েবসাইট', website.isEmpty ? '-' : website),
          _infoRow('ফেসবুক পেজ', facebook.isEmpty ? '-' : facebook),
          if (phone.isNotEmpty || website.isNotEmpty || facebook.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: phone.isEmpty ? null : () => _showPhoneDialog(phone),
                    child: const Text('ফোন দেখুন'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: website.isEmpty ? null : () => _openWebsite(website),
                    child: const Text('ওয়েবসাইট'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: facebook.isEmpty ? null : () => _openWebsite(facebook),
                    child: const Text('ফেসবুক'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (!isOwner)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star_rate_rounded),
                label: const Text('রেটিং দিন'),
              ),
            )
          else
            Text('নিজের ব্যবসায় রেটিং দেওয়া যাবে না', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text('বিবরণ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(desc),
        ],
      ),
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
        child: Text('এখনো রিভিউ নেই', style: TextStyle(color: scheme.onSurfaceVariant)),
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
            final user = r['user_name']?.toString() ?? 'ব্যবহারকারী';
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
