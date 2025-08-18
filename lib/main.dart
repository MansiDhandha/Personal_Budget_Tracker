import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_tracker/screens/home/views/login_page.dart';
import 'package:budget_tracker/screens/home/views/register_page.dart';
import 'package:budget_tracker/screens/home/views/home_screen.dart'; // Add if needed
import 'simple_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Bloc.observer = SimpleBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/splash',
      routes: {
        '/': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/splash': (context) => const SplashScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimestamp = prefs.getInt('login_timestamp');
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (user != null && loginTimestamp != null) {
      final diff = now - loginTimestamp;
      if (diff < 60 * 60 * 1000) {
        // ✅ Valid session — go to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      } else {
        // ✅ Expired — sign out and clear
        await FirebaseAuth.instance.signOut();
        await prefs.remove('login_timestamp');
      }
    }
    // ✅ No session — go to login
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
