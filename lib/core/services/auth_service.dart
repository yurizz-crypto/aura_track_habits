import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class handling all authentication interactions with Supabase.
/// This acts as a facade over the raw [SupabaseClient] auth methods.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the User ID (UUID) of the currently logged-in user, or null if not authenticated.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Registers a new user with the given [email] and [password].
  /// This usually triggers an OTP email to be sent to the user.
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  /// Logs in an existing user using [email] and [password].
  /// Returns the [AuthResponse] containing session data.
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out the current user, clearing the session from the device.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Verifies the 6-digit [token] sent to the user's [email] during signup.
  /// This completes the registration process.
  Future<void> verifyOtp(String email, String token) async {
    await _client.auth.verifyOTP(
      type: OtpType.signup,
      token: token,
      email: email,
    );
  }
}