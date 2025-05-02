
library health;

enum HealthDataType {
  HEART_RATE,
  STEPS,
  CALORIES,
  SLEEP_ASLEEP,
  SLEEP_AWAKE,
  SLEEP_IN_BED,
  ACTIVE_ENERGY_BURNED,
}

class HealthFactory {
  final bool useHealthConnectIfAvailable;

  HealthFactory({this.useHealthConnectIfAvailable = true});

  Future<bool> requestAuthorization(List<HealthDataType> types) async {
    return true;
  }

  Future<List<Map<String, dynamic>>> getHealthDataFromTypes({
    required DateTime start,
    required DateTime end,
    required List<HealthDataType> types,
  }) async {
    final mockData = <Map<String, dynamic>>[];

    if (types.contains(HealthDataType.HEART_RATE)) {
      mockData.add({
        'type': HealthDataType.HEART_RATE,
        'value': 72.0,
        'unit': 'bpm',
        'date_from': start,
        'date_to': end,
      });
    }

    if (types.contains(HealthDataType.ACTIVE_ENERGY_BURNED)) {
      mockData.add({
        'type': HealthDataType.ACTIVE_ENERGY_BURNED,
        'value': 320.0,
        'unit': 'kcal',
        'date_from': start,
        'date_to': end,
      });
    }

    return mockData;
  }
}
