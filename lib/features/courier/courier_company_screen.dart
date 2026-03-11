import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'courier_office_list_screen.dart';
import 'courier_form_screen.dart';
import 'my_courier_offices_screen.dart';

class CourierCompanyScreen extends StatefulWidget {
  const CourierCompanyScreen({super.key});

  @override
  State<CourierCompanyScreen> createState() => _CourierCompanyScreenState();
}

class _CourierCompanyScreenState extends State<CourierCompanyScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _companies = [];

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
      final res = await _api.get('/couriers/companies');
      _companies = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
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
        ? _companies
        : _companies.where((c) => c['name'].toString().toLowerCase().contains(_search.text.trim().toLowerCase())).toList();

    return Scaffold(
      appBar: const ModernAppBar(title: 'কুরিয়ার', subtitle: 'কোম্পানি বাছাই করুন'),
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
                      MaterialPageRoute(builder: (_) => const CourierFormScreen()),
                    ),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('কুরিয়ার যোগ করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyCourierOfficesScreen()),
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('আমার অফিস'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'কোম্পানি সার্চ'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
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
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('কোনো কোম্পানি পাওয়া যায়নি')),
              )
            else
              ...filtered.map((company) {
                final id = (company['id'] as num?)?.toInt() ?? 0;
                final name = company['name'].toString();
                final rating = double.tryParse((company['rating'] ?? '0').toString()) ?? 0;
                final offices = (company['offices_count'] ?? 0).toString();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.local_shipping, color: scheme.primary),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1)),
                        const SizedBox(width: 12),
                        Text('অফিস: $offices'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CourierOfficeListScreen(companyId: id, companyName: name)),
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
