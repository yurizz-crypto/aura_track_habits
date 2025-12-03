import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/common/utils/app_utils.dart';
import 'package:aura_track/common/widgets/custom_text_field.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/features/auth/signup_page.dart';

/// Screen allowing existing users to sign in via Email/Password or Social Providers.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  /// Validates inputs and attempts to sign in using [AuthService].
  /// If successful, [AuthGate] handles the navigation automatically.
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      AppUtils.showSnackBar(context, 'Email is required', isError: true);
      return;
    }
    if (!AppUtils.isValidEmail(email)) {
      AppUtils.showSnackBar(context, 'Please enter a valid email address', isError: true);
      return;
    }
    if (password.isEmpty) {
      AppUtils.showSnackBar(context, 'Password is required', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email, password);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Wrong Email or Password. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Initiates an OAuth login flow (Google/Facebook).
  Future<void> _socialLogin(OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.auratrack://login-callback',
      );
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Social login failed.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/aura_logo.png',
                  height: 250,
                  width: 250,
                ),
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
                  action: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 24),

                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                  children: [
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 20),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR"),
                      ),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                            'lib/assets/images/google.png',
                                () => _socialLogin(OAuthProvider.google)),
                        const SizedBox(width: 30),
                        _socialButton(
                            'lib/assets/images/facebook.png',
                                () => _socialLogin(OAuthProvider.facebook)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      child: const Text('Create Account'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Image.asset(assetPath, height: 40, width: 40),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}