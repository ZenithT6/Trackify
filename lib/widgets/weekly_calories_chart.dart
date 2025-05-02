import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyCaloriesChart extends StatefulWidget {
  final List<int> weeklyCalories;
  final int todayCalories;
  final int goal;

  const WeeklyCaloriesChart({
    super.key,
    required this.weeklyCalories,
    required this.todayCalories,
    required this.goal,
  });

  @override
  State<WeeklyCaloriesChart> createState() => _WeeklyCaloriesChartState();
}

class _WeeklyCaloriesChartState extends State<WeeklyCaloriesChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday % 7;

    final maxY = [
      ...widget.weeklyCalories,
      widget.todayCalories,
      widget.goal
    ].reduce((a, b) => a > b ? a : b) * 1.2;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, animValue, _) {
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
              final value = isToday
                  ? widget.todayCalories.toDouble()
                  : widget.weeklyCalories[i].toDouble();
              final animated = value * animValue;
              final gradient = LinearGradient(
                colors: isToday
                    ? [Colors.deepOrange, Colors.orangeAccent]
                    : [Colors.orange, Colors.orange.shade100],
              );
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: isToday ? animated * _pulseAnimation.value : animated,
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
      },
    );
  }
}
