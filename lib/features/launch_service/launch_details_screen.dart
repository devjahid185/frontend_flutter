import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'launch_form_screen.dart';

class LaunchDetailsScreen extends StatefulWidget {
  const LaunchDetailsScreen({super.key, required this.launchId});

  final int launchId;

  @override
  State<LaunchDetailsScreen> createState() => _LaunchDetailsScreenState();
}

class _LaunchDetailsScreenState extends State<LaunchDetailsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/launches/${widget.launchId}');
      _item = (res as Map).cast<String, dynamic>();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'তথ্য লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String value, String type) async {
    if (value.trim().isEmpty) return;
    final uri = type == 'tel' ? Uri.parse('tel:$value') : Uri.parse(value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = _item;
    return Scaffold(
      appBar: const ModernAppBar(title: 'লঞ্চ বিস্তারিত', subtitle: 'রুট, সময় ও যোগাযোগ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : item == null
                  ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 26, backgroundColor: scheme.primary.withValues(alpha: 0.12), child: Icon(Icons.directions_boat_filled_outlined, color: scheme.primary)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(_s('name', 'লঞ্চ'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text('${_s('route_from', 'রুট নেই')} → ${_s('route_to', 'রুট নেই')}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary)),
                                const SizedBox(height: 8),
                                Text(_s('operator_name', 'অপারেটর তথ্য নেই'), style: TextStyle(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section('সময় ও টার্মিনাল', [
                          _row('ছাড়ার সময়', _s('departure_time', 'দেওয়া নেই')),
                          _row('পৌঁছানোর সময়', _s('arrival_time', 'দেওয়া নেই')),
                          _row('চলার দিন', _s('running_days', 'দেওয়া নেই')),
                          _row('ছাড়ার ঘাট', _s('departure_terminal', 'দেওয়া নেই')),
                          _row('গন্তব্য ঘাট', _s('arrival_terminal', 'দেওয়া নেই')),
                        ]),
                        _section('ভাড়া', [
                          _row('ডেক', _money('deck_fare')),
                          _row('চেয়ার', _money('chair_fare')),
                          _row('সিঙ্গেল কেবিন', _money('single_cabin_fare')),
                          _row('ডাবল কেবিন', _money('double_cabin_fare')),
                        ]),
                        _section('সুবিধা', [
                          _row('কেবিন', _yesNo('has_cabin')),
                          _row('এসি', _yesNo('has_ac')),
                          _row('খাবার', _yesNo('has_food')),
                          _row('অনলাইন বুকিং', _yesNo('online_booking')),
                        ]),
                        _section('যোগাযোগ', [
                          _row('হটলাইন', _s('hotline', 'দেওয়া নেই')),
                          _row('ফোন', ((_item?['phones'] as List?)?.join(', ') ?? 'দেওয়া নেই')),
                          _row('ঠিকানা', _s('address', 'দেওয়া নেই')),
                          _row('ওয়েবসাইট', _s('website', 'দেওয়া নেই')),
                        ]),
                        if (_s('description', '').isNotEmpty) _section('বিবরণ', [Text(_s('description', ''), style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45))]),
                        if (_s('notes', '').isNotEmpty) _section('নোট', [Text(_s('notes', ''), style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45))]),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: FilledButton.icon(onPressed: () => _open(_s('hotline', ''), 'tel'), icon: const Icon(Icons.call), label: const Text('কল করুন'))),
                            const SizedBox(width: 10),
                            if (item['is_owner'] == true)
                              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LaunchFormScreen(initial: item))).then((_) => _load()), icon: const Icon(Icons.edit_outlined), label: const Text('এডিট'))),
                          ],
                        ),
                      ],
                    ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...children]),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))]),
      );

  String _s(String key, [String fallback = '-']) {
    final value = _item?[key]?.toString().trim();
    return value == null || value.isEmpty || value == 'null' ? fallback : value;
  }

  String _money(String key) => _s(key, '').isEmpty ? 'দেওয়া নেই' : '৳ ${_s(key)}';
  String _yesNo(String key) => _item?[key] == true || _item?[key] == 1 ? 'আছে' : 'নেই';
}