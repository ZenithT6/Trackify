import 'package:health/health.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class HealthService {
  static final Health _health = Health();
  static final Logger _logger = Logger();

  static String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  static String _yesterdayKey() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

  /// 🪪 Centralized permission request
  static Future<bool> requestPermissions(List<HealthDataType> types) async {
    final permissions = List.filled(types.length, HealthDataAccess.READ);
    final granted = await _health.requestAuthorization(types, permissions: permissions);
    if (!granted) _logger.w("❌ Permission not granted for: $types");
    return granted;
  }

  /// 🔁 Sync and save steps from today
  static Future<void> fetchAndSaveSteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final types = [HealthDataType.STEPS];

    if (!await requestPermissions(types)) return;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: midnight,
        endTime: now,
      );

      final values = data
          .map((e) => e.value)
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();

      final totalSteps = values.isNotEmpty ? values.reduce((a, b) => a + b) : 0;
      final box = await Hive.openBox('stepBox');
      await box.put(_todayKey(), totalSteps);

      _logger.i("✅ Steps saved to Hive: $totalSteps");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching steps", error: e, stackTrace: stackTrace);
    }
  }

  /// ❤️ Sync and save heart rate average
  static Future<void> fetchAndSaveHeartRate() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final types = [HealthDataType.HEART_RATE];

    if (!await requestPermissions(types)) return;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: midnight,
        endTime: now,
      );

      final bpmValues = data
          .map((e) => e.value)
          .whereType<num>()
          .map((e) => e.toDouble())
          .where((v) => v > 0)
          .toList();

      if (bpmValues.isEmpty) {
        _logger.w("⚠️ No valid heart rate data");
        return;
      }

      final avgBPM = (bpmValues.reduce((a, b) => a + b) / bpmValues.length).round();
      final box = await Hive.openBox('heartBox');
      await box.put(_todayKey(), avgBPM);

      _logger.i("✅ Heart rate saved to Hive: $avgBPM BPM");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching heart rate", error: e, stackTrace: stackTrace);
    }
  }

  /// 😴 Sync and save total sleep in hours
  static Future<void> fetchAndSaveSleep() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    final types = [HealthDataType.SLEEP_ASLEEP];

    if (!await requestPermissions(types)) return;

    try {
      final data = await _health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
      );

      final totalMinutes = data
          .map((e) => e.value)
          .whereType<num>()
          .fold(0.0, (a, b) => a + b.toDouble());

      final sleepHours = totalMinutes / 60;
      final box = await Hive.openBox('sleepBox');
      await box.put(_todayKey(), sleepHours);

      _logger.i("✅ Sleep saved to Hive: ${sleepHours.toStringAsFixed(2)} hrs");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching sleep data", error: e, stackTrace: stackTrace);
    }
  }

  /// 🌙 Sync and save detailed sleep stages
  static Future<void> fetchAndSaveSleepStages() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    final key = _todayKey();
    final types = [
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
    ];

    if (!await requestPermissions(types)) return;

    try {
      double light = 0, deep = 0, rem = 0;

      for (var type in types) {
        final data = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: now,
        );

        final minutes = data
            .map((e) => e.value)
            .whereType<num>()
            .fold(0.0, (a, b) => a + b.toDouble());

        if (type == HealthDataType.SLEEP_LIGHT) light = minutes / 60;
        if (type == HealthDataType.SLEEP_DEEP) deep = minutes / 60;
        if (type == HealthDataType.SLEEP_REM) rem = minutes / 60;
      }

      final box = await Hive.openBox('sleepBox');
      await box.put(key, {
        'lightSleep': light,
        'deepSleep': deep,
        'remSleep': rem,
        'total': light + deep + rem,
      });

      _logger.i("✅ Sleep stages saved: Light=$light, Deep=$deep, REM=$rem");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching sleep stages", error: e, stackTrace: stackTrace);
    }
  }
}
