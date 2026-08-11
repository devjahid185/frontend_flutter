import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class TeacherRequestDetailsScreen extends StatefulWidget {
  const TeacherRequestDetailsScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<TeacherRequestDetailsScreen> createState() =>
      _TeacherRequestDetailsScreenState();
}

class _TeacherRequestDetailsScreenState
    extends State<TeacherRequestDetailsScreen> {
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
      final res = await _api.get('/teacher-requests/${widget.requestId}');
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
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _closeRequest() async {
    try {
      await _api.post('/teacher-requests/${widget.requestId}/close');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিকোয়েস্ট বন্ধ করা হয়েছে')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিকোয়েস্ট বন্ধ করা যায়নি')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'টিউশন রিকোয়েস্ট',
        subtitle: 'বিস্তারিত',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : _request == null
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
    final title = (_request?['title'] ?? '').toString();
    final category = (_request?['category_name'] ?? '').toString();
    final status = (_request?['status'] ?? '').toString();
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
          if (category.isNotEmpty)
            Text(category, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (status.isNotEmpty)
            Text(
              'স্ট্যাটাস: $status',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) =>
        (_request?[key]?.toString().trim().isNotEmpty ?? false)
        ? _request![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'ক্লাস', 'value': getS('class_level')},
      {'label': 'মাধ্যম', 'value': getS('medium')},
      {'label': 'মোড', 'value': getS('mode')},
      {'label': 'দিন/সপ্তাহ', 'value': getS('days_per_week')},
      {'label': 'বাজেট', 'value': getS('budget')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'ফোন', 'value': getS('phone')},
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
            'তথ্য',
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

  Widget _actions(ColorScheme scheme) {
    final phone = (_request?['phone'] ?? '').toString();
    final isOwner = _request?['is_owner'] == true;
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
                            const SnackBar(content: Text('নম্বর কপি হয়েছে')),
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
        const SizedBox(height: 10),
        if (isOwner)
          FilledButton.icon(
            onPressed: _closeRequest,
            icon: const Icon(Icons.lock_outline),
            label: const Text('রিকোয়েস্ট বন্ধ করুন'),
          ),
      ],
    );
  }
}
