import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/features/auth/login_page.dart';
import 'package:aura_track/features/admin_panel/admin_dashboard.dart';
import 'package:aura_track/features/dashboard/main_scaffold.dart';

/// The root widget that listens to authentication state changes.
/// It directs the user to the Login page, Admin Dashboard, or User Home
/// based on their auth status and database role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listen to live auth changes (login, logout, token refresh)
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loader while initializing connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        // If no session exists, redirect to Login
        if (session == null) {
          return const LoginPage();
        }

        // If logged in, fetch the user profile to check their role (admin vs user)
        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = roleSnapshot.data;
            final role = data != null ? data['role'] : 'user';

            // Role-based routing
            if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return const MainScaffold();
            }
          },
        );
      },
    );
  }
}