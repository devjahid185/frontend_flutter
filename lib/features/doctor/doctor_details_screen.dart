import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'doctor_booking_screen.dart';
import 'doctor_profile_form_screen.dart';
import 'doctor_appointments_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _doctor;

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
      final res = await _api.get('/doctors/${widget.doctorId}');
      if (res is Map<String, dynamic>) _doctor = res;
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
        title: 'ডাক্তার বিস্তারিত',
        subtitle: 'চেম্বার তথ্য',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : _doctor == null
          ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, scheme),
                const SizedBox(height: 12),
                _info(context, scheme),
                const SizedBox(height: 12),
                _schedule(context, scheme),
                const SizedBox(height: 12),
                _actions(context, scheme),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme) {
    final name = (_doctor?['name'] ?? '').toString();
    final title = (_doctor?['title'] ?? '').toString();
    final spec = (_doctor?['specialization'] ?? '').toString();
    final fees = (_doctor?['fees'] ?? '').toString();
    final available =
        _doctor?['is_available'] == true || _doctor?['is_available'] == 1;
    final imageUrl = (_doctor?['image_url'] ?? '').toString();
    final categoryName = (_doctor?['category_name'] ?? '').toString();

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
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl.isEmpty
                ? Icon(Icons.medical_services_outlined, color: scheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
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
                if (title.isNotEmpty)
                  Text(title, style: TextStyle(color: scheme.onSurfaceVariant)),
                if (spec.isNotEmpty)
                  Text(spec, style: TextStyle(color: scheme.onSurfaceVariant)),
                if (categoryName.isNotEmpty)
                  Text(
                    categoryName,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fees.isEmpty ? '-' : '৳ $fees',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  available ? 'সেবা চলছে' : 'সেবা বন্ধ',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 10),
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
        (_doctor?[key]?.toString().trim().isNotEmpty ?? false)
        ? _doctor![key].toString()
        : fallback;

    final info = <Map<String, String>>[
      {'label': 'হাসপাতাল', 'value': getS('hospital')},
      {'label': 'ক্লিনিক', 'value': getS('clinic')},
      {'label': 'অভিজ্ঞতা', 'value': getS('experience_years')},
      {'label': 'ডিগ্রি', 'value': getS('degrees')},
      {'label': 'বিএমডিসি', 'value': getS('bmdc_number')},
      {'label': 'ফোন', 'value': getS('phone')},
      {'label': 'ইমেইল', 'value': getS('email')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'চেম্বার সময়', 'value': getS('chamber_time')},
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
                    width: 120,
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
          if (getS('about') != '-') ...[
            const SizedBox(height: 8),
            Text(
              'পরিচিতি',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(getS('about')),
          ],
        ],
      ),
    );
  }

  Widget _schedule(BuildContext context, ColorScheme scheme) {
    final schedules =
        (_doctor?['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (schedules.isEmpty) return const SizedBox.shrink();
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
            'সময়সূচি',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...schedules.map((s) {
            final day = s['day_of_week']?.toString() ?? '';
            final start = s['start_time']?.toString() ?? '';
            final end = s['end_time']?.toString() ?? '';
            final note = s['note']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$day: $start - $end ${note.isEmpty ? '' : '($note)'}',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final phone = (_doctor?['phone'] ?? '').toString();
    final isOwner = _doctor?['is_owner'] == true;
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
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DoctorBookingScreen(doctorId: widget.doctorId),
            ),
          ),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('অ্যাপয়েন্টমেন্ট নিন'),
        ),
        if (isOwner) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DoctorProfileFormScreen(initial: _doctor),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('প্রোফাইল আপডেট'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DoctorAppointmentsScreen(doctorId: widget.doctorId),
              ),
            ),
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('অ্যাপয়েন্টমেন্ট তালিকা'),
          ),
        ],
      ],
    );
  }
}
