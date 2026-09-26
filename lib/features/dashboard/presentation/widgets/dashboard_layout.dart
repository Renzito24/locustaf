import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import 'employee_bottom_nav_bar.dart';
import 'sidebar.dart';

class DashboardLayout extends ConsumerWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppTheme.isMobile(context);

    if (!isMobile) {
      return _DesktopLayout(child: child);
    }

    final role = ref.watch(userRoleProvider);
    if (role == UserRole.employee) {
      final isPushedForm = GoRouterState.of(context).uri.path ==
          RoutePaths.employeeCreateIncidence;
      return _MobileLayout(
        bottomNavigationBar: isPushedForm ? null : const EmployeeBottomNavBar(),
        child: child,
      );
    }

    return _MobileLayout(child: child);
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;

  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Row(
          children: [
            const Sidebar(),
            Expanded(
              child: Container(
                color: AppColors.bgDarkTop.withValues(alpha: 0.5),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const _MobileLayout({required this.child, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      appBar: AppBar(
        backgroundColor: AppColors.sidebar,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
          child: const Text(
            'LOCUSTAF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sidebar,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(child: Sidebar()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: child,
      ),
    );
  }
}
