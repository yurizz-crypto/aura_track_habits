import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aura_track/core/services/habit_repository.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';
import 'package:aura_track/common/utils/app_utils.dart';

/// A mindfulness game where the user must hold the phone still for 60 seconds
/// to complete a meditation habit. It uses the User Accelerometer (which excludes
/// gravity) to detect small movements.
class MeditationGame extends StatefulWidget {
  /// The ID of the habit being tracked. Used for completion logging.
  final String habitId;
  const MeditationGame({super.key, required this.habitId});

  @override
  State<MeditationGame> createState() => _MeditationGameState();
}

class _MeditationGameState extends State<MeditationGame> with SingleTickerProviderStateMixin {
  /// The duration of stillness required in seconds.
  final int _targetSeconds = 60;

  /// The current progress of the meditation (0.0 to 1.0).
  double _progress = 0.0;

  /// Flag indicating if the device is currently moving above the threshold.
  bool _isMoving = false;

  /// Flag indicating if the habit goal has been completed.
  bool _completed = false;

  /// Timer for tracking time and updating progress.
  Timer? _timer;

  /// Subscription to the User Accelerometer stream.
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  /// Audio player for the success sound.
  final AudioPlayer _audioPlayer = AudioPlayer();

  final _habitRepo = HabitRepository();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Set audio cache prefix for loading assets
    _audioPlayer.audioCache.prefix = 'lib/assets/sound/';
    _startSensor();
    _startTimer();
  }

  /// Starts listening to the User Accelerometer to detect movement (excluding gravity).
  void _startSensor() {
    _accelSubscription = userAccelerometerEventStream().listen((event) {
      // Calculate the magnitude of the acceleration vector.
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Threshold for stillness (0.3 m/s^2)
      bool currentlyMoving = magnitude > 0.3;

      // Update state only if the movement status has changed.
      if (currentlyMoving != _isMoving) {
        setState(() => _isMoving = currentlyMoving);
      }
    });
  }

  /// Starts a periodic timer that increments progress if the device is still.
  /// If moving, progress pauses.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_completed) {
        timer.cancel();
        return;
      }

      if (!_isMoving) {
        // Increment progress by a factor of the target time (0.1 second out of 60 seconds).
        setState(() => _progress += (0.1 / _targetSeconds));

        if (_progress >= 1.0) {
          _finishGame();
        }
      }
    });
  }

  /// Finalizes the game, logs the habit completion, plays a success sound,
  /// and navigates the user away.
  Future<void> _finishGame() async {
    _completed = true;
    _timer?.cancel();
    _accelSubscription?.cancel();

    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Log the habit completion via the repository.
      await _habitRepo.completeHabitInteraction(widget.habitId, userId);

      // Play success sound
      try {
        await _audioPlayer.play(AssetSource('success.mp3'));
      } catch (e) { /* ignore audio errors */ }

      if (mounted) AppUtils.showSnackBar(context, "Points earned!");

      if (mounted) {
        // Show success confirmation dialog.
        await CustomDialogs.showSuccessDialog(
            context,
            title: "Zen Achieved 🌸",
            content: "You remained still and mindful for 60 seconds."
        );
        if (mounted) Navigator.of(context).pop(); // Close the game screen
      }
    } catch (e) {
      debugPrint('Database Update Error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Calculate the canvas size based on the smaller screen dimension for better scaling.
    final canvasSize = (screenSize.height < screenSize.width ? screenSize.height : screenSize.width) * 0.6;

    // Calculate remaining seconds for display
    int secondsRemaining = ((1.0 - _progress) * _targetSeconds).ceil();
    if (secondsRemaining < 0) secondsRemaining = 0;

    return Scaffold(
      // Change background color based on movement status
      backgroundColor: _isMoving ? Colors.red.shade50 : Colors.teal.shade50,
      appBar: AppBar(title: const Text("Hold Still")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isMoving ? "Too much movement!" : "Breathe...",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isMoving ? Colors.red : Colors.teal,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: canvasSize,
                  width: canvasSize,
                  child: CustomPaint(
                    painter: MeditationTimerPainter(progress: _progress, isMoving: _isMoving),
                  ),
                ),
                const SizedBox(height: 40),
                Text("$secondsRemaining seconds remaining", style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                const Text("Hold your phone perfectly still.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A [CustomPainter] for drawing the circular progress indicator and a central dot.
class MeditationTimerPainter extends CustomPainter {
  /// The current progress of the timer (0.0 to 1.0).
  final double progress;

  /// Flag indicating if the device is currently moving.
  final bool isMoving;

  MeditationTimerPainter({required this.progress, required this.isMoving});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;

    // Background circle paint
    Paint bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc paint
    Paint progressPaint = Paint()
      ..color = isMoving ? Colors.red : Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    // Draw the progress arc starting from the top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress, // Total sweep angle
      false,
      progressPaint,
    );

    // Central dot paint
    Paint dotPaint = Paint()..color = isMoving ? Colors.redAccent : Colors.tealAccent;

    // Apply a random "jitter" to the dot if the user is moving
    double jitterX = isMoving ? (Random().nextDouble() * 20 - 10) : 0;
    double jitterY = isMoving ? (Random().nextDouble() * 20 - 10) : 0;

    canvas.drawCircle(center + Offset(jitterX, jitterY), 20, dotPaint);
  }

  @override
  bool shouldRepaint(covariant MeditationTimerPainter oldDelegate) {
    // Repaint every time the progress or movement state changes.
    // Returning true ensures the jitter effect is constantly updated while moving.
    return oldDelegate.progress != progress || oldDelegate.isMoving != isMoving;
  }
}