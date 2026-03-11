import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BloodRequestDetailsScreen extends StatefulWidget {
  const BloodRequestDetailsScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<BloodRequestDetailsScreen> createState() => _BloodRequestDetailsScreenState();
}

class _BloodRequestDetailsScreenState extends State<BloodRequestDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _request;

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
      final res = await _api.get('/blood-requests/${widget.requestId}');
      if (res is Map<String, dynamic>) _request = res;
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

  Future<void> _closeRequest() async {
    try {
      await _api.post('/blood-requests/${widget.requestId}/close');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অনুরোধ বন্ধ করা হয়েছে')));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অনুরোধ বন্ধ হয়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'অনুরোধ ডিটেইলস', subtitle: 'রক্তের প্রয়োজন'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _request == null
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
    final group = (_request?['blood_group'] ?? '-').toString();
    final status = (_request?['status'] ?? 'open').toString();
    final hospital = (_request?['hospital'] ?? 'হাসপাতাল নেই').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(group, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hospital, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(status == 'open' ? 'খোলা আছে' : 'বন্ধ', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'open' ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status == 'open' ? 'Open' : 'Closed', style: TextStyle(color: scheme.onPrimary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) => (_request?[key]?.toString().trim().isNotEmpty ?? false)
        ? _request![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'রোগীর নাম', 'value': getS('patient_name')},
      {'label': 'ইউনিট', 'value': getS('units')},
      {'label': 'প্রয়োজনের তারিখ', 'value': getS('needed_at')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'লোকেশন', 'value': getS('location')},
      {'label': 'যোগাযোগ', 'value': getS('contact_phone')},
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
          Text('বিস্তারিত তথ্য', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
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
          if (getS('note') != '-') ...[
            const SizedBox(height: 6),
            Text('নোট', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(getS('note')),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final phone = (_request?['contact_phone'] ?? '').toString();
    final isOwner = _request?['is_owner'] == true;
    final status = (_request?['status'] ?? 'open').toString();

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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কপি করা হয়েছে')));
                        }
                      }
                    : null,
                icon: const Icon(Icons.copy),
                label: const Text('নম্বর কপি'),
              ),
            ),
          ],
        ),
        if (isOwner && status == 'open') ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _closeRequest,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('অনুরোধ বন্ধ করুন'),
          ),
        ],
      ],
    );
  }
}
