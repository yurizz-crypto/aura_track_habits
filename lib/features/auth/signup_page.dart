import 'package:flutter/material.dart';
import 'package:aura_track/common/utils/app_utils.dart';
import 'package:aura_track/common/widgets/custom_text_field.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/features/auth/otp_verify_page.dart';

/// Screen allowing new users to create an account.
/// Navigates to [OtpVerifyPage] upon successful registration initiation.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  /// Validates form fields and calls [AuthService.signUp].
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Input Validation
    if (email.isEmpty) {
      AppUtils.showSnackBar(context, 'Email is required', isError: true);
      return;
    }
    if (!AppUtils.isValidEmail(email)) {
      AppUtils.showSnackBar(context, 'Please enter a valid email address', isError: true);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      AppUtils.showSnackBar(context, 'Password must be at least 6 characters', isError: true);
      return;
    }
    if (password != confirm) {
      AppUtils.showSnackBar(context, "Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(email, password);

      if (!mounted) return;

      // Navigate to OTP verification screen passing the email used
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => OtpVerifyPage(email: email)),
      );
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Signup failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              inputType: TextInputType.emailAddress,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              isPassword: true,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              isPassword: true,
              action: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}