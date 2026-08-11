import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/animated_bottom_nav_bar.dart';
import '../../core/state/notification_manager.dart';
import '../auth/auth_manager.dart';
import 'community_page.dart';
import 'home_screen.dart';
import 'marketplace_page.dart';
import 'more_page.dart';
import 'services_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _exitOpen = false;

  final _pages = const [
    HomeScreen(),
    ServicesPage(),
    MarketplacePage(),
    CommunityPage(),
    MorePage(),
  ];

  final _items = const [
    AnimatedBottomNavItem(
      label: 'হোম',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    AnimatedBottomNavItem(
      label: 'সার্ভিস',
      icon: Icons.handyman_outlined,
      activeIcon: Icons.handyman_rounded,
    ),
    AnimatedBottomNavItem(
      label: 'মার্কেট',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    AnimatedBottomNavItem(
      label: 'কমিউনিটি',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    AnimatedBottomNavItem(
      label: 'আরও',
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_open_rounded,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthManager>();
    final notifier = context.read<NotificationManager>();
    if (auth.isLoggedIn) {
      notifier.startPolling();
    } else {
      notifier.stopPolling();
    }
  }

  @override
  void dispose() {
    context.read<NotificationManager>().stopPolling();
    super.dispose();
  }

  Future<void> _handleExit(BuildContext context) async {
    if (_exitOpen) return;
    _exitOpen = true;
    final shouldExit = await _showExitSheet(context);
    _exitOpen = false;
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool?> _showExitSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.shrink(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Icon(
                      Icons.exit_to_app_rounded,
                      color: scheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'অ্যাপ থেকে বের হতে চান?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'আপনার জরুরি কাজ থাকলে ফিরে আসতে পারবেন।',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: scheme.onSurface,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('না, থাকি'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('হ্যাঁ, বের হই'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleExit(context);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _pages[_currentIndex],
          ),
        ),
        bottomNavigationBar: AnimatedBottomNavBar(
          items: _items,
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }
}
