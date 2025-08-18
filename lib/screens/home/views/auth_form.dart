import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final String toggleText;
  final VoidCallback onToggle;

  const AuthForm({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.toggleText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  child: Text(buttonLabel),
                ),
              ),
              TextButton(
                onPressed: onToggle,
                child: Text(toggleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
