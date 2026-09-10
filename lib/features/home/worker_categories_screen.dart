import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/api_list_screen.dart';
import '../common/module_layout.dart';
import '../common/modern_app_bar.dart';
import 'worker_add_screen.dart';

class WorkerCategoriesScreen extends StatefulWidget {
  const WorkerCategoriesScreen({super.key});

  @override
  State<WorkerCategoriesScreen> createState() => _WorkerCategoriesScreenState();
}

class _WorkerCategoriesScreenState extends State<WorkerCategoriesScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

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
      final res = await _api.get('/worker/categories');
      if (res is List) {
        _items = res;
      }
    } catch (_) {
      _error = 'ক্যাটাগরি লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    IconData? mapCategoryIcon(String name) {
      final n = name.toLowerCase();
      if (n.contains('ইলেক') || n.contains('electric'))
        return Icons.electrical_services_rounded;
      if (n.contains('প্লাম্ব') || n.contains('পানি') || n.contains('sanitary'))
        return Icons.plumbing_rounded;
      if (n.contains('রাজ') || n.contains('mason') || n.contains('ইট'))
        return Icons.foundation_rounded;
      if (n.contains('ছুত') ||
          n.contains('carpenter') ||
          n.contains('ফার্নিচার'))
        return Icons.carpenter_rounded;
      if (n.contains('রং') || n.contains('paint'))
        return Icons.format_paint_rounded;
      if (n.contains('এসি') || n.contains('ac')) return Icons.ac_unit_rounded;
      if (n.contains('মোবাইল')) return Icons.phone_android_rounded;
      if (n.contains('ফ্রিজ')) return Icons.kitchen_rounded;
      if (n.contains('গাড়ি') || n.contains('বাইক') || n.contains('মেকানিক'))
        return Icons.build_circle_outlined;
      if (n.contains('ড্রাইভার')) return Icons.local_taxi_rounded;
      if (n.contains('টিউট')) return Icons.school_rounded;
      if (n.contains('রাঁধ') || n.contains('কুক'))
        return Icons.restaurant_rounded;
      if (n.contains('ক্লিন') || n.contains('পরিচার'))
        return Icons.cleaning_services_rounded;
      if (n.contains('ডেলিভারি')) return Icons.delivery_dining_rounded;
      if (n.contains('ওয়েল্ড')) return Icons.hardware_rounded;
      if (n.contains('সিসিটিভি') || n.contains('নেটওয়ার্ক'))
        return Icons.settings_input_antenna_rounded;
      if (n.contains('গ্লাস') || n.contains('অ্যালুমিন'))
        return Icons.window_rounded;
      if (n.contains('মালী')) return Icons.nature_people_rounded;
      return null;
    }

    String? normalizeIconUrl(String? raw) {
      final value = (raw ?? '').trim();
      if (value.isEmpty) return null;
      if (value.startsWith('http://') || value.startsWith('https://')) {
        try {
          final uri = Uri.parse(value);
          if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
            final apiUri = Uri.parse(AppConfig.apiBaseUrl);
            final origin =
                '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
            return '$origin${uri.path}';
          }
        } catch (_) {}
        return value;
      }

      final apiUri = Uri.parse(AppConfig.apiBaseUrl);
      final origin =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      if (value.startsWith('/')) {
        return '$origin$value';
      }
      return '$origin/storage/$value';
    }

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'কর্মী ক্যাটাগরি',
        subtitle: 'সব ধরনের মিস্ত্রি',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._items.map((item) {
                  final id = (item['id'] as num?)?.toInt() ?? 0;
                  final name = item['name']?.toString() ?? '-';
                  final iconUrl = normalizeIconUrl(item['icon']?.toString());
                  final count = (item['workers_count'] as num?)?.toInt() ?? 0;
                  final mappedIcon = mapCategoryIcon(name);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        backgroundImage: iconUrl != null
                            ? NetworkImage(iconUrl)
                            : null,
                        child: iconUrl != null
                            ? null
                            : (mappedIcon != null
                                  ? Icon(mappedIcon, color: scheme.primary)
                                  : Text(
                                      name.isNotEmpty
                                          ? name.substring(0, 1)
                                          : 'ক',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'মোট কর্মী: $count',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ApiListScreen(
                              title: name,
                              endpoint: '/workers',
                              query: {'category_id': '$id'},
                              layout: ModuleLayout.directory,
                              floatingActionButton:
                                  FloatingActionButton.extended(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WorkerAddScreen(
                                            initialCategoryId: id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('কর্মী যোগ করুন'),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
