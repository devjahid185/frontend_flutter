import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import '../common/simple_post_screen.dart';
import 'chat_inbox_screen.dart';
import 'module_config.dart';
import 'marketplace_item_add_screen.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final postActions = quickActions
        .where(
          (a) => a.endpoint == '/items/add' || a.endpoint == '/business/add',
        )
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ModernAppBar(
          title: 'মার্কেটপ্লেস',
          subtitle: 'ক্রয়-বিক্রয় ও ব্যবসা',
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                labelColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                tabs: const [
                  Tab(text: 'ব্রাউজ'),
                  Tab(text: 'পোস্ট'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatInboxScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'মেসেজ ইনবক্স',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'আপনার সব কথোপকথন দেখুন',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: marketplaceModules.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final m = marketplaceModules[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => openReadModule(context, m),
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        m.icon,
                                        color: scheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      m.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...marketplaceModules.map(
                        (m) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(m.icon, color: scheme.primary),
                            ),
                            title: Text(
                              m.title,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              m.subtitle,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                            onTap: () => openReadModule(context, m),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Text(
                          'নতুন আইটেম বা ব্যবসা যোগ করতে নিচের অপশন বেছে নিন।',
                          style: TextStyle(color: scheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...postActions.map(
                        (action) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(action.icon, color: scheme.primary),
                            title: Text(
                              action.title,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              action.subtitle,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                            trailing: const Icon(Icons.edit_note_rounded),
                            onTap: () {
                              if (action.endpoint == '/items/add') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MarketplaceItemAddScreen(),
                                  ),
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SimplePostScreen(
                                    title: action.title,
                                    endpoint: action.endpoint,
                                    fields: action.fields,
                                    useDelete: action.useDelete,
                                    allowImages: action.allowImages,
                                    mediaTargetType: action.mediaTargetType,
                                    mediaSection: action.mediaSection,
                                    mediaResponseKey: action.mediaResponseKey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
