import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/features/common/animated_bottom_nav_bar.dart';

void main() {
  testWidgets('renders and activates the featured Food Delivery action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedIndex = 2;
    const items = [
      AnimatedBottomNavItem(
        label: 'হোম',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      AnimatedBottomNavItem(
        label: 'সার্ভিস',
        icon: Icons.handyman_outlined,
        activeIcon: Icons.handyman,
      ),
      AnimatedBottomNavItem(
        label: 'ফুড',
        icon: Icons.delivery_dining_outlined,
        activeIcon: Icons.delivery_dining,
      ),
      AnimatedBottomNavItem(
        label: 'মার্কেট',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
      ),
      AnimatedBottomNavItem(
        label: 'আরও',
        icon: Icons.menu,
        activeIcon: Icons.menu_open,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) => AnimatedBottomNavBar(
              items: items,
              currentIndex: selectedIndex,
              featuredIndex: 2,
              onTap: (index) => setState(() => selectedIndex = index),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ফুড'), findsOneWidget);
    expect(find.text('কমিউনিটি'), findsNothing);
    expect(find.byIcon(Icons.delivery_dining), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delivery_dining));
    await tester.pump();
    expect(selectedIndex, 2);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(selectedIndex, 0);
  });
}
