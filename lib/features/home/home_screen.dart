import 'dart:ui' show ImageFilter;

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
  bool _showAllServices = false;
  List<_HomeServiceShortcut> _serviceShortcuts = const [];

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
    _loadServiceShortcuts();
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

  Future<void> _loadServiceShortcuts() async {
    try {
      final res = await _api.get('/home-service-shortcuts', auth: false);
      final items = (res as List?)
          ?.whereType<Map>()
          .map(
            (raw) =>
                _HomeServiceShortcut.fromJson(Map<String, dynamic>.from(raw)),
          )
          .where((item) => item.endpoint.trim().isNotEmpty)
          .toList();
      if (!mounted || items == null || items.isEmpty) return;
      setState(() => _serviceShortcuts = items);
    } catch (_) {
      // Keep the built-in order if admin shortcut settings cannot be loaded.
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

  List<_HomeServiceTile> _orderedHomeServices() {
    final moduleByEndpoint = {
      for (final module in homeServiceModules) module.endpoint: module,
    };
    moduleByEndpoint['/medicine'] = moduleByEndpoint['/medicine/home']!;
    if (_serviceShortcuts.isEmpty) {
      return homeServiceModules
          .map((module) => _HomeServiceTile(module: module))
          .toList();
    }

    final ordered = <_HomeServiceTile>[];
    final used = <String>{};
    for (final shortcut in _serviceShortcuts) {
      final module = moduleByEndpoint[shortcut.endpoint];
      if (module == null) continue;
      used.add(module.endpoint);
      ordered.add(_HomeServiceTile(module: module, shortcut: shortcut));
    }
    for (final module in homeServiceModules) {
      if (!used.contains(module.endpoint)) {
        ordered.add(_HomeServiceTile(module: module));
      }
    }

    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final services = _orderedHomeServices();
    final auth = context.watch<AuthManager>();
    final notifier = context.watch<NotificationManager>();
    final bloodModule = homeServiceModules.firstWhere(
      (module) => module.endpoint == '/blood-donors',
    );

    if (auth.isLoggedIn) {
      notifier.refresh();
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          children: [
            _HomeTopBar(
              unreadCount: notifier.unreadCount,
              onNotifications: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: TextField(
                readOnly: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ServicesCatalogPage(),
                    ),
                  );
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'কি খুঁজছেন?',
                  hintStyle: const TextStyle(
                    color: Color(0xff9ca3af),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xff9ca3af),
                  ),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffe5e7eb)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff006a4e)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 338,
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
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _openBannerLink(banner.link),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _HeroBannerImage(banner: banner),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.62),
                                        Colors.black.withValues(alpha: 0.18),
                                        Colors.black.withValues(alpha: 0.04),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9F1C),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'অফার',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        banner.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          height: 1.04,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        banner.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.86,
                                          ),
                                          fontSize: 13,
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
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
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
                                ? scheme.primary.withValues(alpha: 0.74)
                                : scheme.outlineVariant.withValues(alpha: 0.72),
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
            _HomeServicesPanel(
              services: services,
              expanded: _showAllServices,
              onToggle: () =>
                  setState(() => _showAllServices = !_showAllServices),
              onOpen: (service) => openReadModule(context, service.module),
              onOpenCatalog: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ServicesCatalogPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _HomeBloodCta(onTap: () => openReadModule(context, bloodModule)),
            const SizedBox(height: 16),
            Text(
              '\u09a6\u09cd\u09b0\u09c1\u09a4 \u0985\u09cd\u09af\u09be\u0995\u09b6\u09a8',
              style: const TextStyle(
                color: Color(0xff1f2937),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
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
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.82,
                              ),
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
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.unreadCount, required this.onNotifications});

  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ভোলাবাসী',
                style: const TextStyle(
                  color: Color(0xff006a4e),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xff4b5563),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ভোলা, বাংলাদেশ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xff4b5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onNotifications,
            color: const Color(0xff1f2937),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unreadCount > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xffef4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBloodCta extends StatelessWidget {
  const _HomeBloodCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffe6f1ee),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: Color(0xff006a4e),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'জরুরী রক্তদান সেবা',
                      style: TextStyle(
                        color: Color(0xff006a4e),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ভোলার যেকোনো হাসপাতালে রক্তদাতার সন্ধান পান মুহূর্তেই',
                      style: TextStyle(
                        color: Color(0xff4b5563),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeServiceShortcut {
  const _HomeServiceShortcut({
    required this.title,
    required this.endpoint,
    this.subtitle,
    this.accentColor,
  });

  final String title;
  final String endpoint;
  final String? subtitle;
  final Color? accentColor;

  factory _HomeServiceShortcut.fromJson(Map<String, dynamic> json) {
    return _HomeServiceShortcut(
      title: '${json['title'] ?? ''}',
      subtitle: json['subtitle']?.toString(),
      endpoint: '${json['endpoint'] ?? ''}',
      accentColor: _parseColor(json['accent_color']?.toString()),
    );
  }

  static Color? _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final hex = value.trim().replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}

class _HomeServiceTile {
  const _HomeServiceTile({required this.module, this.shortcut});

  final ReadModule module;
  final _HomeServiceShortcut? shortcut;

  String get title {
    final custom = shortcut?.title.trim();
    return custom == null || custom.isEmpty ? module.title : custom;
  }

  String get subtitle {
    final custom = shortcut?.subtitle?.trim();
    return custom == null || custom.isEmpty ? module.subtitle : custom;
  }

  Color? get color => shortcut?.accentColor;
}

class _HomeServicesPanel extends StatelessWidget {
  const _HomeServicesPanel({
    required this.services,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onOpenCatalog,
  });

  final List<_HomeServiceTile> services;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<_HomeServiceTile> onOpen;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final hasMore = services.length > 6;
    final visible = expanded || !hasMore ? services : services.take(6).toList();
    const columns = 3;
    const itemHeight = 94.0;
    const rowGap = 12.0;
    const collapsedGridHeight = (itemHeight * 2) + rowGap;
    final expandedRows = (visible.length / columns).ceil();
    final expandedGridHeight =
        (expandedRows * itemHeight) +
        ((expandedRows - 1).clamp(0, 99) * rowGap);

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'জনপ্রিয় সেবাসমূহ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xff1f2937),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenCatalog,
                icon: const Icon(Icons.grid_view_rounded, size: 17),
                label: const Text('সব সেবা'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            alignment: Alignment.topCenter,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: expanded || !hasMore
                  ? expandedGridHeight.toDouble()
                  : collapsedGridHeight,
              child: ClipRect(
                child: Stack(
                  children: [
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisExtent: itemHeight,
                            mainAxisSpacing: rowGap,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) {
                        final service = visible[index];
                        return _HomeServiceButton(
                          service: service,
                          onTap: () => onOpen(service),
                        );
                      },
                    ),
                    if (hasMore && !expanded) ...[
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 104,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.6, sigmaY: 2.6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(
                                      0xfff4f7f6,
                                    ).withValues(alpha: 0.22),
                                    const Color(
                                      0xfff4f7f6,
                                    ).withValues(alpha: 0.82),
                                    const Color(0xfff4f7f6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: Center(
                          child: _MoreServicesButton(
                            expanded: false,
                            onPressed: onToggle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (hasMore && expanded) ...[
            const SizedBox(height: 12),
            _MoreServicesButton(expanded: true, onPressed: onToggle),
          ],
        ],
      ),
    );
  }
}

class _MoreServicesButton extends StatelessWidget {
  const _MoreServicesButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: expanded ? 0 : 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 132, minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.48),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                expanded ? 'কম দেখুন' : 'আরো দেখুন',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeServiceButton extends StatelessWidget {
  const _HomeServiceButton({required this.service, required this.onTap});

  final _HomeServiceTile service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = service.color ?? const Color(0xff006a4e);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe5e7eb)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(service.module.icon, size: 21, color: color),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: Text(
                service.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff1f2937),
                  fontSize: 11.5,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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

class _HeroBannerImage extends StatelessWidget {
  const _HeroBannerImage({required this.banner});

  final _HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty) {
      return Image.network(
        banner.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(scheme),
      );
    }
    if (banner.imageAsset != null && banner.imageAsset!.isNotEmpty) {
      return Container(
        color: scheme.primary,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(22),
        child: Image.asset(
          banner.imageAsset!,
          width: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallback(scheme),
        ),
      );
    }
    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, const Color(0xFF0E8F75)],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Icon(
            Icons.local_offer_rounded,
            size: 96,
            color: Colors.white.withValues(alpha: 0.24),
          ),
        ),
      ),
    );
  }
}
