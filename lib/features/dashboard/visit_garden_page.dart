import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:aura_track/common/widgets/garden_scene.dart';

/// A read-only view displaying the virtual garden and key statistics of another user.
/// It listens to the target user's profile in real-time using Supabase.
class VisitGardenPage extends StatelessWidget {
  /// The unique ID of the user whose garden is being visited.
  final String userId;

  /// The display name of the user whose garden is being visited.
  final String username;

  const VisitGardenPage({
    super.key,
    required this.userId,
    required this.username,
  });

  /// Sets up a Supabase Realtime Stream listener for the target user's profile
  /// based on their [userId].
  ///
  /// Returns a stream of a single profile map.
  Stream<Map<String, dynamic>> _getTargetUserProfile() {
    return Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
    // Since 'id' is unique, we expect exactly one event in the list.
        .map((event) => event.first);
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height to size the garden view appropriately.
    final screenHeight = MediaQuery.of(context).size.height;
    final double gardenHeight = screenHeight * 0.6; // Dedicate 60% of the screen height to the garden

    return Scaffold(
      appBar: AppBar(
        title: Text("$username's Sanctuary"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: gardenHeight,
            width: double.infinity,
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _getTargetUserProfile(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Safely extract profile data
                final profile = snapshot.data ?? {};
                final int flowers = profile['points'] ?? 0;
                final int streak = profile['current_streak'] ?? 0;
                final String? lastBonus = profile['last_bonus_date'];

                // Logic to check if the user has met their daily quota
                final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final bool isQuotaMet = lastBonus == todayStr;

                return Stack(
                  children: [
                    // 1. The Garden Widget (Visual representation of progress)
                    Positioned.fill(
                      child: GardenScene(
                        totalPoints: flowers,
                        currentStreak: streak,
                        isQuotaMet: isQuotaMet,
                      ),
                    ),

                    // 2. Visitor Overlay Information (Stats)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Level is calculated as points / 50 (simplified)
                              _buildStatItem("Level", "${(flowers / 50).floor()}"),
                              _buildStatItem("Blooms", "$flowers"),
                              _buildStatItem("Streak", "$streak 🔥"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Section: Motivational message for the visitor
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.teal.shade50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 40, color: Colors.teal),
                  const SizedBox(height: 16),
                  Text(
                    "You are visiting $username.",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Keep growing your own garden to climb the leaderboard!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to display a single statistic item (label and value).
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}