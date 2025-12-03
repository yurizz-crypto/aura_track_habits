import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that renders an animated garden scene.
/// The visual theme changes based on the user's total points (Prestige levels).
class GardenScene extends StatefulWidget {
  /// Total points earned by the user. Determines the Level and flower count.
  final int totalPoints;

  /// Current daily streak. If >= 7, flowers will glow.
  final int currentStreak;

  /// If `true`, changes the sky gradient to indicate daily success.
  final bool isQuotaMet;

  const GardenScene({
    super.key,
    required this.totalPoints,
    required this.currentStreak,
    required this.isQuotaMet,
  });

  @override
  State<GardenScene> createState() => _GardenSceneState();
}

class _GardenSceneState extends State<GardenScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous animation loop (10 seconds) for elements like the Bee, Sun pulse, etc.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Level increases every 50 points (0-49 = Lvl 0, 50-99 = Lvl 1).
    final int level = widget.totalPoints ~/ 50;
    // Only show up to 50 flowers at a time before resetting.
    final int visibleFlowers = widget.totalPoints % 50;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: GardenPainter(
            level: level,
            flowerCount: visibleFlowers,
            currentStreak: widget.currentStreak,
            isQuotaMet: widget.isQuotaMet,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

/// CustomPainter responsible for drawing the sky, hills, flowers, and animated elements.
class GardenPainter extends CustomPainter {
  final int level;
  final int flowerCount;
  final int currentStreak;
  final bool isQuotaMet;
  final double animationValue; // 0.0 to 1.0

  GardenPainter({
    required this.level,
    required this.flowerCount,
    required this.currentStreak,
    required this.isQuotaMet,
    required this.animationValue,
  });

  /// Returns a color palette [GardenTheme] based on the current level index.
  /// Cycle: Day -> Sunset -> Night -> Sakura.
  GardenTheme _getTheme(int lvl) {
    int themeIndex = lvl % 4;
    switch (themeIndex) {
      case 0: // Standard Day
        return GardenTheme(
          skyTop: Colors.lightBlue.shade100,
          skyBottom: Colors.white,
          grass: Colors.green.shade300,
          hill: Colors.green.shade400,
          celestialBodyColor: Colors.yellow,
          isNight: false,
        );
      case 1: // Sunset
        return GardenTheme(
          skyTop: Colors.orange.shade200,
          skyBottom: Colors.yellow.shade50,
          grass: Colors.orange.shade700,
          hill: Colors.brown.shade400,
          celestialBodyColor: Colors.orangeAccent,
          isNight: false,
        );
      case 2: // Night
        return GardenTheme(
          skyTop: const Color(0xFF0D1B2A),
          skyBottom: const Color(0xFF1B263B),
          grass: const Color(0xFF415A77),
          hill: const Color(0xFF778DA9),
          celestialBodyColor: Colors.white,
          isNight: true,
        );
      case 3: // Sakura / Spring
        return GardenTheme(
          skyTop: Colors.pink.shade50,
          skyBottom: Colors.white,
          grass: Colors.pink.shade200,
          hill: Colors.pink.shade300,
          celestialBodyColor: Colors.amber.shade100,
          isNight: false,
        );
      default:
        return GardenTheme(
            skyTop: Colors.blue, skyBottom: Colors.white, grass: Colors.green, hill: Colors.green, celestialBodyColor: Colors.yellow, isNight: false);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final theme = _getTheme(level);
    final Paint paint = Paint();
    final Rect rect = Offset.zero & size;

    // 1. Draw Sky Gradient
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.skyTop, theme.skyBottom],
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null; // Reset shader for subsequent draws

    // 2. Draw Sun or Moon
    _drawCelestialBody(canvas, size, theme);

    // 3. Draw Background Hills
    paint.color = theme.hill;
    final Path hillPath = Path();
    hillPath.moveTo(0, size.height);
    hillPath.lineTo(0, size.height - 40);
    hillPath.quadraticBezierTo(size.width * 0.25, size.height - 80, size.width * 0.5, size.height - 50);
    hillPath.quadraticBezierTo(size.width * 0.75, size.height - 30, size.width, size.height - 60);
    hillPath.lineTo(size.width, size.height);
    canvas.drawPath(hillPath, paint);

    // 4. Draw Foreground Grass
    paint.color = theme.grass;
    final Path foreGroundHill = Path();
    foreGroundHill.moveTo(0, size.height);
    foreGroundHill.lineTo(0, size.height - 20);
    foreGroundHill.quadraticBezierTo(size.width * 0.5, size.height - 50, size.width, size.height - 20);
    foreGroundHill.lineTo(size.width, size.height);
    canvas.drawPath(foreGroundHill, paint);

    // 5. Draw Flowers
    for (int i = 0; i < flowerCount; i++) {
      // Use a stable random seed so flowers don't jitter every frame
      final flowerRandom = Random(i + (level * 100));

      double x = size.width * (0.05 + flowerRandom.nextDouble() * 0.9);
      double y = size.height - 20 - (flowerRandom.nextDouble() * 40);

      _drawFlower(canvas, x, y, Colors.primaries[i % Colors.primaries.length], theme.isNight);
    }

    // 6. Draw Animated Elements (Bee or Shooting Star)
    if (!theme.isNight) {
      _drawBee(canvas, size);
    } else {
      _drawStar(canvas, size);
    }
  }

  /// Draws the Sun or Moon with a pulsing glow effect.
  void _drawCelestialBody(Canvas canvas, Size size, GardenTheme theme) {
    final paint = Paint()..color = theme.celestialBodyColor;

    // Subtle pulse using sine wave
    double pulse = sin(animationValue * 2 * pi) * 2.0;
    Offset pos = Offset(size.width * 0.85, size.height * 0.2);

    // Outer Glow
    paint.color = theme.celestialBodyColor.withOpacity(0.3);
    canvas.drawCircle(pos, 25 + pulse, paint);

    // Core Body
    paint.color = theme.celestialBodyColor;
    canvas.drawCircle(pos, 15, paint);
  }

  /// Draws a Bee moving in a Figure-8 pattern across the screen.
  void _drawBee(Canvas canvas, Size size) {
    double t = animationValue;

    // Figure-8 motion path
    double x = size.width * 0.4 + (size.width * 0.4 * sin(t * 2 * pi));
    double y = size.height * 0.4 + (30 * cos(t * 4 * pi));

    Paint paint = Paint()..color = Colors.yellow;

    // Bee Body
    RRect body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 14, height: 10),
        const Radius.circular(10)
    );
    canvas.drawRRect(body, paint);

    // Bee Stripes
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(x - 2, y - 5), Offset(x - 2, y + 5), paint);
    canvas.drawLine(Offset(x + 2, y - 5), Offset(x + 2, y + 5), paint);

    // Bee Wings (Flapping animation)
    paint.color = Colors.white.withOpacity(0.7);
    double wingOffset = sin(t * 20 * pi) * 5; // Fast oscillation
    canvas.drawOval(Rect.fromCenter(center: Offset(x - 2, y - 5 - wingOffset.abs()), width: 8, height: 5), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 4, y - 5 - wingOffset.abs()), width: 8, height: 5), paint);
  }

  /// Draws a shooting star animation that triggers only during a specific timeframe (0.8 - 0.9) of the loop.
  void _drawStar(Canvas canvas, Size size) {
    double t = animationValue;
    if (t > 0.8 && t < 0.9) {
      Paint paint = Paint()..color = Colors.white..strokeWidth = 2;
      double progress = (t - 0.8) * 10; // Normalize to 0.0 - 1.0 range

      // Start/End coordinates for the shooting star path
      double startX = size.width * 0.2;
      double startY = size.height * 0.1;
      double endX = size.width * 0.5;
      double endY = size.height * 0.4;

      double currentX = startX + (endX - startX) * progress;
      double currentY = startY + (endY - startY) * progress;

      canvas.drawLine(Offset(currentX, currentY), Offset(currentX - 10, currentY - 10), paint);
    }
  }

  /// Draws a single flower. If it is night or user has a high streak, applies a glow effect.
  void _drawFlower(Canvas canvas, double x, double y, Color color, bool isNight) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bool isGlowing = currentStreak >= 7;

    // Draw Glow (Blur)
    if (isGlowing || isNight) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);
      paint.color = isNight ? Colors.white.withOpacity(0.5) : Colors.amber.withOpacity(0.6);
      canvas.drawCircle(Offset(x, y - 35), 15, paint);
      paint.maskFilter = null;
    }

    // Stem
    paint.color = Colors.green.shade800;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(x, y), Offset(x, y - 35), paint);

    // Petals
    paint.color = color;
    for (int i = 0; i < 5; i++) {
      double angle = (i * 72) * pi / 180;
      double petalX = x + cos(angle) * 8;
      double petalY = (y - 35) + sin(angle) * 8;
      canvas.drawCircle(Offset(petalX, petalY), 5, paint);
    }

    // Flower Center
    paint.color = Colors.yellowAccent;
    canvas.drawCircle(Offset(x, y - 35), 3, paint);
  }

  @override
  bool shouldRepaint(covariant GardenPainter oldDelegate) {
    return true; // Always repaint to ensure smooth animations
  }
}

/// Data class holding color definitions for various garden themes.
class GardenTheme {
  final Color skyTop;
  final Color skyBottom;
  final Color grass;
  final Color hill;
  final Color celestialBodyColor;
  final bool isNight;

  GardenTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.grass,
    required this.hill,
    required this.celestialBodyColor,
    required this.isNight,
  });
}