// 📁 lib/services/heart_rate_history_service.dart
import 'package:hive/hive.dart';

class HeartRateHistoryService {
  static const String _boxName = 'heartBox';

  static Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

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
