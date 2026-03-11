import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'electricity_office_form_screen.dart';

class ElectricityOfficeDetailsScreen extends StatefulWidget {
  const ElectricityOfficeDetailsScreen({super.key, required this.officeId});

  final int officeId;

  @override
  State<ElectricityOfficeDetailsScreen> createState() => _ElectricityOfficeDetailsScreenState();
}

class _ElectricityOfficeDetailsScreenState extends State<ElectricityOfficeDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _office;

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
      final res = await _api.get('/electricity/offices/${widget.officeId}');
      if (res is Map<String, dynamic>) _office = res;
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

  Future<void> _openMap() async {
    final lat = _office?['lat'];
    final lng = _office?['lng'];
    final address = (_office?['address'] ?? '').toString();
    final query = (lat != null && lng != null) ? '$lat,$lng' : Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'বিদ্যুৎ অফিস', subtitle: 'অফিসের তথ্য'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _office == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _header(scheme),
                        const SizedBox(height: 12),
                        _info(scheme),
                        const SizedBox(height: 12),
                        _actions(scheme),
                      ],
                    ),
    );
  }

  Widget _header(ColorScheme scheme) {
    final name = (_office?['name'] ?? '').toString();
    final provider = (_office?['provider'] ?? '').toString();
    final officeType = (_office?['office_type'] ?? '').toString();
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
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (provider.isNotEmpty) Text(provider, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (officeType.isNotEmpty) Text(officeType, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) => (_office?[key]?.toString().trim().isNotEmpty ?? false)
        ? _office![key].toString()
        : fallback;

    final phones = (_office?['phones'] as List?)?.cast<String>() ?? [];

    final info = <Map<String, String>>[
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'হটলাইন', 'value': getS('hotline')},
      {'label': 'ইমেইল', 'value': getS('email')},
      {'label': 'ওয়েবসাইট', 'value': getS('website')},
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
          if (phones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ফোন', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: phones.map((e) => _chip(e, scheme)).toList()),
          ],
          if (getS('notes') != '-') ...[
            const SizedBox(height: 8),
            Text('নোট', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(getS('notes')),
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
    final phones = (_office?['phones'] as List?)?.cast<String>() ?? [];
    final isOwner = _office?['is_owner'] == true;
    final primaryPhone = phones.isNotEmpty ? phones.first : '';
    final website = (_office?['website'] ?? '').toString();
    final email = (_office?['email'] ?? '').toString();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: primaryPhone.isNotEmpty ? () => _call(primaryPhone) : null,
                icon: const Icon(Icons.call),
                label: const Text('কল করুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('লোকেশন'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: website.isNotEmpty ? () => _openLink(website) : null,
                icon: const Icon(Icons.public),
                label: const Text('ওয়েবসাইট'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: email.isNotEmpty ? () => _openLink('mailto:$email') : null,
                icon: const Icon(Icons.email_outlined),
                label: const Text('ইমেইল'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isOwner)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ElectricityOfficeFormScreen(initial: _office)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('তথ্য আপডেট'),
          ),
        TextButton.icon(
          onPressed: primaryPhone.isNotEmpty
              ? () async {
                  await Clipboard.setData(ClipboardData(text: primaryPhone));
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
}
