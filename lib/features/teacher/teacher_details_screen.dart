import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'teacher_profile_form_screen.dart';

class TeacherDetailsScreen extends StatefulWidget {
  const TeacherDetailsScreen({super.key, required this.teacherId});

  final int teacherId;

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _teacher;
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
      final res = await _api.get('/teachers/${widget.teacherId}');
      if (res is Map<String, dynamic>) _teacher = res;
      await _loadReviews();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await _api.get('/reviews/teacher/${widget.teacherId}');
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
      appBar: const ModernAppBar(title: 'শিক্ষক বিস্তারিত', subtitle: 'টিউটর তথ্য'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _teacher == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
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

  Widget _header(ColorScheme scheme) {
    final name = (_teacher?['name'] ?? '').toString();
    final title = (_teacher?['title'] ?? '').toString();
    final rating = double.tryParse((_teacher?['rating'] ?? '0').toString()) ?? 0;
    final imageUrl = (_teacher?['image_url'] ?? '').toString();
    final categoryName = (_teacher?['category_name'] ?? '').toString();
    final available = _teacher?['is_available'] == true || _teacher?['is_available'] == 1;

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
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.school, color: scheme.primary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (title.isNotEmpty) Text(title, style: TextStyle(color: scheme.onSurfaceVariant)),
                if (categoryName.isNotEmpty) Text(categoryName, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(available ? 'সেবা চলছে' : 'সেবা বন্ধ', style: TextStyle(color: scheme.onPrimary, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) => (_teacher?[key]?.toString().trim().isNotEmpty ?? false)
        ? _teacher![key].toString()
        : fallback;

    final subjects = (_teacher?['subjects'] as List?)?.cast<String>() ?? [];
    final classLevels = (_teacher?['class_levels'] as List?)?.cast<String>() ?? [];

    final info = <Map<String, String>>[
      {'label': 'মাধ্যম', 'value': getS('medium')},
      {'label': 'শিক্ষাগত যোগ্যতা', 'value': getS('education')},
      {'label': 'ইনস্টিটিউট', 'value': getS('institute')},
      {'label': 'অভিজ্ঞতা', 'value': getS('experience_years')},
      {'label': 'ঘণ্টা ভিত্তিক ফি', 'value': getS('hourly_rate')},
      {'label': 'মাসিক ফি', 'value': getS('monthly_rate')},
      {'label': 'লিঙ্গ', 'value': getS('gender')},
      {'label': 'মোড', 'value': getS('mode')},
      {'label': 'জেলা', 'value': getS('district')},
      {'label': 'উপজেলা', 'value': getS('upazila')},
      {'label': 'ঠিকানা', 'value': getS('address')},
      {'label': 'পছন্দের এলাকা', 'value': getS('preferred_area')},
      {'label': 'ফোন', 'value': getS('phone')},
      {'label': 'ইমেইল', 'value': getS('email')},
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
                    SizedBox(width: 120, child: Text(e['label']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(child: Text(e['value']!)),
                  ],
                ),
              )),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('বিষয়', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: subjects.map((e) => _chip(e, scheme)).toList()),
          ],
          if (classLevels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ক্লাস/লেভেল', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: classLevels.map((e) => _chip(e, scheme)).toList()),
          ],
          if (getS('availability') != '-') ...[
            const SizedBox(height: 8),
            Text('সময়সূচি', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(getS('availability')),
          ],
          if (getS('about') != '-') ...[
            const SizedBox(height: 8),
            Text('পরিচিতি', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(getS('about')),
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
    final phone = (_teacher?['phone'] ?? '').toString();
    final isOwner = _teacher?['is_owner'] == true;
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নম্বর কপি হয়েছে')));
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
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TeacherProfileFormScreen(initial: _teacher)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('প্রোফাইল আপডেট'),
          )
        else
          FilledButton.icon(
            onPressed: _showRatingDialog,
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('রেটিং দিন'),
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
                    '/reviews/teacher',
                    body: {
                      'target_id': widget.teacherId,
                      'rating': selected,
                      'comment': commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    },
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়েছে')));
                    await _load();
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
