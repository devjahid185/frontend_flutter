import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'student_request_details_screen.dart';

class MyStudentRequestsScreen extends StatefulWidget {
  const MyStudentRequestsScreen({super.key});

  @override
  State<MyStudentRequestsScreen> createState() => _MyStudentRequestsScreenState();
}

class _MyStudentRequestsScreenState extends State<MyStudentRequestsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      final res = await _api.get('/student-requests/my');
      _items = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
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
    return Scaffold(
      appBar: const ModernAppBar(title: 'আমার স্টুডেন্ট রিকোয়েস্ট', subtitle: 'আপনার দেওয়া অনুরোধ'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('আপনার কোনো রিকোয়েস্ট নেই')),
              )
            else
              ..._items.map((req) {
                final title = (req['title'] ?? 'রিকোয়েস্ট').toString();
                final status = (req['status'] ?? '').toString();
                final id = (req['id'] as num?)?.toInt() ?? 0;
                return Card(
                  child: ListTile(
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: status.isEmpty ? null : Text('স্ট্যাটাস: $status'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StudentRequestDetailsScreen(requestId: id)),
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
