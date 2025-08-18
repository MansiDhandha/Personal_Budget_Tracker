import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'home_screen.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:budget_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final incomeController = TextEditingController();
  final budgetController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      String name = nameController.text.trim();
      double income = double.tryParse(incomeController.text.trim()) ?? 0.0;
      double budget = double.tryParse(budgetController.text.trim()) ?? 0.0;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': emailController.text.trim(),
        'monthly_income': income,
        'monthly_budget': budget,
        'remaining_budget': budget, // ✅ new field here
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'login_timestamp', DateTime.now().millisecondsSinceEpoch);

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
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return '$fieldName must be a valid number';
    }
    return null;
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Register',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: incomeController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monthly Income',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateNumber(value, 'Monthly Income'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: budgetController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monthly Budget',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateNumber(value, 'Monthly Budget'),
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
                          onPressed: _register,
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
                                'Register',
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
                                builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
