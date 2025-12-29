// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyMetricsAdapter extends TypeAdapter<DailyMetrics> {
  @override
  final int typeId = 1;

  @override
  DailyMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMetrics(
      date: fields[0] as DateTime,
      sleepHours: fields[1] as double,
      moodLevel: fields[2] as int,
      waterIntake: fields[3] as int,
      steps: fields[4] as int,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMetrics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.sleepHours)
      ..writeByte(2)
      ..write(obj.moodLevel)
      ..writeByte(3)
      ..write(obj.waterIntake)
      ..writeByte(4)
      ..write(obj.steps)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
