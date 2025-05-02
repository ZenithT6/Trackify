import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../services/step_tracker_service.dart';
import '../services/step_history_service.dart';
import '../widgets/circular_steps_progress.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/step_info.dart';
import '../widgets/steps_insight_card.dart';

class DailyStepsScreen extends StatefulWidget {
  const DailyStepsScreen({super.key});

  @override
  State<DailyStepsScreen> createState() => _DailyStepsScreenState();
}

class _DailyStepsScreenState extends State<DailyStepsScreen> {
  List<int> weeklySteps = List.filled(7, 0);
  int stepGoal = 8000;

  @override
  void initState() {
    super.initState();
    _loadStepGoal();
    _saveTodaySteps();
    _loadWeeklySteps();
  }

  Future<void> _loadStepGoal() async {
    final box = await Hive.openBox('goalBox');
    setState(() {
      stepGoal = box.get('stepsGoal', defaultValue: 8000);
    });
  }

  Future<void> _saveTodaySteps() async {
    final tracker = Provider.of<StepTracker>(context, listen: false);
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final history = await StepHistoryService.getStepHistory();
    if (!history.containsKey(todayKey)) {
      await StepHistoryService.saveTodaySteps(tracker.steps);
    }
  }

  Future<void> _loadWeeklySteps() async {
    try {
      final history = await StepHistoryService.getStepHistory();
      final now = DateTime.now();

      Map<int, int> stepsByWeekday = {for (var i = 0; i < 7; i++) i: 0};

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final key = '${date.year}-${date.month}-${date.day}';
        final weekdayIndex = date.weekday % 7;
        stepsByWeekday[weekdayIndex] = history[key] ?? 0;
      }

      setState(() {
        weeklySteps = List.generate(7, (i) => stepsByWeekday[i] ?? 0);
      });
    } catch (e) {
      debugPrint('Error loading weekly steps: $e');
      setState(() {
        weeklySteps = [2000, 3000, 3500, 4500, 5000, 6000, 7000];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<StepTracker>(context);
    final steps = tracker.steps;

    final distanceKm = (steps * 0.0008).toStringAsFixed(2);
    final calories = (steps * 0.04).toStringAsFixed(0);
    final minutes = (steps / 100).toStringAsFixed(0);

    final todayIndex = DateTime.now().weekday % 7;
    final syncedWeeklySteps = [...weeklySteps];
    syncedWeeklySteps[todayIndex] = steps;

    final totalWeek = syncedWeeklySteps.fold(0, (a, b) => a + b);
    final avg = (totalWeek / 7).toStringAsFixed(0);

    final pastDaysOnly = [
      for (int i = 0; i < syncedWeeklySteps.length; i++)
        if (i != todayIndex) syncedWeeklySteps[i],
    ];
    final high = pastDaysOnly.reduce((a, b) => a > b ? a : b);
    final low = pastDaysOnly.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: RefreshIndicator(
        onRefresh: () async {
          final tracker = Provider.of<StepTracker>(context, listen: false);
          await tracker.saveTodayStepToHive();
          tracker.refreshSteps();
          await _loadWeeklySteps();
          await _loadStepGoal();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFFF0F9FF),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text("Daily Steps",
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressWidget(stepCount: steps, goalSteps: stepGoal),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StepInfo(icon: FontAwesomeIcons.clock, text: "$minutes mins"),
                        StepInfo(icon: FontAwesomeIcons.locationDot, text: "$distanceKm km"),
                        StepInfo(icon: FontAwesomeIcons.fireFlameSimple, text: "$calories kcal"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Weekly Progress",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 260,
                      child: WeeklyBarChart(
                        weeklySteps: weeklySteps,
                        todaySteps: steps,
                        goal: stepGoal,
                      ),
                    ),
                    StepInsightCard(steps: steps, goal: stepGoal),
                    const SizedBox(height: 20),
                    _buildSummaryPanel(totalWeek, avg, high, low),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(int total, String avg, int high, int low) {
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
          _summaryTile("Total", "$total", FontAwesomeIcons.calculator),
          _summaryTile("Average", avg, FontAwesomeIcons.chartLine),
          _summaryTile("Highest", "$high", FontAwesomeIcons.arrowUp),
          _summaryTile("Lowest", "$low", FontAwesomeIcons.arrowDown),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}