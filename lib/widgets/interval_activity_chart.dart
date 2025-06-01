import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/interval_step_entry.dart';

class IntervalActivityChart extends StatelessWidget {
  final List<IntervalStepEntry> intervals;

  const IntervalActivityChart({super.key, required this.intervals});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final expectedSlots = List.generate(288, (i) {
      final time = todayMidnight.add(Duration(minutes: i * 5));
      return DateFormat('HH:mm').format(time);
    });

    // ✅ Dummy intervals for visualization
    final List<IntervalStepEntry> dummyData = List.generate(288, (i) {
      final hour = i ~/ 12;
      int steps = 0;
      if (hour >= 6 && hour < 8) {
        steps = 20 + (i % 10);
      } else if (hour >= 8 && hour < 10) {
        steps = 60 + (i % 20);
      } else if (hour >= 18 && hour < 20) {
        steps = 100 + (i % 30);
      }

      return IntervalStepEntry(
        time: expectedSlots[i],
        steps: steps,
        speed: steps / 5.0,
        intensity: 'brisk walk',
        durationMinutes: 5,
        caloriesBurned: steps * 0.04,
        distanceMeters: steps * 0.8,
        avgAcceleration: 0,
      );
    });

    final intervalMap = {for (var e in dummyData) e.time: e};

    final fullIntervals = expectedSlots.map((slot) {
      return intervalMap[slot] ??
          IntervalStepEntry(
            time: slot,
            steps: 0,
            speed: 0,
            intensity: 'inactive',
            durationMinutes: 5,
            caloriesBurned: 0,
            distanceMeters: 0,
            avgAcceleration: 0,
          );
    }).toList();

    final hasData = fullIntervals.any((e) => e.steps > 0);

    final List<FlSpot> lineSpots = [];
    double cumulative = 0;

    for (int i = 0; i < fullIntervals.length; i++) {
      final entry = fullIntervals[i];
      cumulative += entry.steps;
      lineSpots.add(FlSpot(i.toDouble(), cumulative));
    }

    return hasData
        ? AspectRatio(
            aspectRatio: 1.65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: cumulative + 50,
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      color: Colors.deepOrange,
                      barWidth: 3.5,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 36, // every 3 hrs
                        getTitlesWidget: (value, _) {
                          final totalMinutes = value.toInt() * 5;
                          final hour = totalMinutes ~/ 60;
                          final label = DateFormat('ha').format(
                            DateTime(0).add(Duration(hours: hour)),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              label.toLowerCase(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final e = fullIntervals[spot.x.toInt()];
                        return LineTooltipItem(
                          "🕓 ${e.time}\n"
                          "🚶 ${e.steps} steps\n"
                          "⚡ ${e.intensity}",
                          const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                "No activity recorded yet today.\nStart moving to fill the timeline!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          );
  }
}
