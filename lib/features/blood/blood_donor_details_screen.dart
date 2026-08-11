import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BloodDonorDetailsScreen extends StatefulWidget {
  const BloodDonorDetailsScreen({super.key, required this.donorId});

  final int donorId;

  @override
  State<BloodDonorDetailsScreen> createState() =>
      _BloodDonorDetailsScreenState();
}

class _BloodDonorDetailsScreenState extends State<BloodDonorDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _donor;

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
      final res = await _api.get('/blood-donors/${widget.donorId}');
      if (res is Map<String, dynamic>) _donor = res;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'ডোনার ডিটেইলস',
        subtitle: 'রক্তদাতা তথ্য',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : _donor == null
          ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, scheme),
                const SizedBox(height: 12),
                _infoCard(context, scheme),
                const SizedBox(height: 12),
                _actions(context, scheme),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme) {
    final name = (_donor?['name'] ?? 'ডোনার').toString();
    final group = (_donor?['blood_group'] ?? '-').toString();
    final available = _donor?['available'] == true || _donor?['available'] == 1;
    final imageUrl = (_donor?['image_url'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: scheme.primary,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl.isEmpty
                ? Text(
                    group,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  available ? 'রক্ত দিতে পারবেন' : 'অপ্রাপ্য',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: available ? scheme.primary : scheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              available ? 'Available' : 'Unavailable',
              style: TextStyle(color: scheme.onPrimary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) =>
        (_donor?[key]?.toString().trim().isNotEmpty ?? false)
        ? _donor![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'লোকে​শন', 'value': getS('location')},
      {'label': 'লিঙ্গ', 'value': getS('gender')},
      {'label': 'বয়স', 'value': getS('age')},
      {'label': 'ওজন', 'value': getS('weight')},
      {'label': 'শেষ ডোনেশন', 'value': getS('last_donation')},
      {'label': 'ডোনেশন সংখ্যা', 'value': getS('donation_count')},
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
          Text(
            'বিস্তারিত তথ্য',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...info.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      e['label']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Text(e['value']!)),
                ],
              ),
            ),
          ),
          if (getS('note') != '-') ...[
            const SizedBox(height: 6),
            Text(
              'নোট',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(getS('note')),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final phone = (_donor?['phone'] ?? '').toString();
    return Row(
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
            onPressed: phone.isNotEmpty
                ? () async {
                    await Clipboard.setData(ClipboardData(text: phone));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('কপি করা হয়েছে')),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.copy),
            label: const Text('নম্বর কপি'),
          ),
        ),
      ],
    );
  }
}
