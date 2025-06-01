// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interval_step_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IntervalStepEntryAdapter extends TypeAdapter<IntervalStepEntry> {
  @override
  final int typeId = 1;

  @override
  IntervalStepEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntervalStepEntry(
      time: fields[0] as String,
      steps: fields[1] as int,
      speed: fields[2] as double,
      intensity: fields[3] as String,
      durationMinutes: fields[4] as int,
      caloriesBurned: fields[5] as double,
      distanceMeters: fields[6] as double,
      avgAcceleration: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IntervalStepEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.speed)
      ..writeByte(3)
      ..write(obj.intensity)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.caloriesBurned)
      ..writeByte(6)
      ..write(obj.distanceMeters)
      ..writeByte(7)
      ..write(obj.avgAcceleration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntervalStepEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
