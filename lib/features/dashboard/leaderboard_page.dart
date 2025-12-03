import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/common/widgets/user_avatar.dart';
import 'package:aura_track/features/dashboard/visit_garden_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final int _pageSize = 50;
  final List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final from = _users.length;
      final to = from + _pageSize - 1;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'user')
          .order('points', ascending: false)
          .range(from, to);

      final List<Map<String, dynamic>> newUsers = List<Map<String, dynamic>>.from(response);

      setState(() {
        _users.addAll(newUsers);
        if (newUsers.length < _pageSize) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching leaderboard: $e");
    }
  }

  void _visitGarden(BuildContext context, Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitGardenPage(
          userId: user['id'],
          username: user['username'] ?? "Anonymous",
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return Colors.amber;
      case 1: return const Color(0xFFC0C0C0);
      case 2: return const Color(0xFFCD7F32);
      case 3: return Colors.purpleAccent;
      case 4: return Colors.deepPurpleAccent;
      case 5: return Colors.indigoAccent;
      case 6: return Colors.blueAccent;
      default: return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text("Community Garden")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: const Text(
              "Tap on a gardener to visit their Sanctuary! 🌱",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _users.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = _users[index];
                final isMe = user['id'] == currentUserId;
                final isTop3 = index < 3;
                final rankColor = _getRankColor(index);

                return ListTile(
                  onTap: () => _visitGarden(context, user),
                  leading: SizedBox(
                    width: 90,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: rankColor,
                          foregroundColor: Colors.white,
                          child: Text(
                            "#${index + 1}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        UserAvatar(
                          avatarUrl: user['avatar_url'],
                          username: user['username'] ?? 'A',
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                  title: isTop3
                      ? RainbowText(
                    text: user['username'] ?? "Anonymous Gardener",
                    baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                      : Text(
                    user['username'] ?? "Anonymous Gardener",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  subtitle: Text("${user['points'] ?? 0} flowers bloomed"),
                  tileColor: isMe ? Colors.teal.shade50 : null,
                  trailing: index < 3
                      ? Icon(Icons.emoji_events, color: rankColor)
                      : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RainbowText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;

  const RainbowText({super.key, required this.text, required this.baseStyle});

  @override
  State<RainbowText> createState() => _RainbowTextState();
}

class _RainbowTextState extends State<RainbowText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.red, Colors.orange, Colors.yellow, Colors.green,
                Colors.blue, Colors.indigo, Colors.purple, Colors.red,
              ],
              tileMode: TileMode.mirror,
              stops: [
                (_controller.value * 0.1) % 1.0,
                (_controller.value * 0.1 + 0.15) % 1.0,
                (_controller.value * 0.1 + 0.3) % 1.0,
                (_controller.value * 0.1 + 0.45) % 1.0,
                (_controller.value * 0.1 + 0.6) % 1.0,
                (_controller.value * 0.1 + 0.75) % 1.0,
                (_controller.value * 0.1 + 0.9) % 1.0,
                (_controller.value * 0.1 + 1.0) % 1.0,
              ],
              transform: GradientRotation(_controller.value * 6.28),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.baseStyle.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}