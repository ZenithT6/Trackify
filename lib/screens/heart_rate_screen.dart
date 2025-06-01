import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

import '../widgets/heart_rate_pulse.dart';
import '../widgets/mini_heart_chart.dart';
import '../widgets/heart_rate_zone_chart.dart';
import '../widgets/weekly_heart_chart.dart';
import '../widgets/heart_insight_card.dart';
import '../services/heart_rate_history_service.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> with WidgetsBindingObserver {
  int bpm = 75;
  List<int> trend = [];
  List<int> weeklyBPM = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveHeartRate().then((_) => _loadWeeklyBPM());
    });
  }

  Future<void> _fetchLiveHeartRate() async {
    await HeartRateHistoryService.fetchAndSaveTodayBPM();
    final todayBPM = await HeartRateHistoryService.getTodayBPM();

    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 6));
    final interval = const Duration(minutes: 18); // 6 hours / 20 readings

    final health = Health();

    bool? hasPermission = await health.hasPermissions(
      [HealthDataType.HEART_RATE],
      permissions: [HealthDataAccess.READ],
    );

    bool granted = hasPermission == true
        || await health.requestAuthorization(
            [HealthDataType.HEART_RATE],
            permissions: [HealthDataAccess.READ],
          ) == true;

    if (!granted) {
      final fallbackTrend = List.filled(20, todayBPM);
      setState(() {
        bpm = todayBPM;
        trend = fallbackTrend;
      });
      return;
    }

    List<int> bpmTrend = [];
    for (int i = 0; i < 20; i++) {
      final from = start.add(interval * i);
      final to = from.add(interval);
      final data = await health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.HEART_RATE],
      );
      final values = data.map((e) => e.value).whereType<num>().toList();
      final avg = values.isEmpty
          ? todayBPM
          : (values.reduce((a, b) => a + b) / values.length).round();
      bpmTrend.add(avg);
    }

    if (mounted) {
      setState(() {
        bpm = todayBPM;
        trend = bpmTrend;
      });
    }
  }

  Future<void> _loadWeeklyBPM() async {
    final history = await HeartRateHistoryService.getBPMHistory();
    final now = DateTime.now();
    final bpmByWeekday = Map<int, int>.fromIterable(
      List.generate(7, (i) => i),
      value: (_) => 0,
    );

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final weekdayIndex = date.weekday % 7;
      bpmByWeekday[weekdayIndex] = history[key] ?? 0;
    }

    final todayIndex = now.weekday % 7;
    bpmByWeekday[todayIndex] = bpm;

    setState(() {
      weeklyBPM = List.generate(7, (i) => bpmByWeekday[i] ?? 0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLiveHeartRate().then((_) => _loadWeeklyBPM());
    }
  }

  String _getStatus(int bpm) {
    if (bpm < 65) return "Resting";
    if (bpm < 85) return "Normal";
    return "Elevated";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Resting":
        return Colors.green;
      case "Normal":
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus(bpm);
    final color = _getStatusColor(status);

    final avg = trend.isNotEmpty
        ? (trend.reduce((a, b) => a + b) ~/ trend.length)
        : 0;
    final maxBPM = trend.isNotEmpty ? trend.reduce(max) : 0;
    final minBPM = trend.isNotEmpty ? trend.reduce(min) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Heart Rate",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchLiveHeartRate();
            await _loadWeeklyBPM();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            children: [
              HeartRatePulse(bpm: bpm),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text("Last 20 Readings", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              MiniHeartChart(data: trend),
              const SizedBox(height: 30),
              HeartRateZoneChart(
                zoneData: {
                  "Resting": 35.0,
                  "Normal": 50.0,
                  "Elevated": 15.0,
                },
              ),
              const SizedBox(height: 30),
              HeartInsightCard(avgBPM: avg),
              const SizedBox(height: 30),
              const Text("Weekly Avg BPM", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: WeeklyHeartChart(
                  weeklyBPM: weeklyBPM,
                  todayBPM: bpm,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statTile("Avg BPM", avg.toString(), FontAwesomeIcons.heart),
                  _statTile("Max BPM", maxBPM.toString(), FontAwesomeIcons.arrowUp),
                  _statTile("Min BPM", minBPM.toString(), FontAwesomeIcons.arrowDown),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
