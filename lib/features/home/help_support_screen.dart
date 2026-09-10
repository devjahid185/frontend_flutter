import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _faqs = [];
  Map<String, dynamic> _support = {};

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final faqs = await _api.get('/faqs');
      if (faqs is List) {
        _faqs = faqs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      try {
        final support = await _api.get('/support-settings', auth: false);
        if (support is Map<String, dynamic> && support['settings'] is Map) {
          _support = Map<String, dynamic>.from(support['settings'] as Map);
        }
      } catch (_) {
        _support = {};
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'FAQ লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'হেল্প & সাপোর্ট',
        subtitle: 'সহায়তা ও FAQ',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(context, 'FAQ'),
                _faqSection(context),
                const SizedBox(height: 16),
                _sectionTitle(context, 'যোগাযোগ'),
                _contactSection(context),
              ],
            ),
    );
  }

  Widget _faqSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_faqs.isEmpty) {
      return Text(
        'এখনো কোনো FAQ নেই',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final faq in _faqs) {
      final category = (faq['category'] ?? 'সাধারণ').toString();
      grouped.putIfAbsent(category, () => []).add(faq);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final items = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              ...items.asMap().entries.map((row) {
                final index = row.key + 1;
                final faq = row.value;
                final question = (faq['question'] ?? '').toString();
                final answer = (faq['answer'] ?? '').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    iconColor: scheme.primary,
                    collapsedIconColor: scheme.onSurfaceVariant,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Text(
                          answer,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _contactSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phone = (_support['phone'] ?? '').toString().trim();
    final email = (_support['email'] ?? '').toString().trim();
    final whatsapp = (_support['whatsapp'] ?? '').toString().trim();
    final availability = (_support['availability'] ?? '').toString().trim();
    final note = (_support['note'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phone_in_talk_outlined),
            title: const Text('সাপোর্ট নম্বর'),
            subtitle: Text(
              phone.isEmpty ? 'যোগাযোগ নম্বর যুক্ত করা হয়নি' : phone,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('ইমেইল সাপোর্ট'),
            subtitle: Text(
              email.isEmpty ? 'ইমেইল যুক্ত করা হয়নি' : email,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          if (whatsapp.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('WhatsApp'),
              subtitle: Text(
                whatsapp,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          if (availability.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('সাপোর্ট সময়'),
              subtitle: Text(
                availability,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                note,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
