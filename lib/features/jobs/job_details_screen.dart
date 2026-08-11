import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _job;

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
      final res = await _api.get('/jobs/${widget.jobId}');
      if (res is Map<String, dynamic>) _job = res;
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

  Future<void> _applyDialog() async {
    final phone = TextEditingController();
    final expected = TextEditingController();
    final note = TextEditingController();
    String? cvPath;
    String? cvName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('আবেদন করুন'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'ফোন নম্বর'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: expected,
                    decoration: const InputDecoration(
                      labelText: 'এক্সপেক্টেড স্যালারি',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'নোট (ঐচ্ছিক)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const [
                          'pdf',
                          'doc',
                          'docx',
                          'jpg',
                          'jpeg',
                          'png',
                        ],
                      );
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          cvPath = result.files.single.path;
                          cvName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text(cvName ?? 'CV আপলোড করুন'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('বাতিল'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('জমা দিন'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    try {
      if (cvPath != null) {
        await _api.postMultipart(
          '/jobs/apply',
          fields: {
            'job_id': widget.jobId.toString(),
            'phone': phone.text.trim(),
            'expected_salary': expected.text.trim(),
            'note': note.text.trim(),
          },
          files: {'cv_file': cvPath!},
        );
      } else {
        await _api.post(
          '/jobs/apply',
          body: {
            'job_id': widget.jobId,
            'phone': phone.text.trim(),
            'expected_salary': expected.text.trim(),
            'note': note.text.trim(),
          },
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('আবেদন জমা হয়েছে')));
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('আবেদন জমা হয়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'চাকরি ডিটেইলস',
        subtitle: 'ডিটেইলস দেখুন',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : _job == null
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
    final title = (_job?['title'] ?? 'চাকরি').toString();
    final company = (_job?['company'] ?? '-').toString();
    final salary = (_job?['salary'] ?? '-').toString();
    final status = (_job?['status'] ?? 'open').toString();

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
          Text(company, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                salary,
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

  Widget _infoCard(BuildContext context, ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) =>
        (_job?[key]?.toString().trim().isNotEmpty ?? false)
        ? _job![key].toString()
        : fallback;

    String showIf(String key) {
      final value = getS(key);
      return value == '-' ? '' : value;
    }

    final info = <Map<String, String>>[
      {'label': 'কর্মস্থল/ঠিকানা', 'value': getS('location')},
      {'label': 'কাজের ধরন', 'value': getS('location_type')},
      {'label': 'টাইপ', 'value': getS('employment_type', getS('type'))},
      {'label': 'অভিজ্ঞতা', 'value': getS('experience_level')},
      {'label': 'শিক্ষাগত যোগ্যতা', 'value': getS('education')},
      {'label': 'ভ্যাকেন্সি', 'value': getS('vacancies')},
      {'label': 'ডেডলাইন', 'value': getS('deadline')},
      {'label': 'লিঙ্গ', 'value': getS('gender')},
      {
        'label': 'বয়স সীমা',
        'value': [
          showIf('age_min'),
          showIf('age_max'),
        ].where((e) => e.isNotEmpty).join(' - '),
      },
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
            'বিস্তারিত',
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (getS('salary_min') != '-' || getS('salary_max') != '-')
                _chip(
                  context,
                  'বেতন: ${getS('salary_min')} - ${getS('salary_max')}',
                ),
              if (getS('negotiable') != '-')
                _chip(
                  context,
                  'আলোচনা: ${getS('negotiable') == '1' || getS('negotiable') == 'true' ? 'হ্যাঁ' : 'না'}',
                ),
              if (getS('company_size') != '-')
                _chip(context, 'কোম্পানি আকার: ${getS('company_size')}'),
              if (getS('company_website') != '-')
                _chip(context, 'ওয়েবসাইট: ${getS('company_website')}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'বিবরণ',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(getS('description', 'বিবরণ নেই')),
          if (getS('responsibilities') != '-') ...[
            const SizedBox(height: 10),
            Text(
              'দায়িত্বসমূহ',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(getS('responsibilities')),
          ],
          if (getS('requirements') != '-') ...[
            const SizedBox(height: 10),
            Text(
              'চাহিদা/যোগ্যতা',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(getS('requirements')),
          ],
          if (getS('benefits') != '-') ...[
            const SizedBox(height: 10),
            Text(
              'সুবিধা',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(getS('benefits')),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final phone = (_job?['contact_phone'] ?? _job?['contact'] ?? '').toString();
    final email = (_job?['contact_email'] ?? '').toString();
    final website = (_job?['company_website'] ?? '').toString();
    final isOwner = _job?['is_owner'] == true;
    final status = (_job?['status'] ?? 'open').toString();

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
        if (!isOwner &&
            status == 'open' &&
            (_job?['post_type'] ?? 'hiring') == 'hiring') ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _applyDialog,
            icon: const Icon(Icons.send),
            label: const Text('আবেদন করুন'),
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('mailto:$email');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text('ইমেইল করুন'),
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
        if (isOwner) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _showApplications,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('আবেদনগুলো দেখুন'),
          ),
        ],
      ],
    );
  }

  Future<void> _showApplications() async {
    final scheme = Theme.of(context).colorScheme;
    List<Map<String, dynamic>> apps = [];
    try {
      final res = await _api.get('/jobs/${widget.jobId}/applications');
      apps = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      apps = [];
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: apps.isEmpty
                ? const Center(child: Text('কোনো আবেদন নেই'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final user = app['user'] as Map<String, dynamic>?;
                      final name = (user?['name'] ?? 'প্রার্থী').toString();
                      final phone = (app['phone'] ?? '').toString();
                      final cvUrl = (app['cv_url'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: scheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                Icons.person,
                                color: scheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: cvUrl.isNotEmpty
                                  ? () async {
                                      final uri = Uri.parse(cvUrl);
                                      if (await canLaunchUrl(uri))
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                    }
                                  : null,
                              child: const Text('CV ডাউনলোড'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
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
