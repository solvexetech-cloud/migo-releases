// migo-business/lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/migo_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MigoBusinessApp());
}

class MigoBusinessApp extends StatelessWidget {
  const MigoBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final locale = LocaleProvider.instance.locale;
        return MaterialApp(
          title: 'MIGO Business',
          debugShowCheckedModeBanner: false,
          theme: MigoTheme.light,
          locale: Locale(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('businesses')
                .where('ownerUid', isEqualTo: snapshot.data!.uid)
                .limit(1)
                .get(),
            builder: (context, bizSnap) {
              if (bizSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!bizSnap.hasData || bizSnap.data!.docs.isEmpty) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No business linked to this account.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bizData = bizSnap.data!.docs.first.data() as Map<String, dynamic>;
              final status = bizData['status']?.toString().toLowerCase().trim() ?? 'pending';

              if (status != 'approved') {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
                          const SizedBox(height: 24),
                          const Text(
                            'Account Under Review',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your business registration is pending admin approval. You will be able to access the dashboard once approved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          OutlinedButton.icon(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return const DashboardScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}