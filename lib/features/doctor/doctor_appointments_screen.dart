import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _page = 1;
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final res = await _api.get('/doctor-appointments/doctor/${widget.doctorId}', query: {
        'page': reset ? '1' : (_page + 1).toString(),
        'per_page': '50',
      });
      final nextItems = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? nextItems : [..._items, ...nextItems];
      _page = (res['current_page'] as num?)?.toInt() ?? _page;
      _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _updateStatus(int index, String status) async {
    final id = (_items[index]['id'] as num?)?.toInt() ?? 0;
    if (id == 0) return;
    try {
      await _api.post('/doctor-appointments/$id/status', body: {'status': status});
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

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'অ্যাপয়েন্টমেন্ট তালিকা', subtitle: 'রোগীর অনুরোধ দেখুন'),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
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
              ...[
                ..._items.asMap().entries.map((entry) => _card(entry.key, entry.value, scheme)),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 22),
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _loadMore,
                      icon: _loadingMore
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(_loadingMore ? 'লোড হচ্ছে...' : 'আরও দেখুন'),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _card(int index, Map<String, dynamic> item, ColorScheme scheme) {
    final name = (item['patient_name'] ?? '').toString();
    final age = (item['patient_age'] ?? '').toString();
    final gender = (item['patient_gender'] ?? '').toString();
    final phone = (item['contact_phone'] ?? '').toString();
    final date = (item['appointment_date'] ?? '').toString();
    final time = (item['appointment_time'] ?? '').toString();
    final problem = (item['problem'] ?? '').toString();
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
          Text(name.isEmpty ? 'রোগী' : name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(age.isEmpty ? 'বয়স: -' : 'বয়স: $age'),
              const SizedBox(width: 12),
              Text(gender.isEmpty ? 'লিঙ্গ: -' : 'লিঙ্গ: $gender'),
            ],
          ),
          if (phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('ফোন: $phone')),
          const SizedBox(height: 6),
          Text('সময়: ${date.isEmpty ? '-' : date} ${time.isEmpty ? '' : time}'),
          if (problem.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('সমস্যা: $problem')),
          const SizedBox(height: 10),
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
