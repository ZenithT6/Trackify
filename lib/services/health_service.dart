
import 'package:health/health.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

class HealthService {
  static final HealthFactory _health =
      HealthFactory(useHealthConnectIfAvailable: true);
  static final Logger _logger = Logger();

  static Future<void> fetchAndSaveHeartRate() async {
    final types = [HealthDataType.HEART_RATE];
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final granted = await _health.requestAuthorization(types);
    if (!granted) {
      _logger.w("❌ Permission not granted for heart rate");
      return;
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        start: midnight,
        end: now,
        types: types,
      );

      if (data.isEmpty) {
        _logger.i("ℹ️ No heart rate data found for today");
        return;
      }

      final bpmValues = data.map((e) {
        final raw = e['value'];
        if (raw is num) return raw.toDouble();
        return 0.0;
      }).where((value) => value > 0).toList();

      if (bpmValues.isEmpty) {
        _logger.w("⚠️ No valid numeric BPM values found.");
        return;
      }

      final avgBPM =
          (bpmValues.reduce((a, b) => a + b) / bpmValues.length).round();

      final box = await Hive.openBox('heartBox');
      final key = '${now.year}-${now.month}-${now.day}';
      await box.put(key, avgBPM);

      _logger.i("✅ Saved average BPM to Hive: $avgBPM");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching heart rate", error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> fetchAndSaveCalories() async {
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final granted = await _health.requestAuthorization(types);
    if (!granted) {
      _logger.w("❌ Permission not granted for calories");
      return;
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        start: midnight,
        end: now,
        types: types,
      );

      if (data.isEmpty) {
        _logger.i("ℹ️ No calorie data found for today");
        return;
      }

      final calorieValues = data.map((e) {
        final raw = e['value'];
        if (raw is num) return raw.toDouble();
        return 0.0;
      }).where((value) => value > 0).toList();

      if (calorieValues.isEmpty) {
        _logger.w("⚠️ No valid calorie values found.");
        return;
      }

      final totalCalories =
          calorieValues.reduce((a, b) => a + b).round();

      final box = await Hive.openBox('calorieBox');
      final key = '${now.year}-${now.month}-${now.day}';
      await box.put(key, totalCalories);

      _logger.i("✅ Saved calories to Hive: $totalCalories");
    } catch (e, stackTrace) {
      _logger.e("❌ Error fetching calories", error: e, stackTrace: stackTrace);
    }
  }
}
