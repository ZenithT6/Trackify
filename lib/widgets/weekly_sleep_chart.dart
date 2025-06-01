import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklySleepChart extends StatelessWidget {
  final List<double> sleepHours;
  final double goal;

  const WeeklySleepChart({
    super.key,
    required this.sleepHours,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday % 7;
    final maxY = [
      ...sleepHours,
      goal
    ].reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                final i = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    i == todayIndex ? 'Today' : days[i],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(7, (i) {
          final isToday = i == todayIndex;
          final value = sleepHours[i];
          final gradient = LinearGradient(
            colors: isToday
                ? [Colors.deepPurpleAccent, Colors.deepPurple]
                : [Colors.indigo, Colors.indigoAccent],
          );
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                width: isToday ? 22 : 18,
                borderRadius: BorderRadius.circular(6),
                gradient: gradient,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey[200],
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
