import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/interval_step_entry.dart';
import '../services/interval_step_service.dart';
import '../widgets/interval_activity_chart.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;

  const DayDetailScreen({super.key, required this.date});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  List<IntervalStepEntry> intervalData = [];

  @override
  void initState() {
    super.initState();
    _loadIntervalData();
  }

  Future<void> _loadIntervalData() async {
    final data = await IntervalStepService.getIntervalsForDate(widget.date);

    // ✅ Add dummy fallback for demo
    if (data.isEmpty) {
      intervalData = List.generate(288, (i) {
        return IntervalStepEntry(
          time: DateFormat('HH:mm').format(widget.date.add(Duration(minutes: i * 5))),
          steps: i % 20 == 0 ? 20 : 0,
          speed: 1.2,
          intensity: i % 20 == 0 ? 'brisk walk' : 'inactive',
          durationMinutes: 5,
          caloriesBurned: i % 20 == 0 ? 2.5 : 0,
          distanceMeters: i % 20 == 0 ? 10 : 0,
          avgAcceleration: 0.3,
        );
      });
    } else {
      intervalData = data;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEE, MMM d, yyyy').format(widget.date);

    final totalSteps = intervalData.isNotEmpty ? intervalData.last.steps : 0;
    final totalCalories = intervalData.fold(0.0, (sum, e) => sum + e.caloriesBurned);
    final totalDistance = intervalData.fold(0.0, (sum, e) => sum + e.distanceMeters);
    final activeMinutes = intervalData
        .where((e) => e.intensity != "inactive")
        .fold(0, (sum, e) => sum + e.durationMinutes);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          formattedDate,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(totalSteps, totalCalories, totalDistance, activeMinutes),
            const SizedBox(height: 24),
            IntervalActivityChart(intervals: intervalData),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int steps, double cal, double distMeters, int minutes) {
    final distKm = (distMeters / 1000).toStringAsFixed(2);
    final calories = cal.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoColumn(FontAwesomeIcons.shoePrints, "$steps", "Steps"),
          _infoColumn(FontAwesomeIcons.fireFlameSimple, calories, "Calories"),
          _infoColumn(FontAwesomeIcons.clock, "$minutes", "Minutes"),
          _infoColumn(FontAwesomeIcons.locationDot, distKm, "Distance (km)"),
        ],
      ),
    );
  }

  Widget _infoColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
