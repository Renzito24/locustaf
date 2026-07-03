import 'package:flutter/material.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Empleados',
        style: TextStyle(
          fontSize: 24,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
