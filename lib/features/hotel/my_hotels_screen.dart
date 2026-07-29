import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'hotel_form_screen.dart';

class MyHotelsScreen extends StatefulWidget {
  const MyHotelsScreen({super.key});

  @override
  State<MyHotelsScreen> createState() => _MyHotelsScreenState();
}

class _MyHotelsScreenState extends State<MyHotelsScreen> {
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
      final res = await _api.get('/hotels/my');
      _items = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
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
    return Scaffold(
      appBar: const ModernAppBar(title: 'আমার হোটেল', subtitle: 'আপনার যুক্ত করা তালিকা'),
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
                child: Center(child: Text('আপনার কোনো হোটেল নেই')),
              )
            else
              ..._items.map((hotel) {
                final name = (hotel['name'] ?? 'হোটেল').toString();
                final district = (hotel['district'] ?? '').toString();
                return Card(
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: district.isEmpty ? null : Text(district),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HotelFormScreen(initial: hotel)),
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
