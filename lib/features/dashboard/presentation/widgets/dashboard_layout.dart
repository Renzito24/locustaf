import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'sidebar.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCUSTAF'),
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
