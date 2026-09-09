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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sections.map((section) {
                final selected = _selectedSection == section;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      section,
                      style: TextStyle(
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedSection = section),
                    selectedColor: scheme.primary,
                    backgroundColor: scheme.surfaceContainerLow,
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 124,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpen(service),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(service.icon, size: 27, color: scheme.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  service.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
