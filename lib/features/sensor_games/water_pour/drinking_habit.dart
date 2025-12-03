import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aura_track/core/services/habit_repository.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';

/// A game where users must physically tilt their phone to "drink" water from a
/// virtual glass, designed to track a drinking habit.
class WaterPourGame extends StatefulWidget {
  /// The ID of the habit being tracked. Used for completion logging.
  final String habitId;
  const WaterPourGame({super.key, required this.habitId});

  @override
  State<WaterPourGame> createState() => _WaterPourGameState();
}

class _WaterPourGameState extends State<WaterPourGame> with SingleTickerProviderStateMixin {
  /// Subscription to accelerometer events.
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  /// The raw x-axis tilt value from the accelerometer.
  double _tiltX = 0.0;

  /// The current fill level of the virtual glass (1.0 = full, 0.0 = empty).
  double _fillLevel = 1.0; // Start full

  /// Flag indicating if the tilt threshold for pouring/drinking has been met.
  bool _isPouring = false;

  /// Flag indicating if the game has been completed and the habit logged.
  bool _completed = false;

  /// Audio player for the success sound.
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Audio player for the continuous pouring/drinking sound effect.
  final AudioPlayer _effectPlayer = AudioPlayer();

  final _habitRepo = HabitRepository();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Set audio cache prefix for loading assets
    _audioPlayer.audioCache.prefix = 'lib/assets/sound/';
    _effectPlayer.audioCache.prefix = 'lib/assets/sound/';
    _startListeningToSensor();
  }

  /// Starts listening to accelerometer events to detect phone orientation.
  void _startListeningToSensor() {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (_completed) return;

      setState(() {
        _tiltX = event.x;
        // Threshold > 5.0 roughly indicates a 45+ degree tilt sideways.
        bool nowPouring = _tiltX.abs() > 5.0;

        if (nowPouring && !_isPouring) {
          _isPouring = true;
          _playPourSound();
        } else if (!nowPouring && _isPouring) {
          _isPouring = false;
          _stopPourSound();
        }

        if (_isPouring) {
          _emptyGlass();
        }
      });
    });
  }

  /// Plays the continuous drinking sound effect.
  Future<void> _playPourSound() async {
    try {
      // Plays the sound from the asset source.
      await _effectPlayer.play(AssetSource('drinking_sound.mp3'));
    } catch(e) { /* ignore audio errors */ }
  }

  /// Stops the continuous drinking sound effect.
  Future<void> _stopPourSound() async {
    try {
      await _effectPlayer.stop();
    } catch(e) { /* ignore */ }
  }

  /// Decreases the [_fillLevel] based on how steep the tilt angle is,
  /// simulating the action of drinking water.
  void _emptyGlass() {
    if (_fillLevel > 0.0) { // Check if still water left
      setState(() {
        // Calculate flow rate: Steeper tilt gives a faster flow (higher flowRate).
        double flowRate = (_tiltX.abs() - 4.0) / 500.0;
        // Ensure a minimum flow rate when tilted above the threshold.
        if (flowRate < 0.005) flowRate = 0.005;

        // Decrement fill level and clamp to ensure it stays between 0.0 and 1.0.
        _fillLevel -= flowRate;
        _fillLevel = _fillLevel.clamp(0.0, 1.0);
      });
    } else {
      // If the glass is empty, finish the game.
      _finishGame();
    }
  }

  /// Finalizes the game, logs the habit completion, plays a success sound,
  /// and navigates the user away.
  Future<void> _finishGame() async {
    if (_completed) return;

    _completed = true;
    _isPouring = false;
    _accelSubscription?.cancel();
    _stopPourSound();

    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Log the habit completion via the repository.
      await _habitRepo.completeHabitInteraction(widget.habitId, userId);

      try {
        // Play success audio.
        await _audioPlayer.play(AssetSource('success.mp3'));
      } catch (e) { /* ignore */ }

      if (mounted) {
        // Show success confirmation dialog.
        await CustomDialogs.showSuccessDialog(
            context,
            title: "Hydrated! 💧",
            content: "Good job keeping your habit and earning points!"
        );
        if (mounted) Navigator.of(context).pop(); // Close the game screen
      }
    } catch (e) {
      debugPrint('Error finishing game: $e');
    }
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _audioPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Calculate the canvas size based on the smaller screen dimension for better scaling.
    final canvasSize = (screenSize.height < screenSize.width ? screenSize.height : screenSize.width) * 0.6;
    const double glassAspect = 0.66; // Fixed aspect ratio for the glass visual

    return Scaffold(
      appBar: AppBar(title: const Text("Tilt to Drink")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _completed ? "Empty! (+1 Point)" : "Tilt phone sideways to drink the water!",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: canvasSize,
                  width: canvasSize * glassAspect,
                  child: CustomPaint(
                    painter: WaterGlassPainter(
                        fillLevel: _fillLevel.clamp(0.0, 1.0),
                        isPouring: _isPouring,
                        tiltX: _tiltX
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Fill Level: ${(_fillLevel * 100).clamp(0, 100).toInt()}%"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A [CustomPainter] for drawing the water glass and the water level.
class WaterGlassPainter extends CustomPainter {
  /// The current fill level of the water (0.0 to 1.0).
  final double fillLevel;

  /// Flag indicating if the water is currently pouring/drinking.
  final bool isPouring;

  /// The raw x-axis tilt value. Currently unused in the `paint` method.
  final double tiltX;

  WaterGlassPainter({required this.fillLevel, required this.isPouring, required this.tiltX});

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the glass outline
    final Paint glassPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Paint for the water fill
    final Paint waterPaint = Paint()
      ..color = Colors.blue.shade400.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // --- Draw Glass Outline (Trapezoid shape) ---
    final Path glassPath = Path();
    glassPath.moveTo(10, 0); // Top-left corner
    glassPath.lineTo(30, size.height); // Bottom-left corner
    glassPath.lineTo(size.width - 30, size.height); // Bottom-right corner
    glassPath.lineTo(size.width - 10, 0); // Top-right corner
    canvas.drawPath(glassPath, glassPaint);

    // --- Draw Water Fill ---
    if (fillLevel > 0) {
      double waterHeight = size.height * fillLevel;
      double topY = size.height - waterHeight;

      // Calculate top-edge horizontal offset based on current fillLevel
      // This creates the tapered shape of the water surface inside the glass.
      double horizontalOffset = 20 * (1 - fillLevel);

      Path waterPath = Path();
      // Move to the top-left water surface point
      waterPath.moveTo(10 + horizontalOffset, topY);
      // Line to bottom-left glass corner
      waterPath.lineTo(30, size.height);
      // Line to bottom-right glass corner
      waterPath.lineTo(size.width - 30, size.height);
      // Line to the top-right water surface point
      waterPath.lineTo(size.width - 10 - horizontalOffset, topY);
      canvas.drawPath(waterPath, waterPaint);
    }

    // Note: Pouring stream drawing logic has been removed as per file comments.
  }

  @override
  bool shouldRepaint(covariant WaterGlassPainter oldDelegate) {
    // Repaint only if the fill level or the pouring state has changed.
    return oldDelegate.fillLevel != fillLevel || oldDelegate.isPouring != isPouring;
  }
}