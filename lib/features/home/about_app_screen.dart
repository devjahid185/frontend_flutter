import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'আমাদের সম্পর্কে',
        subtitle: 'Sohoj IT এবং ভোলাবাসী',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _CompanyHero(scheme: scheme),
          const SizedBox(height: 14),
          const _AboutSection(
            title: 'Sohoj IT কারা',
            body:
                'Sohoj IT একটি প্রযুক্তি নির্ভর প্রতিষ্ঠান, যারা স্থানীয় মানুষ, ব্যবসা প্রতিষ্ঠান এবং সেবা প্রদানকারীদের জন্য সহজ, ব্যবহারযোগ্য এবং বিশ্বাসযোগ্য ডিজিটাল সমাধান তৈরি করে। আমাদের লক্ষ্য হলো প্রযুক্তিকে সবার দৈনন্দিন জীবনের কাছাকাছি নিয়ে আসা।',
          ),
          const SizedBox(height: 12),
          const _AboutSection(
            title: 'ভোলাবাসী কী',
            body:
                'ভোলাবাসী হলো Sohoj IT নির্মিত একটি জেলা ভিত্তিক সুপার অ্যাপ। এখানে খাবার অর্ডার, স্থানীয় সেবা, শিক্ষা, স্বাস্থ্য, রক্তদাতা, চাকরি, সম্পত্তি, গাড়ি ভাড়া, হোটেল, রেস্টুরেন্ট, জরুরি তথ্য এবং বিভিন্ন দরকারি সুবিধা এক জায়গায় পাওয়া যায়।',
          ),
          const SizedBox(height: 14),
          _InfoGrid(
            items: const [
              _InfoItem(
                icon: Icons.business_center_rounded,
                title: 'প্রধান প্রতিষ্ঠান',
                value: 'Sohoj IT',
              ),
              _InfoItem(
                icon: Icons.apps_rounded,
                title: 'ডিজিটাল পণ্য',
                value: 'ভোলাবাসী',
              ),
              _InfoItem(
                icon: Icons.location_city_rounded,
                title: 'কাজের ফোকাস',
                value: 'স্থানীয় সেবা',
              ),
              _InfoItem(
                icon: Icons.verified_user_rounded,
                title: 'প্রতিশ্রুতি',
                value: 'নির্ভরযোগ্যতা',
              ),
            ],
            scheme: scheme,
          ),
          const SizedBox(height: 14),
          _FeaturePanel(
            title: 'আমাদের লক্ষ্য',
            items: const [
              'স্থানীয় সেবা খুঁজে পাওয়া আরও সহজ করা',
              'গ্রাহক, ব্যবসায়ী, রেস্টুরেন্ট ও রাইডারদের এক প্ল্যাটফর্মে যুক্ত করা',
              'দ্রুত, নিরাপদ এবং ব্যবহারবান্ধব ডিজিটাল অভিজ্ঞতা তৈরি করা',
              'জেলা ভিত্তিক তথ্য ও সেবাকে আরও সংগঠিত করা',
            ],
            scheme: scheme,
          ),
          const SizedBox(height: 12),
          _FeaturePanel(
            title: 'ভোলাবাসীতে যা পাবেন',
            items: const [
              'ফুড ডেলিভারি এবং অর্ডার ট্র্যাকিং',
              'স্থানীয় সার্ভিস, ব্যবসা ও জরুরি তথ্য',
              'স্বাস্থ্য, শিক্ষা, চাকরি ও কমিউনিটি সেবা',
              'ব্যবসা মালিক ও সার্ভিস প্রোভাইডারদের জন্য ডিজিটাল উপস্থিতি',
            ],
            scheme: scheme,
          ),
          const SizedBox(height: 14),
          _ContactCard(scheme: scheme),
          const SizedBox(height: 14),
          _VersionCard(scheme: scheme),
        ],
      ),
    );
  }
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo_bholavashi_squre.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sohoj IT',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Technology company behind Bholavashi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'মানুষের প্রয়োজনীয় স্থানীয় সেবা, তথ্য এবং ব্যবসাকে একটি সহজ ডিজিটাল প্ল্যাটফর্মে নিয়ে আসাই আমাদের কাজ।',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items, required this.scheme});

  final List<_InfoItem> items;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: scheme.primary, size: 22),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({
    required this.title,
    required this.items,
    required this.scheme,
  });

  final String title;
  final List<String> items;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: scheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent_rounded, color: scheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'যোগাযোগ ও সহায়তা',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ভোলাবাসী সম্পর্কিত সহায়তা, ব্যবসা যুক্ত করা বা কোনো সমস্যার জন্য Help & Support পেজ থেকে আমাদের সাথে যোগাযোগ করুন।',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'ভোলাবাসী অ্যাপ • ভার্সন 1.0.0 • Powered by Sohoj IT',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;
}
