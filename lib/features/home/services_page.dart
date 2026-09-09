import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
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
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const SizedBox(height: 4),
          const Text(
            'সব সেবা সমূহ',
            style: TextStyle(
              color: Color(0xff1f2937),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'প্রয়োজনীয় সেবাটি সার্চ করুন...',
                hintStyle: const TextStyle(
                  color: Color(0xff9ca3af),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xff9ca3af),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xffe5e7eb)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff006a4e)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['সব', 'মার্কেট', 'সেবা', 'জরুরি'].map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    selected: selected,
                    selectedColor: scheme.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? scheme.primary
                          : const Color(0xffe5e7eb),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 118,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpen(service),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe5e7eb)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xffe6f1ee),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    service.icon,
                    size: 22,
                    color: const Color(0xff006a4e),
                  ),
                ),
                const Spacer(),
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1f2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff4b5563),
                    fontSize: 11,
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
