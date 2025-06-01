// 📁 lib/widgets/calorie_insight_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalorieInsightCard extends StatelessWidget {
  final List<int> weeklyCalories;
  final int goal;

  const CalorieInsightCard({
    super.key,
    required this.weeklyCalories,
    this.goal = 2200,
  });

  @override
  Widget build(BuildContext context) {
    final int mostActiveIndex = _getMostActiveDayIndex();
    final int longestStreak = _getLongestGoalStreak();
    final int metGoalCount = weeklyCalories.where((cals) => cals >= goal).length;

    final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🧠 Calorie Insights",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRow("Most Active Day", days[mostActiveIndex]),
          _buildRow("Longest Goal Streak", "$longestStreak days"),
          _buildRow("Goal Met", "$metGoalCount / 7 days"),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  int _getMostActiveDayIndex() {
    int max = 0;
    for (int i = 1; i < weeklyCalories.length; i++) {
      if (weeklyCalories[i] > weeklyCalories[max]) max = i;
    }
    return max;
  }

  int _getLongestGoalStreak() {
    int current = 0;
    int longest = 0;
    for (int val in weeklyCalories) {
      if (val >= goal) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }
}
