// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hourly_mood.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HourlyMoodAdapter extends TypeAdapter<HourlyMood> {
  @override
  final int typeId = 2;

  @override
  HourlyMood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HourlyMood(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      mood: fields[2] as int,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HourlyMood obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlyMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
