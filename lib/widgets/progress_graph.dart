import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressGraph extends StatelessWidget {
  const ProgressGraph({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 50),
              FlSpot(1, 70),
              FlSpot(2, 30),
              FlSpot(3, 90),
              FlSpot(4, 50),
              FlSpot(5, 80),
              FlSpot(6, 60),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
          ),
          LineChartBarData(
            spots: [
              FlSpot(0, 40),
              FlSpot(1, 60),
              FlSpot(2, 20),
              FlSpot(3, 80),
              FlSpot(4, 40),
              FlSpot(5, 70),
              FlSpot(6, 50),
            ],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
          ),
        ],
      ),
    );
  }
}
