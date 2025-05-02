import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeartInsightCard extends StatelessWidget {
  final int avgBPM;

  const HeartInsightCard({super.key, required this.avgBPM});

  @override
  Widget build(BuildContext context) {
    final status = _getZone(avgBPM);
    final message = _getMessage(status);
    final color = _getColor(status);
    final emoji = _getEmoji(status);

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
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
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
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getZone(int bpm) {
    if (bpm < 65) return "Resting";
    if (bpm < 85) return "Normal";
    return "Elevated";
  }

  String _getMessage(String zone) {
    switch (zone) {
      case "Resting":
        return "You're in a calm state. Keep relaxing!";
      case "Normal":
        return "Good job! Your heart is in a healthy range.";
      default:
        return "Your heart rate is elevated. Try resting or breathing exercises.";
    }
  }

  Color _getColor(String zone) {
    switch (zone) {
      case "Resting":
        return Colors.green;
      case "Normal":
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  String _getEmoji(String zone) {
    switch (zone) {
      case "Resting":
        return "😌";
      case "Normal":
        return "💪";
      default:
        return "⚠️";
    }
  }
}
