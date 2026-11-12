import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/been_here_theme.dart';

class AnimatedCompassFab extends StatefulWidget {
  const AnimatedCompassFab({
    super.key,
    required this.isSelected,
    required this.headingDegrees,
    required this.onTap,
  });

  final bool isSelected;
  final double headingDegrees;
  final VoidCallback onTap;

  @override
  State<AnimatedCompassFab> createState() => _AnimatedCompassFabState();
}

class _AnimatedCompassFabState extends State<AnimatedCompassFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        width: widget.isSelected ? 70 : 66,
        height: widget.isSelected ? 70 : 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isSelected
                ? const [
                    BeenHereColors.primaryCompass,
                    BeenHereColors.secondaryAmber,
                  ]
                : const [
                    Color(0xFF253A5E),
                    BeenHereColors.primaryCompass,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: BeenHereColors.primaryCompass.withValues(
                alpha: widget.isSelected ? 0.55 : 0.35,
              ),
              blurRadius: widget.isSelected ? 22 : 14,
              spreadRadius: widget.isSelected ? 3 : 1,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 2.2,
          ),
        ),
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final ambientOscillation =
                math.sin(_ambientController.value * 2 * math.pi) * 0.14;
            final targetRadians =
                (widget.headingDegrees * math.pi / 180.0) + ambientOscillation;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: targetRadians),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, angle, _) {
                return CustomPaint(
                  painter: _CompassDialPainter(needleAngleRadians: angle),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({required this.needleAngleRadians});

  final double needleAngleRadians;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Dış kadran halkası ve 8 yön çizgisi
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ringPaint);

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final tickAngle = i * math.pi / 4;
      final outer = Offset(
        center.dx + math.cos(tickAngle) * radius,
        center.dy + math.sin(tickAngle) * radius,
      );
      final inner = Offset(
        center.dx + math.cos(tickAngle) * (radius - (i.isEven ? 5.5 : 3.0)),
        center.dy + math.sin(tickAngle) * (radius - (i.isEven ? 5.5 : 3.0)),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Pusula Kuzey / Güney İbresi
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(needleAngleRadians);

    final northLength = radius - 5;
    final needleHalfWidth = 5.5;

    // Kuzey ucu (Parlak Beyaz / Altın)
    final northPath = Path()
      ..moveTo(0, -northLength)
      ..lineTo(needleHalfWidth, 0)
      ..lineTo(-needleHalfWidth, 0)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Güney ucu (Koyu Yarı Saydam)
    final southPath = Path()
      ..moveTo(0, northLength)
      ..lineTo(needleHalfWidth, 0)
      ..lineTo(-needleHalfWidth, 0)
      ..close();
    canvas.drawPath(
      southPath,
      Paint()
        ..color = const Color(0xFF0B1320).withValues(alpha: 0.72)
        ..style = PaintingStyle.fill,
    );

    // Merkez perçin noktası
    canvas.drawCircle(
      Offset.zero,
      3.5,
      Paint()..color = BeenHereColors.goldLeague,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.needleAngleRadians != needleAngleRadians;
  }
}
