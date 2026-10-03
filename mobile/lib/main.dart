import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/migo_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const MigoApp());
}

class MigoApp extends StatelessWidget {
  const MigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: MigoTheme.light,
      darkTheme: MigoTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}