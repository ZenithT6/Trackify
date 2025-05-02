import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:hive/hive.dart';

class StepTracker extends ChangeNotifier {
  int _todaySteps = 0;
  int _baseline = 0;
  late StreamSubscription<StepCount> _stepSubscription;

  int get steps => _todaySteps;

  StepTracker() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadBaselineAndSteps();
    _listenToPedometer();
    _checkMidnightReset();

    // ✅ Auto-save every 60 seconds
    Timer.periodic(const Duration(minutes: 1), (_) async {
      await saveTodayStepToHive();
    });
  }

  void _listenToPedometer() {
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) {
    final currentSteps = event.steps;
    _todaySteps = currentSteps - _baseline;
    notifyListeners();
  }

  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  Future<void> _loadBaselineAndSteps() async {
    final box = await Hive.openBox('stepBox');
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    _baseline = box.get('baseline', defaultValue: 0);
    _todaySteps = box.get(todayKey, defaultValue: 0);

    notifyListeners();
  }

  Future<void> saveTodayStepToHive() async {
    final box = await Hive.openBox('stepBox');
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    await box.put(todayKey, _todaySteps);
  }

  Future<void> _resetStepsAtMidnight() async {
    final box = await Hive.openBox('stepBox');
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    await box.put(todayKey, _todaySteps);

    final latestSteps = _todaySteps + _baseline;
    _baseline = latestSteps;
    _todaySteps = 0;

    await box.put('baseline', _baseline);

    notifyListeners();
  }

  void _checkMidnightReset() {
    Timer.periodic(const Duration(minutes: 1), (_) async {
      final now = DateTime.now();
      final box = await Hive.openBox('stepBox');
      final lastCheck = box.get('lastReset') ?? '';
      final today = '${now.year}-${now.month}-${now.day}';

      if (lastCheck != today && now.hour == 0 && now.minute < 5) {
        await _resetStepsAtMidnight();
        await box.put('lastReset', today);
      }
    });
  }

  void refreshSteps() {
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSubscription.cancel();
    saveTodayStepToHive(); // ✅ Save on app exit
    super.dispose();
  }
}
