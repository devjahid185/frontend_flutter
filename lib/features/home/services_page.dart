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
      final matchFilter =
          _selectedFilter == 'সব' || module.section == _selectedFilter;
      final matchSearch =
          q.isEmpty ||
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
      appBar: const ModernAppBar(
        title: 'সার্ভিস',
        subtitle: 'লোকাল কাজ ও জরুরি সেবা',
      ),
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
                    color: _selectedFilter == filter
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _selectedFilter == filter,
                selectedColor: scheme.primaryContainer.withValues(alpha: 0.68),
                backgroundColor: scheme.surfaceContainerLow,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
          _ServiceShortcutGrid(
            services: filtered,
            onOpen: (module) => openReadModule(context, module),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'কোনো সেবা পাওয়া যায়নি',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceShortcutGrid extends StatelessWidget {
  const _ServiceShortcutGrid({required this.services, required this.onOpen});

  final List<ReadModule> services;
  final ValueChanged<ReadModule> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 96,
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpen(service),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(service.icon, size: 27, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: Text(
                    service.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
