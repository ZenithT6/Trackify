import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
    final todayIndex = DateTime.now().weekday % 7;
    final goalReached = widget.todaySteps >= widget.goal;

    final maxY = ([...widget.weeklySteps, widget.goal, widget.todaySteps]
                .reduce((a, b) => a > b ? a : b) +
            2000)
        .toDouble();

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
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipRoundedRadius: 6,
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} steps',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            barGroups: List.generate(widget.weeklySteps.length, (i) {
              final isToday = i == todayIndex;
              final value = isToday
                  ? widget.todaySteps.toDouble()
                  : widget.weeklySteps[i].toDouble();

              final animated = value * animValue;

              final gradient = LinearGradient(
                colors: isToday && goalReached
                    ? [Colors.greenAccent.shade200, Colors.green.shade700]
                    : isToday
                        ? [Colors.purpleAccent, Colors.deepPurple]
                        : value >= widget.goal
                            ? [Colors.green, Colors.greenAccent]
                            : [Colors.blue, Colors.lightBlueAccent],
              );

              final rod = BarChartRodData(
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
              );

              return BarChartGroupData(
                x: i,
                barRods: [rod],
                showingTooltipIndicators: [],
              );
            }),
          ),
        );
      },
    );
  }
}
