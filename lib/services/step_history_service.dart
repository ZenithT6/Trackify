import 'package:hive/hive.dart';

class StepHistoryService {
  static const String _boxName = 'step_history';

  /// Open or get the Hive box
  static Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Save today's step count
  static Future<void> saveTodaySteps(int steps) async {
    final box = await _getBox();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    await box.put(todayKey, steps);
  }

  /// Get full step history
  static Future<Map<String, int>> getStepHistory() async {
    final box = await _getBox();
    return Map<String, int>.from(box.toMap().map(
      (key, value) => MapEntry(key.toString(), value as int),
    ));
  }

  /// Save steps for a specific date (used for testing or custom input)
  static Future<void> saveSpecificDateSteps(String dateKey, int steps) async {
    final box = await _getBox();
    await box.put(dateKey, steps);
  }
}
