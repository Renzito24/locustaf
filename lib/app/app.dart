import 'package:flutter/material.dart';
import '../core/router/app_router.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';

class LocustafApp extends StatelessWidget {
  const LocustafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}