import 'package:flutter/material.dart';

import '../common/animated_bottom_nav_bar.dart';
import 'community_page.dart';
import 'home_screen.dart';
import 'marketplace_page.dart';
import 'profile_page.dart';
import 'services_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    ServicesPage(),
    MarketplacePage(),
    CommunityPage(),
    ProfilePage(),
  ];

  final _items = const [
    AnimatedBottomNavItem(label: 'হোম', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    AnimatedBottomNavItem(label: 'সার্ভিস', icon: Icons.handyman_outlined, activeIcon: Icons.handyman_rounded),
    AnimatedBottomNavItem(label: 'মার্কেট', icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded),
    AnimatedBottomNavItem(label: 'কমিউনিটি', icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded),
    AnimatedBottomNavItem(label: 'প্রোফাইল', icon: Icons.person_outline, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation);
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
    );
  }
}
