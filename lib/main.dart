import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/analytics/meta_app_events_service.dart';
import 'core/state/notification_manager.dart';
import 'core/state/theme_manager.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/auth_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.ensureInitialized();
  await NotificationService.requestPermissions();
  await MetaAppEventsService.instance.initialize();
  runApp(const DistrictSuperAppBootstrap());
}

class DistrictSuperAppBootstrap extends StatelessWidget {
  const DistrictSuperAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthManager()..initialize()),
        ChangeNotifierProvider(create: (_) => NotificationManager()),
        ChangeNotifierProvider(create: (_) => ThemeManager()..initialize()),
      ],
      child: const DistrictSuperApp(),
    );
  }
}
