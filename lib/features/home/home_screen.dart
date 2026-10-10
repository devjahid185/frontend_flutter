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
import '../food/food_home_screen.dart';
import '../food/rider_dashboard_screen.dart';
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
  String? _supportWhatsapp;

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
    _loadSupportSettings();
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

  Future<void> _loadSupportSettings() async {
    try {
      final res = await _api.get('/support-settings', auth: false);
      if (res is! Map<String, dynamic> || res['settings'] is! Map) return;
      final settings = Map<String, dynamic>.from(res['settings'] as Map);
      final whatsapp = settings['whatsapp']?.toString().trim();
      if (!mounted || whatsapp == null || whatsapp.isEmpty) return;
      setState(() => _supportWhatsapp = whatsapp);
    } catch (_) {
      // The WhatsApp shortcut is optional; the home screen should still load.
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

  String _normalizeWhatsappNumber(String value) {
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('880')) return digits;
    if (digits.startsWith('0') && digits.length >= 10) {
      return '880${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _openWhatsapp() async {
    final number = _normalizeWhatsappNumber(_supportWhatsapp ?? '');
    if (number.isEmpty) return;

    final message = Uri.encodeComponent('আসসালামু আলাইকুম, সাহায্য দরকার।');
    final appUri = Uri.parse('whatsapp://send?phone=$number&text=$message');
    final webUri = Uri.parse('https://wa.me/$number?text=$message');

    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Fall back to the universal web link below.
    }

    if (!await launchUrl(webUri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp খুলতে সমস্যা হচ্ছে')),
      );
    }
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
            ).colorScheme.outlineVariant.withValues(alpha: 0.28),
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
                            borderRadius: BorderRadius.circular(14),
                            color: scheme.primaryContainer.withValues(
                              alpha: 0.62,
                            ),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.46,
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      banner.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onPrimaryContainer
                                            .withValues(alpha: 0.72),
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
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: scheme.surface.withValues(alpha: 0.78),
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
                MaterialPageRoute(builder: (_) => const ServicesCatalogPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _DeliveryPartnerEntrySection(
            onRestaurant: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FoodOwnerDashboardScreen(),
                ),
              );
            },
            onRider: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
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
      floatingActionButton: (_supportWhatsapp ?? '').trim().isEmpty
          ? null
          : _WhatsAppFab(onPressed: _openWhatsapp),
    );
  }
}

class _WhatsAppFab extends StatelessWidget {
  const _WhatsAppFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'home-whatsapp-support',
      tooltip: 'WhatsApp support',
      elevation: 8,
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onPressed: onPressed,
      child: const _WhatsAppGlyph(),
    );
  }
}

class _WhatsAppGlyph extends StatelessWidget {
  const _WhatsAppGlyph();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.chat_bubble_rounded, size: 30),
        Transform.translate(
          offset: const Offset(0, -1),
          child: const Icon(
            Icons.call_rounded,
            color: Color(0xFF25D366),
            size: 15,
          ),
        ),
      ],
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
    final scheme = Theme.of(context).colorScheme;
    final hasMore = services.length > 8;
    final visible = expanded || !hasMore
        ? services
        : services.take(12).toList();
    const columns = 4;
    const itemHeight = 96.0;
    const rowGap = 12.0;
    const collapsedGridHeight = (itemHeight * 2) + rowGap + 54;
    final expandedRows = (visible.length / columns).ceil();
    final expandedGridHeight =
        (expandedRows * itemHeight) +
        ((expandedRows - 1).clamp(0, 99) * rowGap);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'সব সেবা',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: 10),
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
                                    scheme.surface.withValues(alpha: 0.22),
                                    scheme.surface.withValues(alpha: 0.82),
                                    scheme.surface,
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
    final scheme = Theme.of(context).colorScheme;
    final color = service.color ?? scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(service.module.icon, size: 27, color: color),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: Text(
              service.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPartnerEntrySection extends StatelessWidget {
  const _DeliveryPartnerEntrySection({
    required this.onRestaurant,
    required this.onRider,
  });

  final VoidCallback onRestaurant;
  final VoidCallback onRider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final restaurantCard = _DeliveryPartnerEntryCard(
          icon: Icons.storefront_rounded,
          title: 'রেস্টুরেন্ট',
          subtitle: 'অর্ডার, মেনু, কুপন ও ওয়ালেট ম্যানেজ',
          accent: const Color(0xFFB80F19),
          onTap: onRestaurant,
        );
        final riderCard = _DeliveryPartnerEntryCard(
          icon: Icons.delivery_dining_rounded,
          title: 'রাইডার',
          subtitle: 'রিকোয়েস্ট, KYC, আয় ও ডেলিভারি ট্র্যাকিং',
          accent: const Color(0xFF00765B),
          onTap: onRider,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      color: Color(0xFFB80F19),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'পার্টনার ড্যাশবোর্ড',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'রেস্টুরেন্ট ও রাইডার কাজ দ্রুত শুরু করুন',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              isWide
                  ? Row(
                      children: [
                        Expanded(child: restaurantCard),
                        const SizedBox(width: 12),
                        Expanded(child: riderCard),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(width: double.infinity, child: restaurantCard),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: riderCard),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveryPartnerEntryCard extends StatelessWidget {
  const _DeliveryPartnerEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 15),
            ],
          ),
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
