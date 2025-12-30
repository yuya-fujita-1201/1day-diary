import 'package:hive/hive.dart';

part 'draft_entry.g.dart';

@HiveType(typeId: 3)
class DraftEntry extends HiveObject {
  @HiveField(0)
  String date; // YYYY-MM-DD format

  @HiveField(1)
  int questionId;

  @HiveField(2)
  String questionText;

  @HiveField(3)
  String answerText;

  @HiveField(4)
  int? mood;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  DateTime lastUpdated;

  DraftEntry({
    required this.date,
    required this.questionId,
    required this.questionText,
    this.answerText = '',
    this.mood,
    List<String>? tags,
    required this.lastUpdated,
  }) : tags = tags ?? [];

  DraftEntry copyWith({
    String? date,
    int? questionId,
    String? questionText,
    String? answerText,
    int? mood,
    List<String>? tags,
    DateTime? lastUpdated,
  }) {
    return DraftEntry(
      date: date ?? this.date,
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      answerText: answerText ?? this.answerText,
      mood: mood ?? this.mood,
      tags: tags ?? List.from(this.tags),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
