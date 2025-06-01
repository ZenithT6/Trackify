import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HeartRateZoneChart extends StatelessWidget {
  final Map<String, double> zoneData; // zone name -> percentage

  const HeartRateZoneChart({super.key, required this.zoneData});

  @override
  Widget build(BuildContext context) {
    final zones = zoneData.keys.toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= zones.length) return Container();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      zones[index],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(zones.length, (i) {
            final zone = zones[i];
            final value = zoneData[zone] ?? 0;
            Color color;
            if (zone.toLowerCase().contains('rest')) {
              color = Colors.green;
            } else if (zone.toLowerCase().contains('normal')) {
              color = Colors.orange;
            } else {
              color = Colors.redAccent;
            }
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: color,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Colors.grey[200],
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
} 
