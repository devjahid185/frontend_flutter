import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'restaurant_form_screen.dart';
import 'restaurant_list_screen.dart';
import 'my_restaurants_screen.dart';

class RestaurantCategoryScreen extends StatefulWidget {
  const RestaurantCategoryScreen({super.key});

  @override
  State<RestaurantCategoryScreen> createState() => _RestaurantCategoryScreenState();
}

class _RestaurantCategoryScreenState extends State<RestaurantCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  final Map<String, String> _categoryInfo = const {
    'বাংলা খাবার': 'ভাত, মাছ, মাংস, দেশি রান্না',
    'বিরিয়ানি': 'কাচ্চি, তেহারি, চিকেন বিরিয়ানি',
    'ফাস্ট ফুড': 'বার্গার, ফ্রাই, স্যান্ডউইচ',
    'চাইনিজ': 'চাইনিজ ও এশিয়ান আইটেম',
    'ক্যাফে': 'কফি, স্ন্যাকস, হালকা খাবার',
    'ডেজার্ট': 'মিষ্টি, ডেজার্ট ও বেকারি',
    'সীফুড': 'মাছ ও সীফুড আইটেম',
    'স্ট্রিট ফুড': 'চটপটি, ফুচকা, স্ন্যাকস',
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
      final res = await _api.get('/restaurants/categories');
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
      appBar: const ModernAppBar(title: 'রেস্টুরেন্ট', subtitle: 'ক্যাটাগরি বাছাই করুন'),
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
                      MaterialPageRoute(builder: (_) => const RestaurantFormScreen()),
                    ),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('রেস্টুরেন্ট যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyRestaurantsScreen()),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার রেস্টুরেন্ট'),
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
                      child: Icon(Icons.restaurant_menu, color: scheme.primary),
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
                              MaterialPageRoute(builder: (_) => RestaurantListScreen(categoryId: id, categoryName: name)),
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
    return 'রেস্টুরেন্টের তথ্য দেখুন';
  }
}
