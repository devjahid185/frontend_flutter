import 'package:flutter/material.dart';

class AnimatedBottomNavItem {
  const AnimatedBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AnimatedBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = currentIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubicEmphasized,
                        top: selected ? -10 : 17,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          scale: selected ? 1.0 : 0.94,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubicEmphasized,
                            width: selected ? 38 : 34,
                            height: selected ? 38 : 34,
                            decoration: BoxDecoration(
                              color: selected
                                  ? activeColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 20,
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubicEmphasized,
                        bottom: 9,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOutCubicEmphasized,
                          offset: selected ? Offset.zero : const Offset(0, 0.2),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                            opacity: selected ? 1 : 0,
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: activeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
