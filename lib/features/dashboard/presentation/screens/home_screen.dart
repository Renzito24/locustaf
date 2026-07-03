import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Inicio',
        style: TextStyle(
          fontSize: 24,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
