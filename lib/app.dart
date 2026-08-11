import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/state/theme_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_manager.dart';
import 'features/auth/auth_landing_screen.dart';
import 'features/home/main_shell.dart';

class DistrictSuperApp extends StatelessWidget {
  const DistrictSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthManager, ThemeManager>(
      builder: (context, auth, themeManager, child) {
        return MaterialApp(
          title: 'ভোলাবাসী',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeManager.themeMode,
          locale: const Locale('bn', 'BD'),
          supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: auth.isInitialized
              ? (auth.isLoggedIn
                    ? const MainShell()
                    : const AuthLandingScreen())
              : const Scaffold(
                  body: Center(child: LogoLoader(showLabel: true)),
                ),
        );
      },
    );
  }
}
