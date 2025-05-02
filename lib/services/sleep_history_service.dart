
import 'package:hive/hive.dart';

class SleepHistoryService {
  static const _boxName = 'sleepBox';

  static Future<void> saveTodaySleep(double hours) async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';

    final existing = box.get(key);
    if (existing is Map) {
      existing['total'] = hours;
      await box.put(key, existing);
    } else {
      await box.put(key, hours);
    }
  }

  static Future<void> saveTodaySleepStages({
    required double lightSleep,
    required double deepSleep,
    required double remSleep,
  }) async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';

    final existing = box.get(key);
    double total = lightSleep + deepSleep + remSleep;

    if (existing is double) {
      await box.put(key, {
        'total': total,
        'lightSleep': lightSleep,
        'deepSleep': deepSleep,
        'remSleep': remSleep,
      });
    } else if (existing is Map) {
      existing['lightSleep'] = lightSleep;
      existing['deepSleep'] = deepSleep;
      existing['remSleep'] = remSleep;
      existing['total'] = total;
      await box.put(key, existing);
    } else {
      await box.put(key, {
        'total': total,
        'lightSleep': lightSleep,
        'deepSleep': deepSleep,
        'remSleep': remSleep,
      });
    }
  }

  static Future<Map<String, double>> getSleepHistory() async {
    final box = await Hive.openBox(_boxName);
    return box.toMap().map((key, value) {
      if (value is Map && value.containsKey('total')) {
        return MapEntry(key.toString(), (value['total'] as num).toDouble());
      } else {
        return MapEntry(key.toString(), (value as num).toDouble());
      }
    });
  }

  static Future<Map<String, double>?> getTodaySleepStages() async {
    final box = await Hive.openBox(_boxName);
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    final data = box.get(key);

    if (data is Map) {
      return {
        'lightSleep': (data['lightSleep'] ?? 0).toDouble(),
        'deepSleep': (data['deepSleep'] ?? 0).toDouble(),
        'remSleep': (data['remSleep'] ?? 0).toDouble(),
      };
    }

    return null;
  }

  static Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  static Future<void> saveDummySleepToday() async {
    await saveTodaySleepStages(
      lightSleep: 3.0,
      deepSleep: 2.0,
      remSleep: 2.5,
    );
    await saveTodaySleep(7.5);
  }
}
