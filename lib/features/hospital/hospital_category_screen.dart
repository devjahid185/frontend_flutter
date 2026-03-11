import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'hospital_list_screen.dart';
import 'hospital_form_screen.dart';
import 'my_hospitals_screen.dart';

class HospitalCategoryScreen extends StatefulWidget {
  const HospitalCategoryScreen({super.key});

  @override
  State<HospitalCategoryScreen> createState() => _HospitalCategoryScreenState();
}

class _HospitalCategoryScreenState extends State<HospitalCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  final Map<String, String> _categoryInfo = const {
    'সরকারি': 'সরকারি সেবাসমূহ, জরুরি ও ইনডোর সুবিধা',
    'বেসরকারি': 'প্রাইভেট ট্রিটমেন্ট, বিশেষায়িত সেবা',
    'ডায়াগনস্টিক': 'টেস্ট, রিপোর্ট, ইমেজিং সেবা',
    'ক্লিনিক': 'আউটডোর চিকিৎসা ও প্রাথমিক সেবা',
    'মাতৃসদন': 'ডেলিভারি, গর্ভাবস্থা, নারী স্বাস্থ্য',
    'শিশু': 'শিশু রোগ ও নিউবর্ন কেয়ার',
    'কার্ডিয়াক': 'হার্ট ও কার্ডিয়াক কেয়ার',
    'ক্যান্সার': 'অনকোলজি ও কেমো/রেডিও',
    'ট্রমা': 'দুর্ঘটনা ও জরুরি সার্জারি',
    'চক্ষু': 'চোখ ও দৃষ্টিশক্তি সেবা',
    'ডেন্টাল': 'দাঁত ও মুখগহ্বর সেবা',
    'মানসিক': 'মেন্টাল হেলথ ও কাউন্সেলিং',
    'পুনর্বাসন': 'ফিজিও/রিহ্যাব ও থেরাপি',
    'নার্সিং': 'ইনডোর কেয়ার ও সাপোর্ট',
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
      final res = await _api.get('/hospitals/categories');
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
        : _categories.where((c) => c['name'].toString().contains(_search.text.trim())).toList();

    return Scaffold(
      appBar: const ModernAppBar(title: 'হাসপাতাল', subtitle: 'ক্যাটাগরি বাছাই করুন'),
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
                      MaterialPageRoute(builder: (_) => const HospitalFormScreen()),
                    ),
                    icon: const Icon(Icons.local_hospital_outlined),
                    label: const Text('হাসপাতাল যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyHospitalsScreen()),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার তালিকা'),
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
                      child: Icon(Icons.local_hospital_outlined, color: scheme.primary),
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
                              MaterialPageRoute(builder: (_) => HospitalListScreen(categoryId: id, categoryName: name)),
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
    for (final entry in _categoryInfo.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return 'হাসপাতাল সেবা ও সুবিধা দেখুন';
  }
}
