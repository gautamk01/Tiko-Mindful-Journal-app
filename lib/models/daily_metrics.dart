import 'package:hive/hive.dart';

part 'daily_metrics.g.dart';

@HiveType(typeId: 1)
class DailyMetrics extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double sleepHours;

  @HiveField(2)
  int moodLevel; // 1-10 scale

  @HiveField(3)
  int waterIntake; // glasses

  @HiveField(4)
  int steps;

  @HiveField(5)
  String? notes;

  DailyMetrics({
    required this.date,
    this.sleepHours = 0,
    this.moodLevel = 5,
    this.waterIntake = 0,
    this.steps = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'sleepHours': sleepHours,
    'moodLevel': moodLevel,
    'waterIntake': waterIntake,
    'steps': steps,
    'notes': notes,
  };

  factory DailyMetrics.fromJson(Map<String, dynamic> json) => DailyMetrics(
    date: DateTime.parse(json['date']),
    sleepHours: (json['sleepHours'] as num).toDouble(),
    moodLevel: json['moodLevel'],
    waterIntake: json['waterIntake'],
    steps: json['steps'],
    notes: json['notes'],
  );
}
