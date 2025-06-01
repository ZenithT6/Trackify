import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/interval_step_entry.dart';

class IntervalStepService {
  static const String boxName = 'intervalStepsBox';

  static String getCurrentTimeSlot() {
    final now = DateTime.now();
    final roundedMinute = (now.minute ~/ 5) * 5;
    return DateFormat('HH:mm').format(
      DateTime(now.year, now.month, now.day, now.hour, roundedMinute),
    );
  }

  static String getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static Future<void> saveStepsForCurrentInterval(int currentSteps) async {
    final box = Hive.box<List>(boxName);
    final userBox = Hive.box('userBox');

    final dateKey = getTodayKey();
    final timeSlot = getCurrentTimeSlot();

    double stepLength = 0.8; // fallback
    final height = userBox.get('height');
    if (height != null && height is double) {
      stepLength = (height * 0.415) / 100;
    }

    double weightKg = 65.0; // fallback
    final weight = userBox.get('weight');
    if (weight != null && weight is double) {
      weightKg = weight;
    }

    List<IntervalStepEntry> intervalList = [];
    if (box.containsKey(dateKey)) {
      intervalList = List<IntervalStepEntry>.from(box.get(dateKey)!);
    }

    int lastSteps = intervalList.isNotEmpty ? intervalList.last.steps : 0;
    int deltaSteps = currentSteps - lastSteps;
    if (deltaSteps < 0) deltaSteps = 0;

    double speed = deltaSteps / 5.0;

    String intensity = "inactive";
    double met = 1.0;
    double avgAccel = 0.0; // placeholder for now

    if (deltaSteps > 0) {
      if (speed < 60) {
        intensity = "slow walk";
        met = 2.5;
      } else if (speed < 120) {
        intensity = "brisk walk";
        met = 4.3;
      } else {
        intensity = "jog/run";
        met = 8.0;
      }
    }

    const int durationMinutes = 5;
    final double durationHours = durationMinutes / 60.0;
    final double caloriesBurned = met * weightKg * durationHours;
    final double distanceMeters = stepLength * deltaSteps;

    final newEntry = IntervalStepEntry(
      time: timeSlot,
      steps: currentSteps,
      speed: speed,
      intensity: intensity,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      distanceMeters: distanceMeters,
      avgAcceleration: avgAccel,
    );

    final existingIndex = intervalList.indexWhere((e) => e.time == timeSlot);
    if (existingIndex != -1) {
      intervalList[existingIndex] = newEntry;
    } else {
      intervalList.add(newEntry);
    }

    await box.put(dateKey, intervalList);

    // ✅ Clean up old entries beyond 7 days
    await _purgeOldIntervals(retainDays: 7);
  }

  static Future<List<IntervalStepEntry>> getIntervalsForDate(DateTime date) async {
    final box = Hive.box<List>(boxName);
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (!box.containsKey(key)) return [];
    return List<IntervalStepEntry>.from(box.get(key)!);
  }

  static Future<void> _purgeOldIntervals({int retainDays = 7}) async {
    final box = Hive.box<List>(boxName);
    final now = DateTime.now();

    final keysToKeep = List.generate(retainDays, (i) {
      return DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
    });

    final keysToDelete = box.keys.where((k) => !keysToKeep.contains(k)).toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }
}
