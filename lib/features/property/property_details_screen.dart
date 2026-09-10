import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _property;

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
      final res = await _api.get('/properties/${widget.propertyId}');
      if (res is Map<String, dynamic>) _property = res;
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
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'প্রোপার্টি ডিটেইলস',
        subtitle: 'বিস্তারিত তথ্য',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : _property == null
          ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, scheme),
                const SizedBox(height: 12),
                _info(context, scheme),
                const SizedBox(height: 12),
                _description(context, scheme),
                const SizedBox(height: 12),
                _actions(context, scheme),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme) {
    final title = (_property?['title'] ?? 'প্রোপার্টি').toString();
    final price = (_property?['price'] ?? '').toString();
    final purpose = (_property?['purpose'] ?? 'rent').toString();
    final status = (_property?['status'] ?? 'open').toString();

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
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                price.isEmpty ? '-' : '৳ $price',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  purpose == 'sell' ? 'বিক্রয়' : 'ভাড়া',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'open'
                      ? scheme.primary
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'open' ? 'Open' : 'Closed',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) =>
        (_property?[key]?.toString().trim().isNotEmpty ?? false)
        ? _property![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'ক্যাটাগরি', 'value': getS('category_name')},
      {'label': 'টাইপ', 'value': getS('type')},
      {'label': 'প্রোপার্টি টাইপ', 'value': getS('property_type')},
      {'label': 'বেডরুম', 'value': getS('bedrooms')},
      {'label': 'বাথরুম', 'value': getS('bathrooms')},
      {'label': 'এরিয়া', 'value': '${getS('area')} ${getS('area_unit')}'},
      {'label': 'ফ্লোর', 'value': getS('floor')},
      {'label': 'মোট ফ্লোর', 'value': getS('total_floors')},
      {'label': 'ফার্নিশড', 'value': getS('furnished')},
      {'label': 'পার্কিং', 'value': getS('parking')},
      {'label': 'ফেসিং', 'value': getS('facing')},
      {'label': 'বছর', 'value': getS('year_built')},
      {'label': 'দাম/স্কয়ারফিট', 'value': getS('price_per_sqft')},
      {'label': 'আলোচনা সাপেক্ষ', 'value': getS('negotiable')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'লোকেশন টাইপ', 'value': getS('location_type')},
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
            'বেসিক তথ্য',
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
                    width: 130,
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
          if (_property?['amenities'] is List) ...[
            const SizedBox(height: 8),
            Text(
              'সুবিধা',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_property?['amenities'] as List)
                  .map((e) => _chip(context, e.toString()))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _description(BuildContext context, ColorScheme scheme) {
    final description = (_property?['description'] ?? '').toString();
    if (description.isEmpty) return const SizedBox.shrink();

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
            'বিবরণ',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final phone = (_property?['contact_phone'] ?? _property?['contact'] ?? '')
        .toString();
    final email = (_property?['contact_email'] ?? '').toString();
    final website = (_property?['contact_website'] ?? '').toString();
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
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('mailto:$email');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text('ইমেইল'),
          ),
        ],
        if (website.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                website.startsWith('http') ? website : 'https://$website',
              );
              if (await canLaunchUrl(uri))
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.language_outlined),
            label: const Text('ওয়েবসাইট'),
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
