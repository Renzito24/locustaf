import 'package:flutter/material.dart';

class WorkplacesScreen extends StatelessWidget {
  const WorkplacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Lugares de trabajo',
        style: TextStyle(
          fontSize: 24,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
