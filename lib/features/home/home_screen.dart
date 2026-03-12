import 'package:flutter/material.dart';

import '../common/module_navigator.dart';
import '../common/modern_app_bar.dart';
import '../common/simple_post_screen.dart';
import '../blood/blood_donor_form_screen.dart';
import '../jobs/job_post_form_screen.dart';
import '../property/property_post_form_screen.dart';
import 'module_config.dart';
import 'services_catalog_page.dart';
import 'marketplace_item_add_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewServices = homeServiceModules.take(6).toList();
    final emergencyModule = homeServiceModules.firstWhere((m) => m.endpoint == '/emergency');

    return Scaffold(
      appBar: ModernAppBar(
        title: 'জেলা সুপার অ্যাপ',
        subtitle: 'সব সেবা এক জায়গায়',
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.primaryContainer,
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আপনার জেলার সব সেবা এক অ্যাপে',
                  style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'কর্মী, মার্কেটপ্লেস, চাকরি, রক্তদাতা, জরুরি নম্বর দ্রুত ব্যবহার করুন।',
                  style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('সব সেবা', style: Theme.of(context).textTheme.titleLarge)),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServicesCatalogPage()));
                },
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('সব দেখুন'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final service = previewServices[index];
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
          const SizedBox(height: 16),
          Text('দ্রুত অ্যাকশন', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (action.endpoint == '/items/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketplaceItemAddScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/blood-donor/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BloodDonorFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/jobs/post') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobPostFormScreen(postType: 'hiring')),
                    );
                    return;
                  }
                  if (action.endpoint == '/properties/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PropertyPostFormScreen()),
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(action.icon, size: 28, color: scheme.primary),
                        const SizedBox(height: 12),
                        Text(action.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          action.subtitle,
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
          const SizedBox(height: 14),
          // OutlinedButton.icon(
          //   onPressed: () => openReadModule(context, emergencyModule),
          //   icon: const Icon(Icons.call),
          //   label: const Text('জরুরি নম্বর দেখুন'),
          // ),
        ],
      ),
    );
  }
}
