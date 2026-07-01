import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      errorMessage = null;
    });

    // VALIDACIONES
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Completa todos los campos";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = "La contraseña debe tener al menos 6 caracteres";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    // SIMULACIÓN LOGIN
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });

      // 🔥 ACA ESTÁ EL CAMBIO IMPORTANTE
      context.go('/dashboard');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login válido (simulado)")),
      );
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "LOCUSTAF",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              // ERROR MESSAGE
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Iniciar sesión"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}