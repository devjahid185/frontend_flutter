import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import 'module_config.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emergency = homeServiceModules.firstWhere(
      (m) => m.endpoint == '/emergency',
    );
    final blood = homeServiceModules.firstWhere(
      (m) => m.endpoint == '/blood-donors',
    );

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'কমিউনিটি',
        subtitle: 'খবর, নোটিশ ও জরুরি আপডেট',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: scheme.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'কমিউনিটি সেকশন থেকে স্থানীয় আপডেট দ্রুত জানতে পারবেন।',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...communityModules.map(
            (module) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(module.icon, color: scheme.primary),
                ),
                title: Text(
                  module.title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  module.subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => openReadModule(context, module),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('জরুরি শর্টকাট', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openReadModule(context, emergency),
                  icon: const Icon(Icons.call),
                  label: const Text('জরুরি নম্বর'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openReadModule(context, blood),
                  icon: const Icon(Icons.bloodtype),
                  label: const Text('রক্তদাতা'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
