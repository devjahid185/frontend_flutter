import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../common/module_navigator.dart';
import '../common/simple_post_screen.dart';
import '../blood/blood_donor_form_screen.dart';
import '../blood/blood_request_form_screen.dart';
import '../car_rental/car_rental_form_screen.dart';
import '../courier/courier_form_screen.dart';
import '../doctor/doctor_profile_form_screen.dart';
import '../education/education_form_screen.dart';
import '../hospital/hospital_form_screen.dart';
import '../hotel/hotel_form_screen.dart';
import '../jobs/job_post_form_screen.dart';
import '../launch_service/launch_form_screen.dart';
import '../property/property_post_form_screen.dart';
import '../restaurant/restaurant_form_screen.dart';
import '../teacher/teacher_profile_form_screen.dart';
import 'module_config.dart';
import 'services_catalog_page.dart';
import 'business_add_screen.dart';
import 'marketplace_item_add_screen.dart';
import 'notifications_list_screen.dart';
import 'worker_add_screen.dart';
import '../../core/state/notification_manager.dart';
import '../auth/auth_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  final List<_HomeBanner> _banners = const [
    _HomeBanner(
      title: 'ভোলাবাসী — জেলার সব সেবা এক অ্যাপে',
      subtitle: 'সার্ভিস, মার্কেট, চাকরি, রক্তদান, জরুরি সেবা',
      image: 'assets/images/logo_bholavashi_landscape_size.png',
      link: null,
    ),
    _HomeBanner(
      title: 'রক্তদান ও জরুরি সহায়তা এক জায়গায়',
      subtitle: 'দ্রুত তথ্য, দ্রুত সেবা',
      image: 'assets/images/favicon_bholavashi.png',
      link: null,
    ),
    _HomeBanner(
      title: 'আপনার ব্যবসা ও সেবার প্রচার দিন',
      subtitle: 'লোকাল ভোক্তাদের কাছে পৌঁছান',
      image: 'assets/images/logo_bholavashi_squre.png',
      link: null,
    ),
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _openBannerLink(String? link) async {
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewServices = homeServiceModules.take(6).toList();
    final auth = context.watch<AuthManager>();
    final notifier = context.watch<NotificationManager>();

    if (auth.isLoggedIn) {
      notifier.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/images/logo_bholavashi_landscape_size.png',
              height: 35,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (notifier.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notifier.unreadCount > 99 ? '99+' : notifier.unreadCount.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: scheme.onError,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (idx) => setState(() => _bannerIndex = idx),
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openBannerLink(banner.link),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: scheme.primaryContainer,
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onPrimaryContainer,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      banner.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.85)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: scheme.surface,
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    banner.image,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_banners.length, (index) {
                      final active = index == _bannerIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: active ? 16 : 6,
                        decoration: BoxDecoration(
                          color: active ? scheme.primary : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
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
                  if (action.endpoint == '/businesses/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BusinessAddScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/workers/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkerAddScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/blood-requests/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BloodRequestFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/jobs/seeking') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobPostFormScreen(postType: 'seeking')),
                    );
                    return;
                  }
                  if (action.endpoint == '/doctors/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DoctorProfileFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/hospitals/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HospitalFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/restaurants/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RestaurantFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/hotels/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HotelFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/education/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EducationFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/car-rentals/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CarRentalFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/launches/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LaunchFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/couriers/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CourierFormScreen()),
                    );
                    return;
                  }
                  if (action.endpoint == '/teachers/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeacherProfileFormScreen()),
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

class _HomeBanner {
  const _HomeBanner({
    required this.title,
    required this.subtitle,
    required this.image,
    this.link,
  });

  final String title;
  final String subtitle;
  final String image;
  final String? link;
}
