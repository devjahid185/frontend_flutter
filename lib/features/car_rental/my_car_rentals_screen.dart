import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'car_rental_form_screen.dart';
import 'car_rental_owner_bookings_screen.dart';

class MyCarRentalsScreen extends StatefulWidget {
  const MyCarRentalsScreen({super.key});

  @override
  State<MyCarRentalsScreen> createState() => _MyCarRentalsScreenState();
}

class _MyCarRentalsScreenState extends State<MyCarRentalsScreen> {
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
      final res = await _api.get('/car-rentals/my');
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
      appBar: const ModernAppBar(title: 'আমার গাড়ি', subtitle: 'এডিট ও বুকিং'),
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
                child: Center(child: Text('কোনো গাড়ি নেই')),
              )
            else
              ..._items.map((item) => _card(context, item, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> item, ColorScheme scheme) {
    final title = (item['title'] ?? 'গাড়ি').toString();
    final id = (item['id'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CarRentalFormScreen(initial: item)),
            ),
            child: const Text('এডিট'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CarRentalOwnerBookingsScreen(rentalId: id)),
            ),
            child: const Text('বুকিং'),
          ),
        ],
      ),
    );
  }
}
