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

  static const List<String> _sections = ['সব', 'সেবা', 'মার্কেট', 'জরুরি', 'কমিউনিটি', 'ক্যারিয়ার'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReadModule> get _filtered {
    final query = _searchController.text.trim().toLowerCase();

    return homeServiceModules.where((service) {
      final matchesSection = _selectedSection == 'সব' || service.section == _selectedSection;
      final matchesSearch = query.isEmpty ||
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
      appBar: const ModernAppBar(title: 'সব সেবা', subtitle: 'সার্চ ও ফিল্টার করুন'),
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
                    color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
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
          Text('মোট সেবা: ${services.length}', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => openReadModule(context, service),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(service.icon, size: 24, color: scheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          service.title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (services.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('কোনো সেবা পাওয়া যায়নি', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }
}
