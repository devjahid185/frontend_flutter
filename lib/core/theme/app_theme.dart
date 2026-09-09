import 'package:flutter/material.dart';

class AppTheme {
  static const Color baseSeedColor = Color(0xFF007A5E);
  static const String appFont = 'HindSiliguri';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final seed = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    final scheme = seed.copyWith(
      primary: isDark ? const Color(0xFF54C2AB) : baseSeedColor,
      onPrimary: isDark ? const Color(0xFF0D1B18) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF12352E)
          : const Color(0xFFE3F3EE),
      onPrimaryContainer: isDark
          ? const Color(0xFFBFE8DE)
          : const Color(0xFF00382F),
      secondary: isDark ? const Color(0xFF9CB4AE) : const Color(0xFF117960),
      onSecondary: isDark ? const Color(0xFF121A18) : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF1E2A27)
          : const Color(0xFFF0FAF7),
      onSecondaryContainer: isDark
          ? const Color(0xFFD2E5E0)
          : const Color(0xFF0B3B33),
      tertiary: isDark ? const Color(0xFFD1B184) : const Color(0xFFFF9F1C),
      onTertiary: isDark ? const Color(0xFF2A1F12) : Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF2A2418) : null,
      onTertiaryContainer: isDark ? const Color(0xFFF3E5CE) : null,
      surface: isDark ? const Color(0xFF0E1114) : const Color(0xFFF5F8F7),
      onSurface: isDark ? const Color(0xFFE7E2DA) : const Color(0xFF172330),
      surfaceContainerLowest: isDark
          ? const Color(0xFF0B0D10)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark
          ? const Color(0xFF12161A)
          : const Color(0xFFFFFFFF),
      surfaceContainer: isDark
          ? const Color(0xFF171C21)
          : const Color(0xFFF0F5F3),
      surfaceContainerHigh: isDark
          ? const Color(0xFF1E242A)
          : const Color(0xFFEAF2EF),
      surfaceContainerHighest: isDark
          ? const Color(0xFF262E35)
          : const Color(0xFFE2ECE8),
      outlineVariant: isDark
          ? const Color(0xFF2F3941)
          : const Color(0xFFD8E3DF),
      shadow: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: appFont,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: appFont,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
        toolbarTextStyle: TextStyle(
          fontFamily: appFont,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        height: 62,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.72),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: appFont,
            );
          }
          return TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: appFont,
          );
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer.withValues(alpha: 0.72),
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.34)),
        labelStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        titleTextStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: appFont,
          color: scheme.onSurfaceVariant,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: appFont,
          fontSize: 14,
          color: scheme.onSurfaceVariant,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: appFont,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: appFont,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: appFont,
            fontWeight: FontWeight.w500,
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 12),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(
          fontFamily: appFont,
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          fontFamily: appFont,
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
        ),
      ),
      textTheme: base.textTheme
          .apply(fontFamily: appFont, bodyColor: scheme.onSurface)
          .copyWith(
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontFamily: appFont,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.12,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamily: appFont,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.18,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontFamily: appFont,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontFamily: appFont,
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: appFont),
    );
  }
}
