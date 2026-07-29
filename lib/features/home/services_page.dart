import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import 'module_config.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'সব';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReadModule> get _filtered {
    final q = _searchController.text.trim().toLowerCase();

    return serviceModules.where((module) {
      final matchFilter = _selectedFilter == 'সব' || module.section == _selectedFilter;
      final matchSearch = q.isEmpty ||
          module.title.toLowerCase().contains(q) ||
          module.subtitle.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    return Scaffold(
      appBar: const ModernAppBar(title: 'সার্ভিস', subtitle: 'লোকাল কাজ ও জরুরি সেবা'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'কর্মী বা সেবা খুঁজুন',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['সব', 'সেবা', 'জরুরি'].map((filter) {
              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: _selectedFilter == filter ? scheme.onPrimaryContainer : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _selectedFilter == filter,
                selectedColor: scheme.primaryContainer,
                backgroundColor: scheme.surfaceContainer,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tips_and_updates_outlined, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'দ্রুত বুকিং করতে নিচের শর্টকাট ব্যবহার করুন।',
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.map((module) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(module.icon, color: scheme.primary),
                  ),
                  title: Text(
                    module.title,
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    module.subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openReadModule(context, module),
                ),
              )),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('কোনো সেবা পাওয়া যায়নি', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }
}
