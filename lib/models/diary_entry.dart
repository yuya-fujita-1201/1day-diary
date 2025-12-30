import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String date; // YYYY-MM-DD format

  @HiveField(2)
  int questionId;

  @HiveField(3)
  String questionText;

  @HiveField(4)
  String answerText;

  @HiveField(5)
  int? mood; // 1-5, nullable

  @HiveField(6)
  List<String> tags; // max 3 tags

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.questionId,
    required this.questionText,
    required this.answerText,
    this.mood,
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  DiaryEntry copyWith({
    String? id,
    String? date,
    int? questionId,
    String? questionText,
    String? answerText,
    int? mood,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      answerText: answerText ?? this.answerText,
      mood: mood ?? this.mood,
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'questionId': questionId,
      'questionText': questionText,
      'answerText': answerText,
      'mood': mood,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      questionId: json['questionId'] as int,
      questionText: json['questionText'] as String,
      answerText: json['answerText'] as String,
      mood: json['mood'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
