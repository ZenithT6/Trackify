import 'package:flutter/material.dart';

class SleepQualityIndicator extends StatelessWidget {
  final double lightSleepHours;
  final double deepSleepHours;
  final double remSleepHours;
  final double goalHours;

  const SleepQualityIndicator({
    super.key,
    required this.lightSleepHours,
    required this.deepSleepHours,
    required this.remSleepHours,
    required this.goalHours,
  });

  @override
  Widget build(BuildContext context) {
    double lightPercent = lightSleepHours / goalHours;
    double deepPercent = deepSleepHours / goalHours;
    double remPercent = remSleepHours / goalHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStageLabel("💤 Light", lightSleepHours),
              _buildStageLabel("🌙 Deep", deepSleepHours),
              _buildStageLabel("🧠 REM", remSleepHours),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              _buildSegment(lightPercent, Colors.lightBlue),
              _buildSegment(deepPercent, Colors.blue),
              _buildSegment(remPercent, Colors.deepPurple),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Summary Tag
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Good Sleep Quality",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageLabel(String label, double hours) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          "${hours.toStringAsFixed(1)}h",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSegment(double percentage, Color color) {
    return Expanded(
      flex: (percentage * 1000).toInt(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        height: 16,
        color: color,
      ),
    );
  }
}
