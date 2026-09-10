import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'car_rental_list_screen.dart';
import 'car_rental_form_screen.dart';
import 'my_car_rentals_screen.dart';
import 'my_car_rental_bookings_screen.dart';

class CarRentalCategoryScreen extends StatefulWidget {
  const CarRentalCategoryScreen({super.key});

  @override
  State<CarRentalCategoryScreen> createState() =>
      _CarRentalCategoryScreenState();
}

class _CarRentalCategoryScreenState extends State<CarRentalCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  final Map<String, String> _categoryInfo = const {
    'সেডান': 'কর্পোরেট/পারিবারিক ভ্রমণ',
    'হ্যাচব্যাক': 'শহরের ছোট ট্রিপ',
    'এসইউভি': 'পরিবার ও লম্বা ভ্রমণ',
    'মাইক্রোবাস': 'গ্রুপ ট্রিপ/বিয়ে/পিকনিক',
    'মিনিবাস': 'ইভেন্ট/টুর/টিম ট্রিপ',
    'বাস': 'বড় গ্রুপ/ট্যুর',
    'প্রাইভেট কার': 'দৈনিক প্রয়োজন',
    'নোয়া': 'পরিবার ও ট্যুর',
    'হাইস': 'অফিস/ট্যুর/শাটল',
    'পিকআপ': 'পণ্য/গুডস ট্রান্সপোর্ট',
    'ট্রাক': 'ভারী মালামাল',
    'কাভার্ড ভ্যান': 'সেফ কার্গো',
    'অ্যাম্বুলেন্স': 'জরুরি সেবা',
    'বাইক': 'দ্রুত যাতায়াত',
    'ইলেকট্রিক': 'ইকো-ফ্রেন্ডলি রাইড',
    'লাক্সারি': 'প্রিমিয়াম রাইড',
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
      final res = await _api.get('/car-rentals/categories');
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
      appBar: const ModernAppBar(
        title: 'গাড়ি ভাড়া',
        subtitle: 'ক্যাটাগরি বাছাই করুন',
      ),
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
                      MaterialPageRoute(
                        builder: (_) => const CarRentalFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('গাড়ি যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyCarRentalsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার গাড়ি'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyCarRentalBookingsScreen(),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('আমার বুকিং'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'ক্যাটাগরি সার্চ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: const Center(child: LogoLoader(showLabel: true)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
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
                      child: Icon(Icons.directions_car, color: scheme.primary),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: info == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              info,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id > 0
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CarRentalListScreen(
                                categoryId: id,
                                categoryName: name,
                              ),
                            ),
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
    return 'ভাড়া ও চালক সুবিধা দেখুন';
  }
}
