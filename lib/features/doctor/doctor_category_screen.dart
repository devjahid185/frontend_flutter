import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'doctor_list_screen.dart';
import 'doctor_profile_form_screen.dart';
import 'my_doctor_appointments_screen.dart';

class DoctorCategoryScreen extends StatefulWidget {
  const DoctorCategoryScreen({super.key});

  @override
  State<DoctorCategoryScreen> createState() => _DoctorCategoryScreenState();
}

class _DoctorCategoryScreenState extends State<DoctorCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];
  final Map<String, String> _categoryInfo = const {
    'মেডিসিন': 'জ্বর, সর্দি, গ্যাস্ট্রিক, সাধারণ শারীরিক সমস্যা',
    'শিশুরোগ': 'শিশুর জ্বর, কাশি, খাওয়ায় সমস্যা ও টিকা সংক্রান্ত',
    'গাইনি': 'নারীর স্বাস্থ্য, গর্ভাবস্থা, পিরিয়ড সমস্যা',
    'কার্ডিওলজি': 'হার্টের ব্যথা, উচ্চ রক্তচাপ, হার্টের সমস্যা',
    'নিউরোলজি': 'মাথাব্যথা, খিঁচুনি, স্নায়ুর সমস্যা',
    'অর্থোপেডিক': 'হাড়/জয়েন্ট ব্যথা, ফ্র্যাকচার',
    'চর্মরোগ': 'চুলকানি, এলার্জি, চামড়ার দাগ',
    'চক্ষু': 'চোখে ঝাপসা, ব্যথা, দৃষ্টিশক্তি সমস্যা',
    'ইএনটি': 'কান, নাক, গলার সমস্যা',
    'ডেন্টাল': 'দাঁতের ব্যথা, ক্ষয়, মাড়ির সমস্যা',
    'ইউরোলজি': 'কিডনি/মূত্রনালী সমস্যা, প্রস্রাবে জ্বালা',
    'কিডনি': 'কিডনি রোগ, ক্রিয়েটিনিন সমস্যা',
    'ডায়াবেটিস': 'ডায়াবেটিস নিয়ন্ত্রণ, হরমোনজনিত সমস্যা',
    'গ্যাস্ট্রো': 'পেটব্যথা, অ্যাসিডিটি, লিভার সমস্যা',
    'পালমোনারি': 'শ্বাসকষ্ট, হাঁপানি, বুকে কাশি',
    'মনোরোগ': 'দুশ্চিন্তা, ঘুমের সমস্যা, ডিপ্রেশন',
    'ফিজিওথেরাপি': 'পেইন ম্যানেজমেন্ট, স্টিফনেস, রিহ্যাব',
    'সার্জারি': 'অপারেশন/সার্জারি পরামর্শ',
    'অনকোলজি': 'ক্যান্সার সম্পর্কিত পরামর্শ',
    'নিউরোসার্জারি': 'মস্তিষ্ক/মেরুদণ্ড সার্জারি পরামর্শ',
    'কার্ডিয়াক সার্জারি': 'হার্ট সার্জারি সম্পর্কিত পরামর্শ',
    'রেডিওলজি': 'এক্স-রে/ইমেজিং রিপোর্ট পরামর্শ',
    'প্যাথলজি': 'রক্ত/টেস্ট রিপোর্ট ব্যাখ্যা',
    'অ্যানেস্থেশিয়া': 'অপারেশনের অ্যানেস্থেসিয়া সংক্রান্ত',
    'অন্যান্য': 'অন্যান্য স্বাস্থ্য সমস্যা',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/doctors/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _search.text.trim().isEmpty
        ? _categories
        : _categories
            .where((c) => c['name'].toString().contains(_search.text.trim()))
            .toList();

    return Scaffold(
      appBar: const ModernAppBar(title: 'ডাক্তার', subtitle: 'ক্যাটাগরি বাছাই করুন'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DoctorProfileFormScreen()),
                    ),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('ডাক্তার প্রোফাইল'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyDoctorAppointmentsScreen()),
                    ),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('আমার অ্যাপয়েন্টমেন্ট'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'ক্যাটাগরি সার্চ'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(child: Text(_error!, style: TextStyle(color: scheme.error))),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('ক্যাটাগরি পাওয়া যায়নি')),
              )
            else
              ...filtered.map((cat) {
                final id = (cat['id'] as num?)?.toInt() ?? 0;
                final name = cat['name'].toString();
                final info = _findCategoryInfo(name);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.medical_services_outlined, color: scheme.primary),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: info == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(info, style: TextStyle(color: scheme.onSurfaceVariant)),
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DoctorListScreen(categoryId: id, categoryName: name)),
                            )
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String? _findCategoryInfo(String name) {
    final key = name.trim();
    for (final entry in _categoryInfo.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return _categoryInfo['অন্যান্য'];
  }
}
