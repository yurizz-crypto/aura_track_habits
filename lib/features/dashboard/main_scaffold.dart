import 'package:flutter/material.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/features/dashboard/user_home.dart';
import 'package:aura_track/features/dashboard/leaderboard_page.dart';
import 'package:aura_track/features/dashboard/profile_page.dart';

/// The main shell of the application for authenticated users.
/// Manages the BottomNavigationBar and navigation between Home, Leaderboard, and Profile.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const UserHome(),
    const LeaderboardPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Displays a confirmation dialog before signing out.
  Future<void> _handleLogout() async {
    final confirm = await CustomDialogs.showConfirmDialog(
      context,
      title: 'Logout?',
      content: 'Are you sure you want to leave your garden?',
      confirmText: 'Logout',
    );

    if (confirm) {
      await AuthService().signOut();
      // Navigation is handled automatically by AuthGate listening to the stream.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_florist),
              label: 'Garden'
          ),
          NavigationDestination(
              icon: Icon(Icons.emoji_events),
              label: 'Leaderboard'
          ),
          NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile'
          ),
        ],
      ),
      // Show Logout button only on the Garden (Home) tab
      floatingActionButton: _selectedIndex == 0 ? null : FloatingActionButton(
        onPressed: _handleLogout,
        backgroundColor: Colors.red.shade100,
        child: const Icon(Icons.logout, color: Colors.red),
      ),
    );
  }
}