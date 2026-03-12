import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'hotel_form_screen.dart';
import 'hotel_list_screen.dart';
import 'my_hotels_screen.dart';

class HotelCategoryScreen extends StatefulWidget {
  const HotelCategoryScreen({super.key});

  @override
  State<HotelCategoryScreen> createState() => _HotelCategoryScreenState();
}

class _HotelCategoryScreenState extends State<HotelCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  final Map<String, String> _categoryInfo = const {
    'হোটেল': 'স্ট্যান্ডার্ড আবাসন, ফ্যামিলি ও বিজনেস থাকার সুবিধা',
    'রিসোর্ট': 'পর্যটন ও রিল্যাক্সেশন-কেন্দ্রিক আবাসন',
    'গেস্ট হাউস': 'কম খরচে থাকার সুবিধা ও প্রশিক্ষণ কেন্দ্র',
    'মোটেল': 'সড়কপথের যাত্রীদের জন্য থাকার জায়গা',
    'লজ': 'লো বাজেট বা ট্রানজিট থাকার সুবিধা',
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
      final res = await _api.get('/hotels/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডাটা লোড করা যায়নি';
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
      appBar: const ModernAppBar(title: 'হোটেল', subtitle: 'ক্যাটাগরি বাছাই করুন'),
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
                      MaterialPageRoute(builder: (_) => const HotelFormScreen()),
                    ),
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text('হোটেল যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyHotelsScreen()),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার হোটেল'),
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
                      child: Icon(Icons.hotel_outlined, color: scheme.primary),
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
                              MaterialPageRoute(builder: (_) => HotelListScreen(categoryId: id, categoryName: name)),
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
    return 'হোটেলের সুবিধা ও তথ্য দেখুন';
  }
}
