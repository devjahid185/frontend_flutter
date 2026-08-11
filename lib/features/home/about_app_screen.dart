import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'অ্যাপ সম্পর্কে',
        subtitle: 'ভার্সন ও তথ্য',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ডিস্ট্রিক্ট সুপার অ্যাপ',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'ভার্সন: 1.0.0',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'জেলা ভিত্তিক সেবা, বাজার, শিক্ষা, স্বাস্থ্য এবং জরুরি তথ্য এক জায়গায়।',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
