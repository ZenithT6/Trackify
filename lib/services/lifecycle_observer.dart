import 'package:flutter/widgets.dart';
import 'step_tracker_service.dart';

class MyAppLifecycleObserver with WidgetsBindingObserver {
  final StepTracker stepTracker;

  MyAppLifecycleObserver(this.stepTracker);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      stepTracker.saveTodayStepToHive(); // Save on app background or close
    }
  }
}
