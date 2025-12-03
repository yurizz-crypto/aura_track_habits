import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aura_track/core/services/habit_repository.dart';
import 'package:aura_track/core/services/auth_service.dart';
import 'package:aura_track/common/widgets/confirmation_dialog.dart';

/// A sensor-based habit where the user must walk a target distance (~25m, 34 steps)
/// to successfully complete the habit and earn points.
class WalkingHabit extends StatefulWidget {
  /// The ID of the habit being tracked. Used for completion logging.
  final String habitId;
  const WalkingHabit({super.key, required this.habitId});

  @override
  State<WalkingHabit> createState() => _WalkingHabitState();
}

class _WalkingHabitState extends State<WalkingHabit> {
  /// The target number of steps required to complete the habit (~25m).
  final int _targetSteps = 34;

  /// The number of steps walked since the session started.
  int _currentStepsCount = 0;

  /// The baseline step count recorded when the sensor stabilized.
  int? _startStepCount;

  /// Flag indicating if the habit goal has been completed.
  bool _completed = false;

  /// Flag indicating if the 'Physical Activity' permission is granted.
  bool _permissionGranted = false;

  /// Flag indicating if the step sensor is stabilizing its baseline reading.
  bool _isInitializing = true;

  /// Audio player for the success sound.
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Subscription to the Pedometer step count stream.
  late StreamSubscription<StepCount> _stepCountSubscription;

  /// Timer used to stabilize the initial sensor reading before setting the baseline.
  Timer? _stabilizationTimer;

  final _habitRepo = HabitRepository();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Set audio cache prefix for loading assets
    _audioPlayer.audioCache.prefix = 'lib/assets/sound/';
    _requestPermissionAndStart();
  }

  /// Requests the 'Physical Activity' permission and starts the pedometer if granted.
  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      _startPedometer();
    } else {
      setState(() {
        _permissionGranted = false;
        _currentStepsCount = -1; // Indicate error/no permission
      });
      if (mounted) _showPermissionDialog();
    }
  }

  /// Displays an alert dialog prompting the user to grant the 'Physical Activity' permission.
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Needed"),
        content: const Text("Enable 'Physical Activity' permission to track steps."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Opens app settings on the device
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  /// Subscribes to the pedometer stream, handles initialization, and tracks steps.
  void _startPedometer() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
          (StepCount event) {
        if (_completed) return;
        setState(() {
          // 1. Wait for initial stream event and stabilize baseline for 500ms
          if (_startStepCount == null && _stabilizationTimer == null) {
            _isInitializing = true;
            _stabilizationTimer = Timer(const Duration(milliseconds: 500), () {
              _startStepCount = event.steps; // Set baseline
              _isInitializing = false;
              _stabilizationTimer?.cancel();
            });
          }
          // 2. Calculate relative steps walked in this session
          if (_startStepCount != null && !_isInitializing) {
            _currentStepsCount = event.steps - _startStepCount!;
          }
          // 3. Check for completion
          if (_currentStepsCount >= _targetSteps) {
            _finishGame();
          }
        });
      },
      onError: (error) {
        // Handle sensor or stream error
        setState(() {
          _currentStepsCount = -1;
          _isInitializing = false;
          _stepCountSubscription.cancel();
        });
      },
      cancelOnError: true,
    );
  }

  /// Resets the session step count and re-initializes the pedometer stream.
  void _resetSteps() {
    setState(() {
      _startStepCount = null;
      _currentStepsCount = 0;
      _isInitializing = true;
      _stabilizationTimer?.cancel();
    });
    if (_permissionGranted) _startPedometer();
  }

  /// Finalizes the habit, logs the completion, and navigates away.
  Future<void> _finishGame() async {
    if (_completed) return;
    _completed = true;
    _stepCountSubscription.cancel();
    _stabilizationTimer?.cancel();

    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Log the habit completion via the repository.
      await _habitRepo.completeHabitInteraction(widget.habitId, userId);

      // Play success sound
      try {
        await _audioPlayer.play(AssetSource('success.mp3'));
      } catch (e) { /* ignore audio errors */ }

      if (mounted) {
        // Show success confirmation dialog.
        await CustomDialogs.showSuccessDialog(
            context,
            title: "Goal Achieved! 🏃",
            content: "You walked 25 meters and earned a point!"
        );
        if (mounted) Navigator.of(context).pop(); // Close the game screen
      }
    } catch (e) {
      debugPrint('Game Error: $e');
    }
  }

  @override
  void dispose() {
    _stepCountSubscription.cancel();
    _stabilizationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Walk 25 Meters (~34 Steps)")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_run, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                Text(
                  _currentStepsCount == -1
                      ? "Sensor Error - Check Permissions"
                      : _completed ? "Completed! (+1 Point)" : _permissionGranted
                      ? (_isInitializing ? "Initializing Sensor..." : "Keep Walking!")
                      : "Grant Permission to Start",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Text(
                  "Steps: ${_currentStepsCount > 0 ? _currentStepsCount : 0} / $_targetSteps",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // Progress Indicator
                LinearProgressIndicator(
                  value: _isInitializing
                      ? null // Use indeterminate progress during initialization
                      : (_currentStepsCount > 0 ? _currentStepsCount : 0) / _targetSteps,
                  minHeight: 15,
                  backgroundColor: Colors.teal.shade50,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Start/Request Permission button
                    ElevatedButton(
                      onPressed: _permissionGranted ? null : _requestPermissionAndStart,
                      child: const Text("Start"),
                    ),
                    // Reset button
                    if (_permissionGranted)
                      TextButton(
                        onPressed: _resetSteps,
                        child: const Text("Reset"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}