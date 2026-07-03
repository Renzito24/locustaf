import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Asistencia',
        style: TextStyle(
          fontSize: 24,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
