import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircularSleepProgress extends StatelessWidget {
  final double hoursSlept;
  final double goal;

  const CircularSleepProgress({
    super.key,
    required this.hoursSlept,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (hoursSlept / goal).clamp(0.0, 1.0);
    final remaining = (goal - hoursSlept).clamp(0.0, goal);
    final goalReached = hoursSlept >= goal;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ Animated Glow Ring if Goal Reached
          if (goalReached)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 25,
                    spreadRadius: 4,
                  )
                ],
              ),
            ),
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                goalReached ? Colors.green : Colors.deepPurple,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.bed,
                size: 30,
                color: goalReached ? Colors.green : Colors.deepPurple,
              ),
              const SizedBox(height: 5),
              Text(
                "${hoursSlept.toStringAsFixed(1)} hrs",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: goalReached ? Colors.green[700] : Colors.black,
                ),
              ),
              Text(
                "Goal - ${goal.toStringAsFixed(0)} hrs",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              if (!goalReached)
                Text(
                  "${remaining.toStringAsFixed(1)} hrs left",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                ),
              if (goalReached)
                Text(
                  "🎉 Goal Reached!",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
