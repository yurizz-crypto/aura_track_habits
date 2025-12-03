import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/common/utils/app_utils.dart';
import 'package:aura_track/common/widgets/custom_text_field.dart';
import 'package:aura_track/common/widgets/user_avatar.dart';

/// Allows the user to view their stats, update their display name, and choose an avatar.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  int _currentStreak = 0;
  String? _avatarUrl;

  // Preset avatars using DiceBear API
  final List<String> _avatarOptions = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Simba',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Gizmo',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Chloe',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Buster',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Mimi',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Jack',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Fetches current profile data from Supabase.
  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client
        .from('profiles')
        .select('username, current_streak, avatar_url')
        .eq('id', userId)
        .single();

    if (mounted) {
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _currentStreak = data['current_streak'] ?? 0;
        _avatarUrl = data['avatar_url'];
      });
    }
  }

  /// Saves changes to the database.
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text,
        'avatar_url': _avatarUrl,
      }).eq('id', userId);

      if (mounted) AppUtils.showSnackBar(context, "Profile Updated!");
    } catch (e) {
      if (mounted) AppUtils.showSnackBar(context, "Update failed.", isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Opens a bottom sheet to select a new avatar.
  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.teal.shade50,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose your Gardener", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    final url = _avatarOptions[index];
                    final isSelected = _avatarUrl == url;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _avatarUrl = url);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected ? Border.all(color: Colors.teal, width: 3) : null,
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(child: Image.network(url)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gardener Profile")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Reusable Avatar Component with Edit Indicator
                  UserAvatar(
                    avatarUrl: _avatarUrl,
                    username: _usernameController.text,
                    radius: 60,
                    showEditIcon: true,
                    onTap: _showAvatarSelection,
                  ),

                  const SizedBox(height: 20),
                  Text(
                      "Current Streak: $_currentStreak days 🔥",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(
                    controller: _usernameController,
                    label: "Display Name",
                    action: TextInputAction.done,
                  ),

                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}