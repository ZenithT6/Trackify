import 'package:hive/hive.dart';

part 'interval_step_entry.g.dart';

@HiveType(typeId: 1)
class IntervalStepEntry extends HiveObject {
  @HiveField(0)
  String time; // "HH:mm"

  @HiveField(1)
  int steps;

  @HiveField(2)
  double speed;

  @HiveField(3)
  String intensity;

  @HiveField(4)
  int durationMinutes;

  @HiveField(5)
  double caloriesBurned;

  @HiveField(6)
  double distanceMeters;

  @HiveField(7)
  double avgAcceleration; // optional for accuracy

  IntervalStepEntry({
    required this.time,
    required this.steps,
    required this.speed,
    required this.intensity,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.distanceMeters,
    required this.avgAcceleration,
  });
}