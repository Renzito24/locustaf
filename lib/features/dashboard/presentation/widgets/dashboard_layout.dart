import 'package:flutter/material.dart';

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
              color: const Color(0xFFF3F4F6),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
