import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'electricity_office_form_screen.dart';

class MyElectricityOfficesScreen extends StatefulWidget {
  const MyElectricityOfficesScreen({super.key});

  @override
  State<MyElectricityOfficesScreen> createState() => _MyElectricityOfficesScreenState();
}

class _MyElectricityOfficesScreenState extends State<MyElectricityOfficesScreen> {
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
      final res = await _api.get('/electricity/my');
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
      appBar: const ModernAppBar(title: 'আমার অফিস', subtitle: 'আপনার যোগ করা তালিকা'),
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
                child: Center(child: Text('আপনার কোনো অফিস নেই')),
              )
            else
              ..._items.map((office) {
                final name = (office['name'] ?? 'অফিস').toString();
                final address = (office['address'] ?? '').toString();
                return Card(
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: address.isEmpty ? null : Text(address),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ElectricityOfficeFormScreen(initial: office)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
