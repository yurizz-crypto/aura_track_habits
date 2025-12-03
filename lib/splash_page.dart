import 'package:flutter/material.dart';
import 'package:aura_track/features/auth/auth_gate.dart';

/// A simple splash screen that shows the logo for 3 seconds
/// before navigating to the AuthGate to determine user state.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Artificial delay for branding
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/aura_logo.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            const Text(
              "Growing your garden...",
              style: TextStyle(
                color: Colors.teal,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}