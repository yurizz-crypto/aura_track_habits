import 'package:flutter/material.dart';
import 'package:aura_track/common/utils/app_utils.dart';
import 'package:aura_track/common/widgets/custom_text_field.dart';
import 'package:aura_track/core/services/auth_service.dart';

/// Screen to verify the email OTP code sent during signup.
class OtpVerifyPage extends StatefulWidget {
  /// The email address to verify.
  final String email;
  const OtpVerifyPage({super.key, required this.email});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  /// Submits the OTP token to Supabase.
  /// On success, pops back to the root so [AuthGate] can redirect to the main app.
  Future<void> _verify() async {
    setState(() => _isLoading = true);
    try {
      await _authService.verifyOtp(widget.email, _otpController.text.trim());

      if (mounted) {
        // Pop all routes until we reach the AuthGate (root), which will auto-detect the new session.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Invalid Code or expired.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Placeholder for resending OTP functionality.
  Future<void> _resendOTP() async {
    try {
      // Implement authService.resendOtp(widget.email) here in future
      AppUtils.showSnackBar(context, 'Code resent!');
    } catch (e) {
      AppUtils.showSnackBar(context, 'Resend failed.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter the code sent to ${widget.email}"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _otpController,
              label: '6-Digit Code',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _verify,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Verify'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendOTP,
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}