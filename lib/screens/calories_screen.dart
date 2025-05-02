import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../widgets/weekly_calories_chart.dart';
import '../widgets/circular_calorie_progress.dart';
import '../widgets/calorie_insight_card.dart';
import '../services/calorie_history_service.dart';
import '../services/health_service.dart';

class CaloriesScreen extends StatefulWidget {
  const CaloriesScreen({super.key});

  @override
  State<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen>
    with WidgetsBindingObserver {
  int todayCalories = 0;
  List<int> weeklyCalories = List.filled(7, 0);
  int calorieGoal = 2200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncCalorieSensor();
    _loadGoal();
    _loadWeeklyCalories();
  }

  Future<void> _syncCalorieSensor() async {
    await HealthService.fetchAndSaveCalories();
    final updated = await CalorieHistoryService.getTodayCalories();
    setState(() {
      todayCalories = updated;
    });
  }

  Future<void> _loadGoal() async {
    final goalBox = await Hive.openBox('goalBox');
    setState(() {
      calorieGoal = goalBox.get('calorieGoal', defaultValue: 2200);
    });
  }

  Future<void> _loadWeeklyCalories() async {
    final history = await CalorieHistoryService.getCalorieHistory();
    final now = DateTime.now();
    Map<int, int> caloriesByWeekday = {for (int i = 0; i < 7; i++) i: 0};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final weekdayIndex = date.weekday % 7;
      caloriesByWeekday[weekdayIndex] = history[key] ?? 0;
    }

    setState(() {
      weeklyCalories = List.generate(7, (i) => caloriesByWeekday[i] ?? 0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CalorieHistoryService.saveTodayCalories(todayCalories);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCalorieSensor();
      _loadGoal();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      CalorieHistoryService.saveTodayCalories(todayCalories);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = weeklyCalories.reduce((a, b) => a + b);
    final avg = (total / 7).round();
    final maxVal = weeklyCalories.reduce(max);
    final minVal = weeklyCalories.reduce(min);

    final todayIndex = DateTime.now().weekday % 7;
    weeklyCalories[todayIndex] = todayCalories;

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
          "Calories Burnt",
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
          CircularCalorieProgress(
            burned: todayCalories,
            goal: calorieGoal,
          ),
          const SizedBox(height: 30),
          CalorieInsightCard(
            weeklyCalories: weeklyCalories,
            goal: calorieGoal,
          ),
          const Text("Weekly Chart", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: WeeklyCaloriesChart(
              weeklyCalories: weeklyCalories,
              todayCalories: todayCalories,
              goal: calorieGoal,
            ),
          ),
          const SizedBox(height: 30),
          _buildStatsPanel(total, avg, maxVal, minVal),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(int total, int avg, int high, int low) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statTile("Total", "$total kcal", FontAwesomeIcons.calculator),
              _statTile("Avg", "$avg kcal", FontAwesomeIcons.chartLine),
              _statTile("High", "$high kcal", FontAwesomeIcons.arrowUp),
              _statTile("Low", "$low kcal", FontAwesomeIcons.arrowDown),
            ],
          ),
        ],
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
