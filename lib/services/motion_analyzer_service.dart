// 📁 services/motion_analyzer_service.dart

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum MovementStatus { still, slowWalk, briskWalk, run }

class MotionAnalyzerService {
  static final MotionAnalyzerService _instance = MotionAnalyzerService._internal();
  factory MotionAnalyzerService() => _instance;
  MotionAnalyzerService._internal();

  final StreamController<MovementStatus> _statusController = StreamController<MovementStatus>.broadcast();
  StreamSubscription? _accelerometerSubscription;

  Stream<MovementStatus> get movementStatusStream => _statusController.stream;

  void start() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);
      final movement = _classifyMovement(magnitude);
      _statusController.add(movement);
    });
  }

  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _statusController.close();
  }

  double _calculateMagnitude(double x, double y, double z) {
    const gravity = 9.8;
    final rawMag = sqrt(x * x + y * y + z * z);
    return (rawMag - gravity).abs(); // remove gravity component
  }

  MovementStatus _classifyMovement(double magnitude) {
    if (magnitude < 0.5) return MovementStatus.still;
    if (magnitude < 2.0) return MovementStatus.slowWalk;
    if (magnitude < 4.0) return MovementStatus.briskWalk;
    return MovementStatus.run;
  }
}
