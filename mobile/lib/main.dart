import 'package:firebase_auth/firebase_auth.dart';
import 'services/location_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/migo_theme.dart';
import 'features/auth/welcome_screen.dart';
import 'features/main/main_shell.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/referral_tracker.dart';
import 'features/onboarding/how_to_use_dialog.dart'; // നമ്മുടെ പുതിയ പോപ്പ്അപ്പ്

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load languages + strings
  await LocaleProvider.instance.init();

  // Initialize push notifications (FCM)
  NotificationService.instance.init();

  // Ads init (skip on web)
  if (!kIsWeb) {
    await AdsService.instance.initialize();
  }

  // Auto-referral tracker
  await ReferralTracker.instance.init();
  
  final uri = Uri.base;
  final ref = uri.queryParameters['ref'];
  if (ref != null && ref.isNotEmpty) {
    await ReferralTracker.instance.saveSharedBy(ref);
  }

  // Deep link handler
  initDeepLinks();

  runApp(const MigoApp());
}

void initDeepLinks() {
  try {
    final appLinks = AppLinks();

    appLinks.getInitialLink().then((uri) {
      if (uri != null) handleDeepLink(uri);
    });

    appLinks.uriLinkStream.listen(
      (uri) => handleDeepLink(uri),
      onError: (err) {
        // Ignore errors
      },
    );
  } catch (e) {
    // Deep links not supported on web
  }
}

Future<void> handleDeepLink(Uri uri) async {
  String? code;

  if (uri.scheme == 'migo' && uri.host == 'ref') {
    if (uri.pathSegments.isNotEmpty) {
      code = uri.pathSegments.first;
    }
  }

  if (uri.scheme == 'https' &&
      uri.host == 'migo-app-3030e.web.app' &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments[0] == 'r') {
    code = uri.pathSegments[1];
  }

  if (code == null && uri.queryParameters.containsKey('ref')) {
    code = uri.queryParameters['ref'];
  }

  if (code != null && code.isNotEmpty) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_referral_code', code.toUpperCase());
  }
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
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
    
    // ആപ്പ് തുറക്കുമ്പോൾ "How to Use" പോപ്പ്അപ്പ് കാണിക്കാൻ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowHowToUse();
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        LocationService.instance.updateUserLocation();
        NotificationService.instance.init();
      } else {
        NotificationService.instance.clearToken();
      }
    });
  }

  Future<void> _checkShowHowToUse() async {
    final prefs = await SharedPreferences.getInstance();
    final neverShow = prefs.getBool('never_show_how_to_use') ?? false;
    
    if (!neverShow) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => HowToUseDialog(
          onClose: () => Navigator.pop(ctx),
        ),
      );
    }
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