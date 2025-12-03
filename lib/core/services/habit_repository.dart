import 'package:supabase_flutter/supabase_flutter.dart';

/// A data repository class for managing Habits and Habit Logs in Supabase.
class HabitRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns a real-time stream of habits created by the specific [userId].
  /// The list is ordered by creation date.
  Stream<List<Map<String, dynamic>>> getHabitsStream(String userId) {
    return _client
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at');
  }

  /// Returns a real-time stream of the 50 most recent habit completion logs for [userId].
  /// Used to determine which habits have been done today.
  Stream<List<Map<String, dynamic>>> getRecentLogsStream(String userId) {
    return _client
        .from('habit_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('completed_at', ascending: false)
        .limit(50);
  }

  /// Records a habit completion in the database.
  ///
  /// 1. Inserts a new record into `habit_logs`.
  /// 2. Calls the RPC `increment_points` to update user score.
  /// 3. Calls the RPC `update_user_streak` to recalculate streaks.
  Future<void> completeHabitInteraction(String habitId, String userId) async {
    await _client.from('habit_logs').insert({
      'habit_id': habitId,
      'user_id': userId,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _client.rpc('increment_points', params: {'row_id': userId});

    await _client.rpc('update_user_streak', params: {'user_uuid': userId});
  }

  /// Deletes a habit definition from the `habits` table.
  /// Note: This might fail if foreign key constraints (existing logs) are not handled.
  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }
}