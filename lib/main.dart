import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/state/theme_manager.dart';
import 'features/auth/auth_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DistrictSuperAppBootstrap());
}

class DistrictSuperAppBootstrap extends StatelessWidget {
  const DistrictSuperAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthManager()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeManager()..initialize()),
      ],
      child: const DistrictSuperApp(),
    );
  }
}
