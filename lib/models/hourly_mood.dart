import 'package:hive/hive.dart';

part 'hourly_mood.g.dart';

@HiveType(typeId: 2)
class HourlyMood extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  int mood; // 1-5 scale: 1=😞, 2=😐, 3=🙂, 4=😊, 5=😄

  @HiveField(3)
  String? note;

  HourlyMood({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'note': note,
    };
  }

  factory HourlyMood.fromJson(Map<String, dynamic> json) {
    return HourlyMood(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: json['mood'] as int,
      note: json['note'] as String?,
    );
  }
}
