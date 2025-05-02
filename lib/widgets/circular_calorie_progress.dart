// 📁 lib/widgets/circular_calorie_progress.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CircularCalorieProgress extends StatelessWidget {
  final int burned;
  final int goal;

  const CircularCalorieProgress({
    super.key,
    required this.burned,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (burned / goal).clamp(0.0, 1.0);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    value >= 1.0
                        ? Colors.green
                        : const Color.fromARGB(255, 255, 123, 0),
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, size: 32, color: Colors.deepOrange),
              const SizedBox(height: 8),
              Text("$burned kcal",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text("of $goal",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
              if (burned >= goal)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text("🎯 Goal Reached!",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                )
            ],
          )
        ],
      ),
    );
  }
}
