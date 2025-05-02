import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import '../widgets/weekly_sleep_chart.dart';
import '../widgets/sleep_insight_card.dart';
import '../widgets/circular_sleep_progress.dart';
import '../widgets/sleep_stage_chart.dart';
import '../models/sleep_stage.dart';
import '../services/sleep_history_service.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with WidgetsBindingObserver {
  List<double> weeklySleep = List.filled(7, 0);
  List<SleepStage> sleepStages = [
    SleepStage(type: 'Light', hours: 3.0),
    SleepStage(type: 'Deep', hours: 2.0),
    SleepStage(type: 'REM', hours: 2.5),
  ];
  double todayHours = 7.5;
  double goalHours = 8.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGoal();
    _loadWeeklySleep();
    _loadTodayStages();
    _saveTodaySleep();
  }

  Future<void> _loadGoal() async {
    final goalBox = await Hive.openBox('goalBox');
    setState(() {
      goalHours = goalBox.get('sleepGoal', defaultValue: 8.0);
    });
  }

  Future<void> _saveTodaySleep() async {
    await SleepHistoryService.saveTodaySleep(todayHours);
  }

  Future<void> _loadWeeklySleep() async {
    final history = await SleepHistoryService.getSleepHistory();
    final now = DateTime.now();
    Map<int, double> sleepByWeekday = {for (int i = 0; i < 7; i++) i: 0};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final weekdayIndex = date.weekday % 7;
      sleepByWeekday[weekdayIndex] = history[key] ?? 0;
    }

    setState(() {
      weeklySleep = List.generate(7, (i) => sleepByWeekday[i] ?? 0);
      todayHours = sleepByWeekday[DateTime.now().weekday % 7] ?? 0;
    });
  }

  Future<void> _loadTodayStages() async {
    final stageMap = await SleepHistoryService.getTodaySleepStages();
    if (stageMap != null) {
      setState(() {
        sleepStages = [
          SleepStage(type: 'Light', hours: stageMap['lightSleep'] ?? 0),
          SleepStage(type: 'Deep', hours: stageMap['deepSleep'] ?? 0),
          SleepStage(type: 'REM', hours: stageMap['remSleep'] ?? 0),
        ];
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTodaySleep();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveTodaySleep();
    }
  }

  String _getBestSleepDay() {
    final index = weeklySleep.indexOf(weeklySleep.reduce(max));
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[index];
  }

  int _calculateConsistency() {
    return weeklySleep.where((h) => h >= goalHours).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = weeklySleep.reduce((a, b) => a + b);
    final avg = (total / 7).toStringAsFixed(1);
    final maxVal = weeklySleep.reduce(max).toStringAsFixed(1);
    final minVal = weeklySleep.reduce(min).toStringAsFixed(1);

    final todayIndex = DateTime.now().weekday % 7;
    weeklySleep[todayIndex] = todayHours;

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
          "Sleep Tracker",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          CircularSleepProgress(hoursSlept: todayHours, goal: goalHours),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "😴 ${todayHours.toStringAsFixed(1)} hrs – ${todayHours >= 8 ? "Well Rested!" : todayHours >= 6.5 ? "Nice Sleep!" : "Needs Improvement"}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SleepStageChart(stages: sleepStages),
          const SizedBox(height: 30),
          const Text("Weekly Sleep", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: WeeklySleepChart(sleepHours: weeklySleep, goal: goalHours,),
          ),
          const SizedBox(height: 30),
          SleepInsightCard(
            bestDay: _getBestSleepDay(),
            average: double.parse(avg),
            consistency: _calculateConsistency(),
          ),
          const SizedBox(height: 30),
          Text("Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildHorizontalStatsPanel(total.toStringAsFixed(1), avg, maxVal, minVal),
        ],
      ),
    );
  }

  Widget _buildHorizontalStatsPanel(String total, String avg, String high, String low) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconStatTile(FontAwesomeIcons.clock, "Total", "$total hrs"),
        _iconStatTile(FontAwesomeIcons.star, "Avg", "$avg hrs"),
        _iconStatTile(FontAwesomeIcons.arrowUp, "Best", "$high hrs"),
        _iconStatTile(FontAwesomeIcons.arrowDown, "Least", "$low hrs"),
      ],
    );
  }

  Widget _iconStatTile(IconData icon, String label, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.21,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withAlpha(25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
