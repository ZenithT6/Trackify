import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircularProgressWidget extends StatelessWidget {
  final int stepCount;
  final int goalSteps;

  const CircularProgressWidget({
    super.key,
    required this.stepCount,
    this.goalSteps = 8000,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (stepCount / goalSteps).clamp(0.0, 1.0);
    final goalReached = stepCount >= goalSteps;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (goalReached) AnimatedPulseGlow(radius: 80),
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _GradientCircularPainter(value),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FontAwesomeIcons.personWalking,
                  size: 24,
                  color: Color(0xFF0072FF),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: stepCount),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, animatedSteps, _) => Text(
                    "$animatedSteps Steps",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  "Goal - $goalSteps Steps",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (goalReached)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Goal Reached!",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GradientCircularPainter extends CustomPainter {
  final double progress;

  _GradientCircularPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    List<Color> gradientColors;
    if (progress < 0.4) {
      gradientColors = [const Color(0xFF00C6FF), const Color(0xFF0072FF)];
    } else if (progress < 0.8) {
      gradientColors = [const Color(0xFF00C6FF), Colors.tealAccent.shade700];
    } else {
      gradientColors = [Colors.greenAccent.shade400, Colors.green.shade800];
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: pi * 2,
      colors: gradientColors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedPulseGlow extends StatefulWidget {
  final double radius;

  const AnimatedPulseGlow({super.key, this.radius = 80});

  @override
  State<AnimatedPulseGlow> createState() => _AnimatedPulseGlowState();
}

class _AnimatedPulseGlowState extends State<AnimatedPulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.0, end: 20.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          width: widget.radius + _pulse.value,
          height: widget.radius + _pulse.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
          ),
        );
      },
    );
  }
}
