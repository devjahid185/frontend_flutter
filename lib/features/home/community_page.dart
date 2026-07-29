import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import 'module_config.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emergency = homeServiceModules.firstWhere((m) => m.endpoint == '/emergency');
    final blood = homeServiceModules.firstWhere((m) => m.endpoint == '/blood-donors');

    return Scaffold(
      appBar: const ModernAppBar(title: 'কমিউনিটি', subtitle: 'খবর, নোটিশ ও জরুরি আপডেট'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.campaign_rounded, color: scheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'কমিউনিটি সেকশন থেকে স্থানীয় আপডেট দ্রুত জানতে পারবেন।',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...communityModules.map((module) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
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
