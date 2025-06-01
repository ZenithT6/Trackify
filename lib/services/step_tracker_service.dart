// 📁 services/step_tracker_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import 'interval_step_service.dart';
import 'motion_analyzer_service.dart';
import 'step_history_service.dart';
import 'firebase_step_service.dart';

class StepTracker extends ChangeNotifier with WidgetsBindingObserver {
  int _todaySteps = 0;
  int _lastSensorSteps = 0;
  late StreamSubscription<StepCount> _stepSubscription;
  late StreamSubscription<MovementStatus> _motionSubscription;

  double totalDistance = 0;
  double totalCalories = 0;
  Duration activeTime = Duration.zero;
  MovementStatus currentStatus = MovementStatus.still;

  DateTime? _lastStepTime;
  late double userHeightMeters;
  late double userWeightKg;

  StepTracker() {
    _initialize();
  }

  int get steps => _todaySteps;
  MovementStatus get status => currentStatus;

  Future<void> _initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await _loadUserProfile();
    await _loadStepProgress();
    await _listenToPedometer();
    _checkMidnightReset();

    MotionAnalyzerService().start();
    _motionSubscription = MotionAnalyzerService().movementStatusStream.listen((status) {
      currentStatus = status;
    });

    Timer.periodic(const Duration(minutes: 1), (_) async {
      await saveProgress();
      await IntervalStepService.saveStepsForCurrentInterval(_todaySteps);
      _checkMidnightReset();
    });
  }

  Future<void> _loadUserProfile() async {
    final userBox = await Hive.openBox('userBox');
    final height = userBox.get('height');
    final weight = userBox.get('weight');
    userHeightMeters = (height is double) ? height / 100 : 1.7;
    userWeightKg = (weight is double) ? weight : 65.0;
  }

  Future<void> _listenToPedometer() async {
    if (!await Permission.activityRecognition.isGranted) return;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("❌ Error initializing pedometer: $e");
    }
  }

  void _onStepCount(StepCount event) {
    final currentSensorSteps = event.steps;
    final delta = currentSensorSteps - _lastSensorSteps;

    if (delta > 0 && delta < 10000) {
      _todaySteps += delta;

      final now = DateTime.now();
      final stepTimeDelta = _lastStepTime != null ? now.difference(_lastStepTime!) : const Duration(seconds: 1);
      _lastStepTime = now;

      final stepLength = userHeightMeters * 0.415;
      final met = switch (currentStatus) {
        MovementStatus.slowWalk => 2.5,
        MovementStatus.briskWalk => 3.5,
        MovementStatus.run => 7.0,
        _ => 1.0,
      };

      final timeInHours = stepTimeDelta.inSeconds / 3600;
      totalDistance += stepLength * delta;
      totalCalories += met * userWeightKg * timeInHours;
      if (currentStatus != MovementStatus.still) {
        activeTime += stepTimeDelta;
      }
    }

    _lastSensorSteps = currentSensorSteps;
    notifyListeners();
  }

  void _onStepCountError(error) {
    debugPrint('❌ Step Count Error: $error');
  }

  Future<void> _loadStepProgress() async {
    final box = await Hive.openBox('stepBox');
    final todayKey = _getTodayKey();

    _todaySteps = box.get(todayKey, defaultValue: 0);
    _lastSensorSteps = box.get('lastSensorSteps', defaultValue: 0);
    totalDistance = box.get('distance', defaultValue: 0.0);
    totalCalories = box.get('calories', defaultValue: 0.0);
    activeTime = Duration(seconds: box.get('activeTimeSeconds', defaultValue: 0));
  }

  Future<void> saveProgress() async {
    final box = await Hive.openBox('stepBox');
    final todayKey = _getTodayKey();

    await box.put(todayKey, _todaySteps);
    await box.put('lastSensorSteps', _lastSensorSteps);
    await box.put('distance', totalDistance);
    await box.put('calories', totalCalories);
    await box.put('activeTimeSeconds', activeTime.inSeconds);

    await StepHistoryService.saveTodaySteps(_todaySteps);
    await FirebaseStepService.saveTodayMetrics(
      steps: _todaySteps,
      distance: totalDistance,
      calories: totalCalories,
      activeTimeSeconds: activeTime.inSeconds,
      intensity: currentStatus.name,
    );
  }

  Future<void> _resetStepsAtMidnight() async {
    await saveProgress();

    _todaySteps = 0;
    totalDistance = 0;
    totalCalories = 0;
    activeTime = Duration.zero;

    _lastSensorSteps = 0;

    final box = await Hive.openBox('stepBox');
    await box.put('lastReset', _getTodayKey());

    notifyListeners();
  }

  Future<void> _checkMidnightReset() async {
    final box = await Hive.openBox('stepBox');
    final lastReset = box.get('lastReset', defaultValue: '');
    final todayKey = _getTodayKey();

    if (lastReset != todayKey) {
      await _resetStepsAtMidnight();
    }
  }

  String _getTodayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      saveProgress();
    }
    if (state == AppLifecycleState.resumed) {
      _checkMidnightReset();
    }
  }

  void refreshSteps() {
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSubscription.cancel();
    _motionSubscription.cancel();
    saveProgress();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
