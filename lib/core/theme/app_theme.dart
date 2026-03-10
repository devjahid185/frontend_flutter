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
      primary: isDark ? const Color(0xFF4FD1B3) : baseSeedColor,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF113B34) : const Color(0xFFCDEFE8),
      onPrimaryContainer: isDark ? const Color(0xFFCFF7EF) : const Color(0xFF00382F),
      secondary: isDark ? const Color(0xFF66C9B4) : const Color(0xFF0A7A67),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF173E38) : const Color(0xFFDFF3EE),
      onSecondaryContainer: isDark ? const Color(0xFFD7F7F0) : const Color(0xFF0B3B33),
      tertiary: isDark ? const Color(0xFF82DCC9) : const Color(0xFF1C8A75),
      onTertiary: Colors.white,
      surface: isDark ? const Color(0xFF0D1513) : const Color(0xFFF6FAF8),
      onSurface: isDark ? const Color(0xFFE6EFEC) : const Color(0xFF182320),
      surfaceContainerLowest: isDark ? const Color(0xFF0A100F) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF131D1B) : const Color(0xFFFFFFFF),
      surfaceContainer: isDark ? const Color(0xFF172422) : const Color(0xFFF0F5F3),
      surfaceContainerHigh: isDark ? const Color(0xFF1C2A27) : const Color(0xFFE8EFEC),
      surfaceContainerHighest: isDark ? const Color(0xFF223330) : const Color(0xFFDEE8E5),
      outlineVariant: isDark ? const Color(0xFF3A4C48) : const Color(0xFFC2CFCB),
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
