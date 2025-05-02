import 'package:hive/hive.dart';

class CalorieHistoryService {
  static const String _boxName = 'calorieBox';

  /// 🔁 Save today's calories with date-based key
  static Future<void> saveTodayCalories(int calories) async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    await box.put(key, calories);
  }

  /// 📅 Get today's calorie data
  static Future<int> getTodayCalories() async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    return box.get(key, defaultValue: 0);
  }

  /// 📊 Load calorie data for the past 7 days
  static Future<Map<String, int>> getCalorieHistory() async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    Map<String, int> history = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final value = box.get(key, defaultValue: 0);
      history[key] = value;
    }

    return history;
  }
}
