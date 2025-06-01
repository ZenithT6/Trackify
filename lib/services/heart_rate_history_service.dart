import 'package:hive/hive.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class HeartRateHistoryService {
  static const String _boxName = 'heartBox';
  static final Health _health = Health();
  static final Logger _logger = Logger();

  static Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  static String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// ✅ Fetch and save today's average BPM
  static Future<void> fetchAndSaveTodayBPM() async {
    final types = [HealthDataType.HEART_RATE];
    final permissions = [HealthDataAccess.READ];

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final granted = await _health.requestAuthorization(types, permissions: permissions);
    if (!granted) {
      _logger.w("❌ Heart rate permission not granted");
      return;
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      final values = data
          .map((e) => e.value)
          .whereType<num>()
          .map((e) => e.toDouble())
          .toList();

      if (values.isEmpty) {
        _logger.w("⚠️ No heart rate data found for today");
        return;
      }

      final avgBPM = (values.reduce((a, b) => a + b) / values.length).round();
      await saveTodayBPM(avgBPM);

      _logger.i("✅ Avg heart rate saved to Hive: $avgBPM BPM");
    } catch (e) {
      _logger.e("❌ Error fetching heart rate", error: e);
    }
  }

  static Future<void> saveTodayBPM(int bpm) async {
    final box = await _openBox();
    final key = _dateKey(DateTime.now());
    await box.put(key, bpm);
  }

  static Future<Map<String, int>> getBPMHistory({int days = 7}) async {
    final box = await _openBox();
    final now = DateTime.now();
    Map<String, int> history = {};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      final bpm = box.get(key, defaultValue: 0);
      history[key] = bpm;
    }

    return history;
  }

  static Future<int> getTodayBPM() async {
    final box = await _openBox();
    final key = _dateKey(DateTime.now());
    return box.get(key, defaultValue: 0);
  }
}
