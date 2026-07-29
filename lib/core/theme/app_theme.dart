import 'package:flutter/material.dart';

class AppTheme {
  static const Color baseSeedColor = Color(0xFF006A5B);
  static const String appFont = 'HindSiliguri';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final seed = ColorScheme.fromSeed(seedColor: baseSeedColor, brightness: brightness);
    final isDark = brightness == Brightness.dark;

    final scheme = seed.copyWith(
      primary: isDark ? const Color(0xFF5FB7A6) : baseSeedColor,
      onPrimary: isDark ? const Color(0xFF0D1B18) : Colors.white,
      primaryContainer: isDark ? const Color(0xFF1B2F2A) : const Color(0xFFCDEFE8),
      onPrimaryContainer: isDark ? const Color(0xFFBFE8DE) : const Color(0xFF00382F),
      secondary: isDark ? const Color(0xFF9CB4AE) : const Color(0xFF0A7A67),
      onSecondary: isDark ? const Color(0xFF121A18) : Colors.white,
      secondaryContainer: isDark ? const Color(0xFF1E2A27) : const Color(0xFFDFF3EE),
      onSecondaryContainer: isDark ? const Color(0xFFD2E5E0) : const Color(0xFF0B3B33),
      tertiary: isDark ? const Color(0xFFD1B184) : const Color(0xFF1C8A75),
      onTertiary: isDark ? const Color(0xFF2A1F12) : Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF2A2418) : null,
      onTertiaryContainer: isDark ? const Color(0xFFF3E5CE) : null,
      surface: isDark ? const Color(0xFF0E1114) : const Color(0xFFF6FAF8),
      onSurface: isDark ? const Color(0xFFE7E2DA) : const Color(0xFF182320),
      surfaceContainerLowest: isDark ? const Color(0xFF0B0D10) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF12161A) : const Color(0xFFFFFFFF),
      surfaceContainer: isDark ? const Color(0xFF171C21) : const Color(0xFFF0F5F3),
      surfaceContainerHigh: isDark ? const Color(0xFF1E242A) : const Color(0xFFE8EFEC),
      surfaceContainerHighest: isDark ? const Color(0xFF262E35) : const Color(0xFFDEE8E5),
      outlineVariant: isDark ? const Color(0xFF2F3941) : const Color(0xFFC2CFCB),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
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
        height: 64,
        indicatorColor: scheme.primaryContainer,
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
              fontWeight: FontWeight.w700,
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
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        labelStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w700,
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
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 18),
        contentTextStyle: TextStyle(fontFamily: appFont, fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(fontFamily: appFont, color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(fontFamily: appFont, color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textTheme: base.textTheme.apply(fontFamily: appFont),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: appFont),
    );
  }
}
