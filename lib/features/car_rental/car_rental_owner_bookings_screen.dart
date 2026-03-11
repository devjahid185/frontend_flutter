import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class CarRentalOwnerBookingsScreen extends StatefulWidget {
  const CarRentalOwnerBookingsScreen({super.key, required this.rentalId});

  final int rentalId;

  @override
  State<CarRentalOwnerBookingsScreen> createState() => _CarRentalOwnerBookingsScreenState();
}

class _CarRentalOwnerBookingsScreenState extends State<CarRentalOwnerBookingsScreen> {
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
      final res = await _api.get('/car-rental-bookings/owner/${widget.rentalId}');
      _items = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int index, String status) async {
    final id = (_items[index]['id'] as num?)?.toInt() ?? 0;
    if (id == 0) return;
    try {
      await _api.post('/car-rental-bookings/$id/status', body: {'status': status});
      setState(() => _items[index]['status'] = status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('স্ট্যাটাস আপডেট হয়েছে')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('আপডেট করা যায়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'বুকিং তালিকা', subtitle: 'ক্লায়েন্ট রিকোয়েস্ট'),
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
                child: Center(child: Text('কোনো বুকিং নেই')),
              )
            else
              ..._items.asMap().entries.map((entry) => _card(entry.key, entry.value, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _card(int index, Map<String, dynamic> item, ColorScheme scheme) {
    final start = (item['start_date'] ?? '').toString();
    final end = (item['end_date'] ?? '').toString();
    final phone = (item['contact_phone'] ?? '').toString();
    final pickup = (item['pickup_location'] ?? '').toString();
    final status = (item['status'] ?? 'pending').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('তারিখ: $start${end.isNotEmpty ? ' - $end' : ''}'),
          if (pickup.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('পিকআপ: $pickup')),
          if (phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('ফোন: $phone')),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('স্ট্যাটাস: '),
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('অপেক্ষমান')),
                  DropdownMenuItem(value: 'confirmed', child: Text('নিশ্চিত')),
                  DropdownMenuItem(value: 'cancelled', child: Text('বাতিল')),
                  DropdownMenuItem(value: 'completed', child: Text('সম্পন্ন')),
                ],
                onChanged: (value) {
                  if (value != null && value != status) {
                    _updateStatus(index, value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
