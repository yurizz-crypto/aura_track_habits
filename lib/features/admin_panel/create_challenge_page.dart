import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/common/utils/app_utils.dart';
import 'package:aura_track/common/widgets/custom_text_field.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';

/// A form page for Admins to create and deploy a habit to ALL users.
class CreateChallengePage extends StatefulWidget {
  const CreateChallengePage({super.key});

  @override
  State<CreateChallengePage> createState() => _CreateChallengePageState();
}

class _CreateChallengePageState extends State<CreateChallengePage> {
  final _titleController = TextEditingController();
  String _selectedType = 'water_game';
  String _selectedIconAsset = 'check';
  bool _isDeploying = false;

  // Map of friendly names to internal types
  final Map<String, String> _habitTypes = {
    'water_game': 'Interactive: Pour Water',
    'meditation_game': 'Interactive: Meditation',
    'walking_game': 'Interactive: Walking',
    'standard': 'Standard: Checkbox',
  };

  // Map of icons for standard habits
  final Map<String, IconData> _icons = {
    'check': Icons.check_circle_outline,
    'book': Icons.menu_book,
    'gym': Icons.fitness_center,
    'bed': Icons.bed,
    'sun': Icons.sunny,
    'leaf': Icons.eco,
  };

  Future<void> _deployChallenge() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppUtils.showSnackBar(context, "Please enter a challenge title", isError: true);
      return;
    }

    // Confirm action
    final confirm = await CustomDialogs.showConfirmDialog(
      context,
      title: "Deploy Challenge?",
      content: "This will add the '$title' habit to ALL registered users immediately.",
      confirmText: "Deploy",
      confirmColor: Colors.teal,
    );

    if (!confirm) return;

    setState(() => _isDeploying = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch all user IDs
      // Note: In a real production app with thousands of users, this should be done via a Database Function (RPC)
      // to avoid fetching thousands of rows to the client. For this scale, client-side logic is acceptable.
      final response = await supabase.from('profiles').select('id');
      final List<dynamic> users = response as List<dynamic>;

      if (users.isEmpty) {
        if (mounted) AppUtils.showSnackBar(context, "No users found to deploy to.");
        return;
      }

      // 2. Prepare batch insert data
      final List<Map<String, dynamic>> habitsToInsert = users.map((user) {
        return {
          'user_id': user['id'],
          'title': title,
          'type': _selectedType,
          'icon_asset': _selectedType == 'standard' ? _selectedIconAsset : null,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      // 3. Perform Bulk Insert
      await supabase.from('habits').insert(habitsToInsert);

      if (mounted) {
        CustomDialogs.showSuccessDialog(
          context,
          title: "Deployment Successful 🚀",
          content: "Added '$title' to ${users.length} gardens.",
        );
        _titleController.clear();
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, "Deployment failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDeploying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Global Challenge")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              color: Colors.teal,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.public, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Create a habit that will appear in every user's garden.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text("Challenge Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _titleController,
              label: "Challenge Title (e.g., 'Morning Hydration')",
              action: TextInputAction.done,
            ),

            const SizedBox(height: 24),
            const Text("Habit Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _habitTypes.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),

            if (_selectedType == 'standard') ...[
              const SizedBox(height: 24),
              const Text("Select Icon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _icons.entries.map((entry) {
                  final isSelected = _selectedIconAsset == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconAsset = entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? Colors.teal : Colors.grey,
                        size: 28,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isDeploying ? null : _deployChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                icon: _isDeploying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.rocket_launch),
                label: const Text("Deploy to All Gardeners"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}