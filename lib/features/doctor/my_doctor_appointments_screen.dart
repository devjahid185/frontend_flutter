import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class MyDoctorAppointmentsScreen extends StatefulWidget {
  const MyDoctorAppointmentsScreen({super.key});

  @override
  State<MyDoctorAppointmentsScreen> createState() => _MyDoctorAppointmentsScreenState();
}

class _MyDoctorAppointmentsScreenState extends State<MyDoctorAppointmentsScreen> {
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
      final res = await _api.get('/doctor-appointments/my');
      _items = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
      appBar: const ModernAppBar(title: 'আমার অ্যাপয়েন্টমেন্ট', subtitle: 'আপনার বুকিং তালিকা'),
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
                child: Center(child: Text('কোনো অ্যাপয়েন্টমেন্ট নেই')),
              )
            else
              ..._items.map((item) => _card(item, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item, ColorScheme scheme) {
    final doctorName = (item['doctor_name'] ?? '').toString();
    final hospital = (item['doctor_hospital'] ?? '').toString();
    final phone = (item['doctor_phone'] ?? '').toString();
    final date = (item['appointment_date'] ?? '').toString();
    final time = (item['appointment_time'] ?? '').toString();
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
          Text(doctorName.isEmpty ? 'ডাক্তার' : doctorName, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (hospital.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(hospital)),
          const SizedBox(height: 6),
          Text('তারিখ: ${date.isEmpty ? '-' : date} ${time.isEmpty ? '' : time}'),
          const SizedBox(height: 6),
          Text('স্ট্যাটাস: ${_statusLabel(status)}'),
          if (phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('ফোন: $phone')),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'নিশ্চিত';
      case 'cancelled':
        return 'বাতিল';
      case 'completed':
        return 'সম্পন্ন';
      default:
        return 'অপেক্ষমান';
    }
  }
}
