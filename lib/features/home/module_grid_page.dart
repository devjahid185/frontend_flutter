import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import 'module_config.dart';

class ModuleGridPage extends StatelessWidget {
  const ModuleGridPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.modules,
  });

  final String title;
  final String subtitle;
  final List<ReadModule> modules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: ModernAppBar(title: title, subtitle: subtitle),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  child: Icon(Icons.dashboard_customize_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'এই সেকশনে ${modules.length}টি অপশন আছে',
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final module = modules[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openReadModule(context, module),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.primary.withValues(alpha: 0.12),
                              child: Icon(module.icon, size: 18, color: scheme.primary),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(module.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          module.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
