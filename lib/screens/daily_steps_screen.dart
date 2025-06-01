import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../services/step_tracker_service.dart';
import '../services/step_history_service.dart';
import '../services/interval_step_service.dart';
import '../models/interval_step_entry.dart';

import '../widgets/circular_steps_progress.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/steps_insight_card.dart';
import '../widgets/interval_activity_chart.dart';

class DailyStepsScreen extends StatefulWidget {
  const DailyStepsScreen({super.key});

  @override
  State<DailyStepsScreen> createState() => _DailyStepsScreenState();
}

class _DailyStepsScreenState extends State<DailyStepsScreen> {
  List<int> weeklySteps = List.filled(7, 0);
  List<IntervalStepEntry> intervalData = [];
  int stepGoal = 8000;
  double stepLength = 0.8;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadUserHeight();
    await _loadStepGoal();
    await _saveTodayStepsIfNeeded();
    await _loadWeeklySteps();
    await _loadIntervalSteps();
  }

  Future<void> _loadUserHeight() async {
    final userBox = await Hive.openBox('userBox');
    final height = userBox.get('height');
    if (height != null && height is double) {
      setState(() {
        stepLength = (height * 0.415) / 100;
      });
    }
  }

  Future<void> _loadStepGoal() async {
    final box = await Hive.openBox('goalBox');
    setState(() {
      stepGoal = box.get('stepsGoal', defaultValue: 8000);
    });
  }

  Future<void> _saveTodayStepsIfNeeded() async {
    final tracker = Provider.of<StepTracker>(context, listen: false);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final history = await StepHistoryService.getStepHistory();
    if (!history.containsKey(todayKey) || history[todayKey] == 0) {
      await StepHistoryService.saveTodaySteps(tracker.steps);
    }
  }

  Future<void> _loadWeeklySteps() async {
    try {
      final history = await StepHistoryService.getStepHistory();
      final now = DateTime.now();
      Map<int, int> stepsByWeekday = {for (int i = 0; i < 7; i++) i: 0};
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        final index = (date.weekday - 1) % 7;
        stepsByWeekday[index] = history[key] ?? 0;
      }
      setState(() {
        weeklySteps = List.generate(7, (i) => stepsByWeekday[i] ?? 0);
      });
    } catch (e) {
      debugPrint("❌ Weekly steps loading error: $e");
    }
  }

  Future<void> _loadIntervalSteps() async {
    final data = await IntervalStepService.getIntervalsForDate(DateTime.now());
    setState(() {
      intervalData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = (DateTime.now().weekday - 1) % 7;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: RefreshIndicator(
        onRefresh: _loadAll,
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
              title: Text("Daily Steps", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SliverToBoxAdapter(
              child: Consumer<StepTracker>(builder: (context, tracker, _) {
                final steps = tracker.steps;
                final syncedWeeklySteps = List<int>.from(weeklySteps)..[todayIndex] = steps;

                final totalWeek = syncedWeeklySteps.fold(0, (a, b) => a + b);
                final avg = (totalWeek / 7).toStringAsFixed(0);
                final past = [for (int i = 0; i < syncedWeeklySteps.length; i++) if (i != todayIndex) syncedWeeklySteps[i]];
                final high = past.isNotEmpty ? past.reduce((a, b) => a > b ? a : b) : steps;
                final low = past.isNotEmpty ? past.reduce((a, b) => a < b ? a : b) : steps;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressWidget(stepCount: steps, goalSteps: stepGoal),
                      const SizedBox(height: 20),
                      _buildSummaryStats(tracker),
                      const SizedBox(height: 20),
                      _buildIntervalChart(),
                      const SizedBox(height: 20),
                      StepInsightCard(steps: steps, goal: stepGoal),
                      const SizedBox(height: 20),
                      _buildWeeklyChart(syncedWeeklySteps, steps),
                      const SizedBox(height: 20),
                      _buildSummaryPanel(totalWeek, avg, high, low),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(StepTracker tracker) {
    final spm = tracker.steps > 0 ? (tracker.steps / ((DateTime.now().minute + 1))).toStringAsFixed(1) : "0.0";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _miniStat(Icons.directions_walk, "Movement", tracker.status.name.toUpperCase()),
        _miniStat(Icons.speed, "Speed", "$spm spm"),
        _miniStat(Icons.local_fire_department, "Calories", "${tracker.totalCalories.toStringAsFixed(0)} kcal"),
        _miniStat(Icons.timer_outlined, "Active Time", "${tracker.activeTime.inMinutes} min"),
      ],
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 12)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildIntervalChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📊 24-Hour Activity Chart", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          IntervalActivityChart(intervals: intervalData),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<int> syncedWeeklySteps, int todaySteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weekly Progress", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: WeeklyBarChart(
            weeklySteps: syncedWeeklySteps,
            todaySteps: todaySteps,
            goal: stepGoal,
          ),
        ),
      ],
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
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
