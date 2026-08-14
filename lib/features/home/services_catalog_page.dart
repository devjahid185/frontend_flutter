import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import 'module_config.dart';

class ServicesCatalogPage extends StatefulWidget {
  const ServicesCatalogPage({super.key});

  @override
  State<ServicesCatalogPage> createState() => _ServicesCatalogPageState();
}

class _ServicesCatalogPageState extends State<ServicesCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSection = 'সব';

  static const List<String> _sections = [
    'সব',
    'সেবা',
    'মার্কেট',
    'জরুরি',
    'কমিউনিটি',
    'ক্যারিয়ার',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReadModule> get _filtered {
    final query = _searchController.text.trim().toLowerCase();

    return homeServiceModules.where((service) {
      final matchesSection =
          _selectedSection == 'সব' || service.section == _selectedSection;
      final matchesSearch =
          query.isEmpty ||
          service.title.toLowerCase().contains(query) ||
          service.subtitle.toLowerCase().contains(query);
      return matchesSection && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final services = _filtered;

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'সব সেবা',
        subtitle: 'সার্চ ও ফিল্টার করুন',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'সেবা খুঁজুন',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sections.map((section) {
              final selected = _selectedSection == section;
              return ChoiceChip(
                label: Text(
                  section,
                  style: TextStyle(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSection = section),
                selectedColor: scheme.primaryContainer,
                backgroundColor: scheme.surfaceContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'মোট সেবা: ${services.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          _ServiceShortcutGrid(
            services: services,
            onOpen: (service) => openReadModule(context, service),
          ),
          if (services.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
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
