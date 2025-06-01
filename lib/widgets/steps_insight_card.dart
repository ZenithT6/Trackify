import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StepInsightCard extends StatelessWidget {
  final int steps;
  final int goal;

  const StepInsightCard({
    super.key,
    required this.steps,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    final percent = steps / goal;

    if (percent >= 1.0) {
      message = "You've reached your step goal — amazing effort!";
      icon = FontAwesomeIcons.trophy;
      color = Colors.green;
    } else if (percent >= 0.7) {
      message = "Almost there — keep pushing to hit your goal!";
      icon = FontAwesomeIcons.shoePrints;
      color = Colors.orange;
    } else {
      message = "Let's get moving! You can do it!";
      icon = FontAwesomeIcons.personWalking;
      color = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
