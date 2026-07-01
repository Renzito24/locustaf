import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';

class LocustafApp extends StatelessWidget {
  const LocustafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
