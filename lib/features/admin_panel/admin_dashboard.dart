import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/features/admin_panel/create_challenge_page.dart'; // Import the new page

/// The dashboard screen visible only to users with the 'admin' role.
/// Displays high-level stats and content management options.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// Shows a logout confirmation dialog and signs out if confirmed.
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await CustomDialogs.showConfirmDialog(
      context,
      title: 'Logout Admin?',
      content: 'Are you sure you want to leave the admin console?',
      confirmText: 'Logout',
    );

    if (confirm) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("System Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Fetches and displays total user count
            FutureBuilder(
              future: Supabase.instance.client.from('profiles').select(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final users = snapshot.data as List;

                return Card(
                  color: Colors.blueGrey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.people, size: 40, color: Colors.blueGrey),
                        const SizedBox(height: 10),
                        Text("${users.length}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const Text("Total Registered Users"),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text("Content Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text("Create Global Challenge"),
              subtitle: const Text("Deploy a new habit template to all users"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateChallengePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}