import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/migo_theme.dart';
import 'features/auth/welcome_screen.dart';
import 'features/main/main_shell.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/ads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load languages + strings (D6-B)
  await LocaleProvider.instance.init();

  // Initialize push notifications (FCM)
  NotificationService.instance.init();

  // D4 — Ads init
  await AdsService.instance.initialize();


  runApp(const MigoApp());
}

class MigoApp extends StatelessWidget {
  const MigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final locale = LocaleProvider.instance.locale;
        final isRtl = LocaleProvider.instance.isRtl;

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: MigoTheme.light,
          darkTheme: MigoTheme.dark,
          themeMode: ThemeMode.system,
          locale: Locale(locale),
          builder: (context, child) {
            // Auto RTL/LTR based on locale
            return Directionality(
              textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService.instance.init();
      } else {
        NotificationService.instance.clearToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const WelcomeScreen();
      },
    );
  }
}