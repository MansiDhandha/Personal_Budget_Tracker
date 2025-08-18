import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'home_screen.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:budget_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // Load stored email on startup
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }
  }

  void _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save login timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'login_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Save email (acts like a cookie)
      await prefs.setString('saved_email', emailController.text.trim());

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) =>
              GetExpensesBloc(FirebaseExpenseRepo())..add(GetExpenses()),
              child: const HomeScreen(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _login,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primary,
                                theme.secondary,
                                theme.tertiary,
                              ],
                              transform: const GradientRotation(45),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text('Don\'t have an account? Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
