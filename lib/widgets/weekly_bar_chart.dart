import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../screens/day_detail_screen.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<int> weeklySteps;
  final int todaySteps;
  final int goal;

  const WeeklyBarChart({
    super.key,
    required this.weeklySteps,
    required this.todaySteps,
    this.goal = 8000,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> with SingleTickerProviderStateMixin {
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
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    // ✅ Use actual data from widget instead of dummy values
    final weeklySteps = List<int>.from(widget.weeklySteps);
    weeklySteps[todayIndex] = widget.todaySteps;

    final maxY = ([
      ...weeklySteps,
      widget.goal
    ].reduce((a, b) => a > b ? a : b) + 2000).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, animValue, _) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, _) {
                    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    int index = value.toInt();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        index == todayIndex ? "Today" : days[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: index == todayIndex ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData: BarTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final steps = rod.toY.toInt();
                  return BarTooltipItem('$steps steps', const TextStyle(color: Colors.white));
                },
              ),
              touchCallback: (event, response) async {
                if (response == null || response.spot == null) return;

                final index = response.spot!.touchedBarGroup.x;
                final now = DateTime.now();
                final currentDayIndex = (now.weekday - 1) % 7;

                if (event is FlTapUpEvent) {
                  if (await Vibration.hasVibrator()) {
                    Vibration.vibrate(duration: 30);
                  }

                  DateTime selectedDate = now.subtract(Duration(days: currentDayIndex - index));
                  if (index > currentDayIndex) {
                    selectedDate = selectedDate.subtract(const Duration(days: 7));
                  }

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayDetailScreen(date: selectedDate),
                      ),
                    );
                  }
                }
              },
            ),
            barGroups: List.generate(weeklySteps.length, (i) {
              final isToday = i == todayIndex;
              final rawValue = weeklySteps[i].toDouble();
              final animated = rawValue * animValue;
              final goalReached = rawValue >= widget.goal;

              final gradient = LinearGradient(
                colors: isToday && goalReached
                    ? [Colors.greenAccent.shade200, Colors.green.shade700]
                    : isToday
                        ? [Colors.purpleAccent, Colors.deepPurple]
                        : goalReached
                            ? [Colors.green, Colors.greenAccent]
                            : [Colors.blue, Colors.lightBlueAccent],
              );

              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: isToday ? animated * _pulseAnimation.value : animated,
                    width: isToday ? 22 : 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: gradient,
                    borderSide: isToday && goalReached
                        ? const BorderSide(color: Colors.green, width: 2)
                        : BorderSide.none,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
                showingTooltipIndicators: [],
              );
            }),
          ),
        );
      },
    );
  }
}
