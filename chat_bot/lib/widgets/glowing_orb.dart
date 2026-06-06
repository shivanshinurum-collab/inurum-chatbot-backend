import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowingOrb extends StatefulWidget {
  final double size;
  final bool isThinking;
  final bool isListening;

  const GlowingOrb({
    super.key,
    this.size = 250.0,
    this.isThinking = false,
    this.isListening = false,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didUpdateWidget(GlowingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking != oldWidget.isThinking || widget.isListening != oldWidget.isListening) {
      if (widget.isThinking) {
        _controller.duration = const Duration(seconds: 2);
        _controller.repeat();
      } else if (widget.isListening) {
        _controller.duration = const Duration(milliseconds: 1500);
        _controller.repeat();
      } else {
        _controller.duration = const Duration(seconds: 4);
        _controller.repeat();
      }
    }
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: OrbPainter(
            animationValue: _controller.value,
            isThinking: widget.isThinking,
            isListening: widget.isListening,
          ),
        );
      },
    );
  }
}

class OrbPainter extends CustomPainter {
  final double animationValue;
  final bool isThinking;
  final bool isListening;

  OrbPainter({
    required this.animationValue,
    required this.isThinking,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.32;

    // Define colors for overlapping gradients (matches user screenshot color theme)
    final pinkGlow = const Color(0xFFFF52A2);
    final purpleGlow = const Color(0xFF9F52FF);
    final violetGlow = const Color(0xFF6B11FF);
    final deepRedGlow = const Color(0xFFFF216E);

    // Save layer to apply composite/blur blending effects cleanly
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(rect, Paint());

    // We draw 4 overlapping layers, each morphing differently using sine/cosine functions
    final numLayers = 4;
    for (int i = 0; i < numLayers; i++) {
      final double progress = animationValue * 2.0 * math.pi;
      final double layerPhase = i * (math.pi / 2);

      // Speed & magnitude scale based on state
      double speedMultiplier = isThinking ? 2.5 : (isListening ? 2.0 : 1.0);
      double scaleMultiplier = isThinking ? 1.25 : (isListening ? 1.35 : 1.0);

      // Vary the radius and position organically
      final double offsetRadius = (baseRadius * 0.12) *
          math.sin(progress * speedMultiplier + layerPhase) *
          scaleMultiplier;
      final double angle = progress * (i.isEven ? 1 : -1) + (i * math.pi / 4);

      final double offsetX = math.cos(angle) * offsetRadius;
      final double offsetY = math.sin(angle) * offsetRadius;
      final Offset blobCenter = center + Offset(offsetX, offsetY);

      final double radius = baseRadius *
          (1.0 + 0.15 * math.sin(progress * speedMultiplier * 1.5 + layerPhase)) *
          scaleMultiplier;

      // Select colors based on layer index
      Color startColor;
      Color endColor;
      switch (i) {
        case 0:
          startColor = pinkGlow.withOpacity(0.75);
          endColor = purpleGlow.withOpacity(0.0);
          break;
        case 1:
          startColor = purpleGlow.withOpacity(0.70);
          endColor = violetGlow.withOpacity(0.0);
          break;
        case 2:
          startColor = deepRedGlow.withOpacity(0.65);
          endColor = pinkGlow.withOpacity(0.0);
          break;
        case 3:
        default:
          startColor = violetGlow.withOpacity(0.80);
          endColor = deepRedGlow.withOpacity(0.0);
          break;
      }

      // Draw the radial glow blob
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [startColor, endColor],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: blobCenter, radius: radius))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isListening ? 24.0 : 30.0);

      canvas.drawCircle(blobCenter, radius, paint);
    }

    // Draw a bright, high-intensity core in the very center to make it look 3D and glowing
    final double coreProgress = animationValue * 2.0 * math.pi;
    final double coreRadius = baseRadius * 0.45 * (1.0 + 0.08 * math.sin(coreProgress * 2));
    final Paint corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          pinkGlow.withOpacity(0.4),
          purpleGlow.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawCircle(center, coreRadius, corePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isThinking != isThinking ||
        oldDelegate.isListening != isListening;
  }
}
