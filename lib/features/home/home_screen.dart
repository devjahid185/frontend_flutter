import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _bannerInterval = Duration(seconds: 5);

  final PageController _bannerController = PageController(
    viewportFraction: 0.92,
  );
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _bannerInterval,
  );

  int _bannerIndex = 0;
  bool _showAllServices = false;
  bool _userDragging = false;
  bool _wasLoggedIn = false;
  bool _bannersLoaded = false;
  bool _serviceShortcutsLoaded = false;
  bool _fabVisible = true;
  List<_HomeServiceShortcut> _serviceShortcuts = const [];
  String? _supportWhatsapp;

  static const List<_HomeBanner> _fallbackBanners = [
    _HomeBanner(
      title: 'ভোলাবাসী - জেলার সব সেবা এক অ্যাপে',
      subtitle: 'সার্ভিস, মার্কেট, চাকরি, রক্তদান, জরুরি সেবা',
      imageAsset: 'assets/images/logo_bholavashi_landscape_size.png',
    ),
    _HomeBanner(
      title: 'রক্তদান ও জরুরি সহায়তা এক জায়গায়',
      subtitle: 'দ্রুত তথ্য, দ্রুত সেবা',
      imageAsset: 'assets/images/favicon_bholavashi.png',
    ),
    _HomeBanner(
      title: 'আপনার ব্যবসা ও সেবার প্রচার দিন',
      subtitle: 'লোকাল ভোক্তাদের কাছে পৌঁছান',
      imageAsset: 'assets/images/logo_bholavashi_squre.png',
    ),
  ];

  List<_HomeBanner> _banners = _fallbackBanners;

  /// Registration / add forms that have a dedicated screen. Everything that is
  /// not listed here falls back to [SimplePostScreen].
  static final Map<String, Widget Function()> _quickActionForms = {
    '/items/add': () => const MarketplaceItemAddScreen(),
    '/blood-donor/register': () => const BloodDonorFormScreen(),
    '/jobs/post': () => const JobPostFormScreen(postType: 'hiring'),
    '/properties/add': () => const PropertyPostFormScreen(),
    '/businesses/add': () => const BusinessAddScreen(),
    '/workers/add': () => const WorkerAddScreen(),
    '/blood-requests/add': () => const BloodRequestFormScreen(),
    '/jobs/seeking': () => const JobPostFormScreen(postType: 'seeking'),
    '/doctors/register': () => const DoctorProfileFormScreen(),
    '/restaurants/register': () => const RestaurantFormScreen(),
    '/hotels/register': () => const HotelFormScreen(),
    '/car-rentals/register': () => const CarRentalFormScreen(),
    '/launches/register': () => const LaunchFormScreen(),
    '/couriers/register': () => const CourierFormScreen(),
    '/teachers/register': () => const TeacherProfileFormScreen(),
  };

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_onProgressStatus);
    _progress.forward();
    _trackVisit();
    _loadBanners();
    _loadServiceShortcuts();
    _loadSupportSettings();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted || _userDragging || _banners.length < 2) return;
    if (!_bannerController.hasClients) return;
    _bannerController.animateToPage(
      (_bannerIndex + 1) % _banners.length,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
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
      _progress.forward(from: 0);
    } catch (_) {
      // Keep local fallback banners when admin data is unavailable.
    } finally {
      if (mounted && !_bannersLoaded) setState(() => _bannersLoaded = true);
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
      if (!mounted || items == null) return;
      setState(() {
        _serviceShortcuts = items;
        _serviceShortcutsLoaded = true;
      });
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

  Future<void> _refreshAll() async {
    HapticFeedback.lightImpact();
    if (context.read<AuthManager>().isLoggedIn) {
      context.read<NotificationManager>().refresh();
    }
    await Future.wait([
      _loadBanners(),
      _loadServiceShortcuts(),
      _loadSupportSettings(),
    ]);
  }

  @override
  void dispose() {
    _progress.dispose();
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
    // Use the built-in list only when the admin-controlled API could not be
    // loaded. Once it loads successfully, even an empty list is intentional:
    // inactive shortcuts must stay hidden in the app.
    if (!_serviceShortcutsLoaded) {
      return homeServiceModules
          .map((module) => _HomeServiceTile(module: module))
          .toList();
    }

    final ordered = <_HomeServiceTile>[];
    for (final shortcut in _serviceShortcuts) {
      final module = moduleByEndpoint[shortcut.endpoint];
      if (module == null) continue;
      ordered.add(_HomeServiceTile(module: module, shortcut: shortcut));
    }
    // Keep Gas Delivery immediately after Marketplace even when the admin
    // shortcut response provides a different order.
    final gasIndex = ordered.indexWhere(
      (service) => service.module.endpoint == '/gas/home',
    );
    if (gasIndex >= 0) {
      final gas = ordered.removeAt(gasIndex);
      final marketplaceIndex = ordered.indexWhere(
        (service) => service.module.endpoint == '/items',
      );
      if (marketplaceIndex >= 0) {
        ordered.insert(marketplaceIndex + 1, gas);
      } else {
        ordered.add(gas);
      }
    }

    return ordered;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'শুভ রাত্রি';
    if (h < 12) return 'শুভ সকাল';
    if (h < 15) return 'শুভ দুপুর';
    if (h < 18) return 'শুভ বিকাল';
    if (h < 20) return 'শুভ সন্ধ্যা';
    return 'শুভ রাত্রি';
  }

  void _openCatalog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ServicesCatalogPage()));
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n is UserScrollNotification) {
      final show = n.direction != ScrollDirection.reverse;
      if (show != _fabVisible) setState(() => _fabVisible = show);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final services = _orderedHomeServices();
    final loggedIn = context.select<AuthManager, bool>((a) => a.isLoggedIn);
    final unread = context.select<NotificationManager, int>(
      (n) => n.unreadCount,
    );

    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      if (loggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<NotificationManager>().refresh();
        });
      }
    }

    final hasFab = (_supportWhatsapp ?? '').trim().isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        color: scheme.primary,
        edgeOffset: kToolbarHeight,
        onRefresh: _refreshAll,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
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
                  _NotificationBell(
                    count: unread,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: _Entrance(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: _GreetingHeader(greeting: _greeting()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 66,
                  child: _SearchHeader(onTap: _openCatalog),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _Entrance(delay: 80, child: _buildBanners(scheme)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                  child: _Entrance(
                    child: _HomeServicesPanel(
                      services: services,
                      expanded: _showAllServices,
                      onToggle: () =>
                          setState(() => _showAllServices = !_showAllServices),
                      onOpen: (service) =>
                          openReadModule(context, service.module),
                      onOpenCatalog: _openCatalog,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                  child: _Entrance(
                    child: _DeliveryPartnerEntrySection(
                      onRestaurant: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FoodOwnerDashboardScreen(),
                          ),
                        );
                      },
                      onRider: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RiderDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: _Entrance(
                    child: _SectionHeader(
                      title: 'দ্রুত অ্যাকশন',
                      subtitle: 'পোস্ট করুন বা রেজিস্ট্রেশন সম্পন্ন করুন',
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: quickActions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final action = quickActions[index];
                      return SizedBox(
                        width: 166,
                        child: _Entrance(
                          delay: math.min(index, 6) * 60,
                          child: _QuickActionCard(
                            icon: action.icon,
                            title: action.title,
                            subtitle: action.subtitle,
                            onTap: () {
                              final form = _quickActionForms[action.endpoint];
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => form != null
                                      ? form()
                                      : SimplePostScreen(
                                          title: action.title,
                                          endpoint: action.endpoint,
                                          fields: action.fields,
                                          useDelete: action.useDelete,
                                          allowImages: action.allowImages,
                                          mediaTargetType:
                                              action.mediaTargetType,
                                          mediaSection: action.mediaSection,
                                          mediaResponseKey:
                                              action.mediaResponseKey,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Entrance(child: _HomeFooter(hasFab: hasFab)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hasFab
          ? Padding(
              // MainShell uses an overlaid floating navigation dock. Keep the
              // page-level FAB above that dock on every tab and safe area.
              padding: const EdgeInsets.only(bottom: 112),
              child: IgnorePointer(
                ignoring: !_fabVisible,
                child: AnimatedSlide(
                  offset: _fabVisible ? Offset.zero : const Offset(0, 3),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: _WhatsAppFab(onPressed: _openWhatsapp),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBanners(ColorScheme scheme) {
    if (!_bannersLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 21),
        child: _SkeletonBox(height: 172, radius: 26),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis != Axis.horizontal) return false;
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _userDragging = true;
                _progress.stop();
              } else if (n is ScrollEndNotification && _userDragging) {
                _userDragging = false;
                _progress.forward(from: 0);
              }
              return false;
            },
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              onPageChanged: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _bannerIndex = idx);
                if (!_userDragging) _progress.forward(from: 0);
              },
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return AnimatedBuilder(
                  animation: _bannerController,
                  builder: (context, child) {
                    double page = _bannerIndex.toDouble();
                    if (_bannerController.hasClients &&
                        _bannerController.position.haveDimensions) {
                      page = _bannerController.page ?? page;
                    }
                    final delta = (page - index).clamp(-1.0, 1.0).toDouble();
                    return Transform.scale(
                      scale: 1 - 0.07 * delta.abs(),
                      child: _BannerCard(
                        banner: banner,
                        parallax: delta,
                        onTap: () => _openBannerLink(banner.link),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 14),
          _SegmentedProgress(
            count: _banners.length,
            index: _bannerIndex,
            progress: _progress,
            onSelect: (i) => _bannerController.animateToPage(
              i,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ],
    );
  }
}

/* ===========================================================================
   Shared animation helpers
   =========================================================================== */

/// Fade + slide-up entrance. Runs when the element is first built, which for
/// a lazily built sliver means right as the section scrolls close to view.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = 560 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
    );
  }
}

/// Press-to-shrink surface with ripple and a light haptic tick.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onTap,
    required this.child,
    this.radius = 18,
    this.color,
    this.border,
    this.scale = 0.96,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final Color? color;
  final BorderSide? border;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      side: widget.border ?? BorderSide.none,
    );
    return AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.color ?? Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onHighlightChanged: (v) => setState(() => _down = v),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Flat skeleton block that pulses while content loads.
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.height, this.radius = 16});

  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: scheme.onSurface.withValues(alpha: 0.05 + 0.06 * t),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/* ===========================================================================
   Header pieces
   =========================================================================== */

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                greeting,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'আজ কোন সেবা দরকার?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// Search pill displayed below the greeting.
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _Pressable(
        onTap: onTap,
        radius: 18,
        scale: 0.985,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'সেবা খুঁজুন...',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(covariant _NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.count;
    return IconButton(
      tooltip: 'নোটিফিকেশন',
      onPressed: widget.onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              final angle = math.sin(t * math.pi * 6) * (1 - t) * 0.4;
              return Transform.rotate(
                angle: angle,
                alignment: Alignment.topCenter,
                child: child,
              );
            },
            child: Icon(
              count > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: AnimatedScale(
              scale: count > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: scheme.onError,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===========================================================================
   Banner
   =========================================================================== */

/// Story-style progress: finished banners are full, the current one fills over
/// the auto-play interval, the rest are empty.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.count,
    required this.index,
    required this.progress,
    required this.onSelect,
  });

  final int count;
  final int index;
  final Animation<double> progress;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 40.0 * count + 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            return Row(
              children: List.generate(count, (i) {
                final fill = i < index
                    ? 1.0
                    : i == index
                    ? progress.value
                    : 0.0;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.5,
                        vertical: 6,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          height: 4,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fill,
                                  child: ColoredBox(color: scheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.parallax,
    required this.onTap,
  });

  final _HomeBanner banner;
  final double parallax;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasButton =
        banner.buttonText != null && banner.buttonText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: _Pressable(
        onTap: onTap,
        radius: 26,
        scale: 0.98,
        color: scheme.primary,
        child: Stack(
          children: [
            // Flat decorative shapes that drift slightly while swiping.
            Positioned(
              right: -40 - parallax * 26,
              top: -50,
              child: _Disc(size: 180, color: scheme.onPrimary, alpha: 0.08),
            ),
            Positioned(
              right: 70 + parallax * 18,
              bottom: -60,
              child: _Disc(size: 130, color: scheme.onPrimary, alpha: 0.06),
            ),
            Positioned(
              left: -30 + parallax * 14,
              bottom: -36,
              child: _Disc(size: 90, color: scheme.onPrimary, alpha: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
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
                            color: scheme.onPrimary,
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onPrimary.withValues(alpha: 0.86),
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasButton) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    banner.buttonText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset: Offset(parallax * -16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _BannerImage(banner: banner),
                      ),
                    ),
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

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

/* ===========================================================================
   Floating WhatsApp button
   =========================================================================== */

class _WhatsAppFab extends StatefulWidget {
  const _WhatsAppFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_WhatsAppFab> createState() => _WhatsAppFabState();
}

class _WhatsAppFabState extends State<_WhatsAppFab>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF25D366);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _pulse.isAnimating) _pulse.stop();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!reduce)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(_pulse.value);
                  return Container(
                    width: 56 + 20 * t,
                    height: 56 + 20 * t,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18 + 8 * t),
                      color: _green.withValues(alpha: 0.28 * (1 - t)),
                    ),
                  );
                },
              ),
            FloatingActionButton(
              heroTag: 'home-whatsapp-support',
              tooltip: 'WhatsApp support',
              elevation: 6,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              child: const _WhatsAppGlyph(),
            ),
          ],
        ),
      ),
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

/* ===========================================================================
   Data models (unchanged behaviour)
   =========================================================================== */

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

Color _serviceAccent(_HomeServiceTile service, Color fallback) {
  final custom = service.color;
  if (custom != null) return custom;
  switch (service.module.endpoint) {
    case '/food/home':
      return const Color(0xFFE85D3F);
    case '/medicine/home':
      return const Color(0xFF1E9B72);
    case '/gas/home':
      return const Color(0xFFE28A24);
    case '/blood-donors':
      return const Color(0xFFD64550);
    case '/workers':
      return const Color(0xFF2979A8);
    case '/businesses':
      return const Color(0xFF6D5BD0);
    case '/items':
      return const Color(0xFF008E91);
    case '/jobs':
      return const Color(0xFF3A6EA5);
    case '/properties':
      return const Color(0xFF9A6B3F);
    default:
      return fallback;
  }
}

/* ===========================================================================
   Services
   =========================================================================== */

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

  static const int _collapsedGridCount = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasMore = services.length > _collapsedGridCount;
    final visible = expanded || !hasMore
        ? services
        : services.take(_collapsedGridCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'আপনার প্রয়োজনীয় সেবা',
                subtitle: 'সহজে সেবা বেছে নিন',
              ),
            ),
            TextButton.icon(
              onPressed: onOpenCatalog,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 17),
              label: const Text('সব সেবা'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (visible.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final cardWidth = (constraints.maxWidth - gap) / 2;
                return Column(
                  children: [
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final service in visible)
                          SizedBox(
                            width: cardWidth,
                            height: 148,
                            child: _ServiceGridItem(
                              service: service,
                              onTap: () => onOpen(service),
                            ),
                          ),
                      ],
                    ),
                    if (hasMore) ...[
                      const SizedBox(height: 14),
                      _MoreServicesButton(
                        expanded: expanded,
                        hiddenCount: services.length - _collapsedGridCount,
                        onPressed: onToggle,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MoreServicesButton extends StatelessWidget {
  const _MoreServicesButton({
    required this.expanded,
    required this.hiddenCount,
    required this.onPressed,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Pressable(
      onTap: onPressed,
      radius: 16,
      scale: 0.95,
      color: scheme.primary.withValues(alpha: 0.08),
      child: Container(
        constraints: const BoxConstraints(minWidth: 160, minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                expanded ? 'কম দেখুন' : 'আরো $hiddenCount টি সেবা',
                key: ValueKey(expanded),
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 320),
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
    );
  }
}

/// Two-column service card with a stable, non-animated layout.
class _ServiceGridItem extends StatelessWidget {
  const _ServiceGridItem({required this.service, required this.onTap});

  final _HomeServiceTile service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _serviceAccent(service, scheme.primary);

    return _Pressable(
      onTap: onTap,
      radius: 18,
      scale: 0.97,
      color: color.withValues(alpha: 0.06),
      border: BorderSide(color: color.withValues(alpha: 0.2)),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(service.module.icon, size: 25, color: color),
                ),
                const Spacer(),
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              service.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              service.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================================================================
   Partner dashboards
   =========================================================================== */

class _DeliveryPartnerEntrySection extends StatelessWidget {
  const _DeliveryPartnerEntrySection({
    required this.onRestaurant,
    required this.onRider,
  });

  final VoidCallback onRestaurant;
  final VoidCallback onRider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final restaurantCard = _DeliveryPartnerEntryCard(
          icon: Icons.storefront_rounded,
          title: 'রেস্টুরেন্ট',
          subtitle: 'অর্ডার, মেনু, কুপন ও ওয়ালেট ম্যানেজ',
          accent: const Color(0xFFB80F19),
          onTap: onRestaurant,
        );
        final riderCard = _DeliveryPartnerEntryCard(
          icon: Icons.delivery_dining_rounded,
          title: 'রাইডার',
          subtitle: 'রিকোয়েস্ট, KYC, আয় ও ডেলিভারি ট্র্যাকিং',
          accent: const Color(0xFF00765B),
          onTap: onRider,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      color: scheme.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'পার্টনার ড্যাশবোর্ড',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'রেস্টুরেন্ট ও রাইডার কাজ দ্রুত শুরু করুন',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
    final scheme = Theme.of(context).colorScheme;

    return _Pressable(
      onTap: onTap,
      radius: 18,
      color: accent.withValues(alpha: 0.06),
      border: BorderSide(color: accent.withValues(alpha: 0.2)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================================================================
   Quick actions
   =========================================================================== */

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Pressable(
      onTap: onTap,
      radius: 22,
      color: scheme.surface,
      border: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: scheme.primary),
                ),
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 17,
                    color: scheme.onPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontSize: 11.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================================================================
   Footer
   =========================================================================== */

class _HomeFooter extends StatelessWidget {
  const _HomeFooter({required this.hasFab});

  final bool hasFab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 34, 24, hasFab ? 110 : 40),
      child: Column(
        children: [
          Opacity(
            opacity: 0.55,
            child: Image.asset(
              'assets/images/logo_bholavashi_landscape_size.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'আপনার জেলার সব সেবা, এক অ্যাপে',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* ===========================================================================
   Banner model + image
   =========================================================================== */

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
    const width = 104.0;
    const height = 92.0;
    final placeholder = SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.campaign_rounded,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty) {
      return Image.network(
        banner.imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            child: child,
          );
        },
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
