import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'টার্মস ও প্রাইভেসি', subtitle: 'নীতি ও শর্তাবলী'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('টার্মস অফ সার্ভিস', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('ব্যবহার করার আগে শর্তগুলো পড়ুন।', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                Text('প্রাইভেসি পলিসি', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('আপনার তথ্য কীভাবে ব্যবহার হয়, তার সংক্ষিপ্ত বিবরণ।', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}