// lib/widgets/sleep_stage_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sleep_stage.dart';

class SleepStageChart extends StatelessWidget {
  final List<SleepStage> stages;

  const SleepStageChart({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    final total = stages.fold(0.0, (sum, s) => sum + s.hours);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Sleep Stages", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 30,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: total,
                minY: 0,
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: total,
                      rodStackItems: _buildStackItems(stages),
                      borderRadius: BorderRadius.circular(6),
                      width: MediaQuery.of(context).size.width * 0.75,
                    )
                  ])
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: stages.map((stage) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: _getColor(stage.type)),
                  const SizedBox(width: 6),
                  Text("${stage.type}: ${stage.hours.toStringAsFixed(1)}h"),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  List<BarChartRodStackItem> _buildStackItems(List<SleepStage> stages) {
    double current = 0;
    return stages.map((s) {
      final from = current;
      final to = from + s.hours;
      current = to;
      return BarChartRodStackItem(from, to, _getColor(s.type));
    }).toList();
  }

  Color _getColor(String type) {
    switch (type) {
      case "Light":
        return Colors.blueAccent;
      case "Deep":
        return Colors.indigo;
      case "REM":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
