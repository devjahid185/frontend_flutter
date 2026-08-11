import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'teacher_list_screen.dart';
import 'teacher_profile_form_screen.dart';
import 'teacher_request_list_screen.dart';
import 'student_request_list_screen.dart';
import 'my_teacher_requests_screen.dart';
import 'my_student_requests_screen.dart';

class TeacherCategoryScreen extends StatefulWidget {
  const TeacherCategoryScreen({super.key});

  @override
  State<TeacherCategoryScreen> createState() => _TeacherCategoryScreenState();
}

class _TeacherCategoryScreenState extends State<TeacherCategoryScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

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
      final res = await _api.get('/teachers/categories');
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
        title: 'শিক্ষক/টিউটর',
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
                        builder: (_) => const TeacherProfileFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('টিউটর প্রোফাইল'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeacherRequestListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.search_outlined),
                    label: const Text('টিউশন রিকোয়েস্ট'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudentRequestListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('স্টুডেন্ট রিকোয়েস্ট'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyTeacherRequestsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার রিকোয়েস্ট'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyStudentRequestsScreen(),
                ),
              ),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('আমার স্টুডেন্ট রিকোয়েস্ট'),
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
                final description = (cat['description'] ?? '').toString();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.school, color: scheme.primary),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: description.isEmpty
                        ? null
                        : Text(
                            description,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id > 0
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeacherListScreen(
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
}
