import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
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
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  int _bannerIndex = 0;

  static const List<_HomeBanner> _fallbackBanners = [
    _HomeBanner(
      title:
          '\u09ad\u09cb\u09b2\u09be\u09ac\u09be\u09b8\u09c0 - \u099c\u09c7\u09b2\u09be\u09b0 \u09b8\u09ac \u09b8\u09c7\u09ac\u09be \u098f\u0995 \u0985\u09cd\u09af\u09be\u09aa\u09c7',
      subtitle:
          '\u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8, \u09ae\u09be\u09b0\u09cd\u0995\u09c7\u099f, \u099a\u09be\u0995\u09b0\u09bf, \u09b0\u0995\u09cd\u09a4\u09a6\u09be\u09a8, \u099c\u09b0\u09c1\u09b0\u09bf \u09b8\u09c7\u09ac\u09be',
      imageAsset: 'assets/images/logo_bholavashi_landscape_size.png',
    ),
    _HomeBanner(
      title:
          '\u09b0\u0995\u09cd\u09a4\u09a6\u09be\u09a8 \u0993 \u099c\u09b0\u09c1\u09b0\u09bf \u09b8\u09b9\u09be\u09df\u09a4\u09be \u098f\u0995 \u099c\u09be\u09df\u0997\u09be\u09df',
      subtitle:
          '\u09a6\u09cd\u09b0\u09c1\u09a4 \u09a4\u09a5\u09cd\u09af, \u09a6\u09cd\u09b0\u09c1\u09a4 \u09b8\u09c7\u09ac\u09be',
      imageAsset: 'assets/images/favicon_bholavashi.png',
    ),
    _HomeBanner(
      title:
          '\u0986\u09aa\u09a8\u09be\u09b0 \u09ac\u09cd\u09af\u09ac\u09b8\u09be \u0993 \u09b8\u09c7\u09ac\u09be\u09b0 \u09aa\u09cd\u09b0\u099a\u09be\u09b0 \u09a6\u09bf\u09a8',
      subtitle:
          '\u09b2\u09cb\u0995\u09be\u09b2 \u09ad\u09cb\u0995\u09cd\u09a4\u09be\u09a6\u09c7\u09b0 \u0995\u09be\u099b\u09c7 \u09aa\u09cc\u0981\u099b\u09be\u09a8',
      imageAsset: 'assets/images/logo_bholavashi_squre.png',
    ),
  ];

  List<_HomeBanner> _banners = _fallbackBanners;

  @override
  void initState() {
    super.initState();
    _trackVisit();
    _loadBanners();
  }

  Future<void> _trackVisit() async {
    try {
      await _api.post(
        '/app-visit',
        body: {'source': 'flutter', 'path': 'home'},
      );
    } catch (_) {
      // Analytics must never block the home screen.
    }
  }

  Future<void> _loadBanners() async {
    try {
      final res = await _api.get('/home-banners', auth: false);
      final items = (res as List?)
          ?.whereType<Map>()
          .map((raw) => _HomeBanner.fromJson(Map<String, dynamic>.from(raw)))
          .where((banner) => banner.title.trim().isNotEmpty)
          .take(6)
          .toList();
      if (!mounted || items == null || items.isEmpty) return;
      setState(() {
        _banners = items;
        _bannerIndex = 0;
      });
      if (_bannerController.hasClients) {
        _bannerController.jumpToPage(0);
      }
    } catch (_) {
      // Keep local fallback banners when admin data is unavailable.
    }
  }

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
                MaterialPageRoute(
                  builder: (_) => const NotificationsListScreen(),
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notifier.unreadCount > 99
                            ? '99+'
                            : notifier.unreadCount.toString(),
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
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
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
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
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
                                      style: TextStyle(
                                        color: scheme.onPrimaryContainer
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                    if (banner.buttonText != null &&
                                        banner.buttonText!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        banner.buttonText!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  color: scheme.surface,
                                  padding: const EdgeInsets.all(4),
                                  child: _BannerImage(banner: banner),
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
                          color: active
                              ? scheme.primary
                              : scheme.outlineVariant,
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
              Expanded(
                child: Text(
                  '\u09b8\u09ac \u09b8\u09c7\u09ac\u09be',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ServicesCatalogPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text(
                  '\u09b8\u09ac \u09a6\u09c7\u0996\u09c1\u09a8',
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '\u09a6\u09cd\u09b0\u09c1\u09a4 \u0985\u09cd\u09af\u09be\u0995\u09b6\u09a8',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
                      MaterialPageRoute(
                        builder: (_) => const MarketplaceItemAddScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/blood-donor/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BloodDonorFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/jobs/post') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const JobPostFormScreen(postType: 'hiring'),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/properties/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PropertyPostFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/businesses/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BusinessAddScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/workers/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WorkerAddScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/blood-requests/add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BloodRequestFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/jobs/seeking') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const JobPostFormScreen(postType: 'seeking'),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/doctors/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DoctorProfileFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/hospitals/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HospitalFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/restaurants/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RestaurantFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/hotels/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HotelFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/education/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EducationFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/car-rentals/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CarRentalFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/launches/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LaunchFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/couriers/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CourierFormScreen(),
                      ),
                    );
                    return;
                  }
                  if (action.endpoint == '/teachers/register') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeacherProfileFormScreen(),
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(action.icon, size: 28, color: scheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          action.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
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
          //   label: const Text('\u099c\u09b0\u09c1\u09b0\u09bf \u09a8\u09ae\u09cd\u09ac\u09b0 \u09a6\u09c7\u0996\u09c1\u09a8'),
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
    this.details,
    this.imageUrl,
    this.imageAsset,
    this.link,
    this.buttonText,
  });

  factory _HomeBanner.fromJson(Map<String, dynamic> json) {
    return _HomeBanner(
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? json['details'] ?? ''}',
      details: json['details']?.toString(),
      imageUrl: json['image_url']?.toString(),
      imageAsset: null,
      link: json['link_url']?.toString(),
      buttonText: json['button_text']?.toString(),
    );
  }

  final String title;
  final String subtitle;
  final String? details;
  final String? imageUrl;
  final String? imageAsset;
  final String? link;
  final String? buttonText;
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.banner});

  final _HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    const width = 112.0;
    const height = 76.0;
    final placeholder = SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.campaign_rounded,
        size: 34,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty) {
      return Image.network(
        banner.imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (banner.imageAsset != null && banner.imageAsset!.isNotEmpty) {
      return Image.asset(
        banner.imageAsset!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}
