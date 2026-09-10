import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

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
      backgroundColor: const Color(0xfff4f7f6),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const _SupportHeader(title: 'হেল্প & সাপোর্ট'),
                const SizedBox(height: 16),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe5e7eb)),
        ),
        child: const Text(
          'এখনো কোনো FAQ নেই',
          style: TextStyle(color: Color(0xff4b5563)),
        ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  color: Color(0xff006a4e),
                  fontWeight: FontWeight.w900,
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
                    color: const Color(0xfff8faf9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffe5e7eb)),
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
                      backgroundColor: const Color(0xffe6f1ee),
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: Color(0xff006a4e),
                          fontWeight: FontWeight.w900,
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
                          border: Border.all(color: const Color(0xffe5e7eb)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
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
        style: const TextStyle(
          color: Color(0xff006a4e),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff1f2937),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
