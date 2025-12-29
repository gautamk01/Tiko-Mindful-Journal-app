import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  int mood; // 1-10 scale

  @HiveField(5)
  String type; // 'morning' or 'evening'

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  List<String> imagePaths; // Paths to attached images

  @HiveField(8)
  List<String> audioPaths; // Paths to attached audio recordings

  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
    required this.type,
    this.tags = const [],
    this.imagePaths = const [],
    this.audioPaths = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'content': content,
    'mood': mood,
    'type': type,
    'tags': tags,
    'imagePaths': imagePaths,
    'audioPaths': audioPaths,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    date: DateTime.parse(json['date']),
    title: json['title'],
    content: json['content'],
    mood: json['mood'],
    type: json['type'],
    tags: List<String>.from(json['tags'] ?? []),
    imagePaths: List<String>.from(json['imagePaths'] ?? []),
    audioPaths: List<String>.from(json['audioPaths'] ?? []),
  );
}
