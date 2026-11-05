import 'dart:math';
import 'package:flutter/material.dart';

class HolographicOrb extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final double size;

  const HolographicOrb({
    super.key,
    this.isListening = false,
    this.isSpeaking = false,
    this.isThinking = false,
    this.size = 280,
  });

  @override
  State<HolographicOrb> createState() => _HolographicOrbState();
}

class _HolographicOrbState extends State<HolographicOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        _updateParticles();
      })
      ..repeat();

    // Create initial particles
    for (int i = 0; i < 180; i++) {
      _particles.add(_createParticle());
    }
  }

  _Particle _createParticle() {
    final angle1 = _random.nextDouble() * pi * 2;
    final angle2 = _random.nextDouble() * pi;
    final radius = 0.7 + _random.nextDouble() * 0.3;

    return _Particle(
      theta: angle1,
      phi: angle2,
      radius: radius,
      speed: 0.002 + _random.nextDouble() * 0.008,
      size: 1.0 + _random.nextDouble() * 2.2,
      opacity: 0.4 + _random.nextDouble() * 0.6,
    );
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.theta += p.speed;
      if (p.theta > pi * 2) p.theta -= pi * 2;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isListening || widget.isSpeaking || widget.isThinking;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        final pulse = 0.92 + (_pulseController.value * 0.08);
        final activeScale = isActive ? 1.05 : 1.0;

        return Transform.scale(
          scale: pulse * activeScale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _OrbPainter(
                particles: _particles,
                rotation: _rotationController.value * 2 * pi,
                isListening: widget.isListening,
                isSpeaking: widget.isSpeaking,
                isThinking: widget.isThinking,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  double theta;
  double phi;
  double radius;
  double speed;
  double size;
  double opacity;

  _Particle({
    required this.theta,
    required this.phi,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _OrbPainter extends CustomPainter {
  final List<_Particle> particles;
  final double rotation;
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;

  _OrbPainter({
    required this.particles,
    required this.rotation,
    required this.isListening,
    required this.isSpeaking,
    required this.isThinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Glow background
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isListening
              ? const Color(0xFF00D4FF).withOpacity(0.25)
              : isSpeaking
                  ? const Color(0xFF7B2CBF).withOpacity(0.3)
                  : isThinking
                      ? const Color(0xFF00FF88).withOpacity(0.2)
                      : const Color(0xFF00D4FF).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8));

    canvas.drawCircle(center, radius * 1.8, glowPaint);

    // Draw particles forming the orb shape
    for (final p in particles) {
      // Spherical to cartesian with rotation
      final x = p.radius * sin(p.phi) * cos(p.theta + rotation);
      final y = p.radius * cos(p.phi);
      final z = p.radius * sin(p.phi) * sin(p.theta + rotation);

      // Simple perspective
      final scale = 0.7 + (z + 1) * 0.3;
      final px = center.dx + x * radius * scale;
      final py = center.dy + y * radius * scale;

      // Color based on state and position
      Color color;
      if (isListening) {
        color = Color.lerp(
          const Color(0xFF00D4FF),
          const Color(0xFF00FFCC),
          (z + 1) / 2,
        )!;
      } else if (isSpeaking) {
        color = Color.lerp(
          const Color(0xFF9B5DE5),
          const Color(0xFF00D4FF),
          (z + 1) / 2,
        )!;
      } else if (isThinking) {
        color = Color.lerp(
          const Color(0xFF00FF88),
          const Color(0xFF00D4FF),
          (z + 1) / 2,
        )!;
      } else {
        color = Color.lerp(
          const Color(0xFF00B4D8),
          const Color(0xFF7B2CBF),
          (z + 1) / 2,
        )!;
      }

      final opacity = (p.opacity * (0.5 + (z + 1) * 0.25)).clamp(0.2, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(px, py), p.size * scale, paint);
    }

    // Outer ring glow
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF00D4FF).withOpacity(0.0),
          const Color(0xFF00D4FF).withOpacity(0.6),
          const Color(0xFF7B2CBF).withOpacity(0.6),
          const Color(0xFF00D4FF).withOpacity(0.0),
        ],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));

    canvas.drawCircle(center, radius * 1.15, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
