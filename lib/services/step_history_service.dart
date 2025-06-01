import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class StepHistoryService {
  static const String _boxName = 'step_history';

  /// Open or get the Hive box
  static Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Save today's step count
  static Future<void> saveTodaySteps(int steps) async {
    final box = await _getBox();
    final todayKey = _getTodayKey();
    await box.put(todayKey, steps);
    debugPrint("📝 Saved $steps steps for $todayKey");
  }

  /// Get today's date key
  static String _getTodayKey() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Save steps for a specific date
  static Future<void> saveSpecificDateSteps(String dateKey, int steps) async {
    final box = await _getBox();
    await box.put(dateKey, steps);
    debugPrint("📆 Saved $steps steps for specific date: $dateKey");
  }

  /// Get all saved step history as a sorted map
  static Future<Map<String, int>> getStepHistory() async {
    final box = await _getBox();
    final rawMap = box.toMap().cast<String, dynamic>();

    final Map<String, int> history = {};
    for (var entry in rawMap.entries) {
      if (entry.value is int) {
        history[entry.key] = entry.value;
      } else if (entry.value is String) {
        final parsed = int.tryParse(entry.value);
        if (parsed != null) {
          history[entry.key] = parsed;
        }
      }
    }

    final sortedKeys = history.keys.toList()..sort();
    final sortedMap = {for (var k in sortedKeys) k: history[k]!};

    debugPrint("📦 Loaded step history: $sortedMap");
    return sortedMap;
  }

  /// Get step history for the past 7 days (including today)
  static Future<Map<String, int>> getLast7DaysSteps() async {
    final box = await _getBox();
    final now = DateTime.now();
    final Map<String, int> result = {};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final steps = box.get(key, defaultValue: 0);
      result[key] = steps is int ? steps : int.tryParse(steps.toString()) ?? 0;
    }

    debugPrint("📊 Last 7 days: $result");
    return result;
  }

  /// Print all saved steps in the console
  static Future<void> printAllSteps() async {
    final box = await _getBox();
    debugPrint("🔍 All saved steps:");
    for (var key in box.keys) {
      debugPrint('$key: ${box.get(key)}');
    }
  }

  /// Clear all saved step history
  static Future<void> clearHistory() async {
    final box = await _getBox();
    await box.clear();
    debugPrint('🧹 Step history cleared.');
  }
}
