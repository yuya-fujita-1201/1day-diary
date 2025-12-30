import 'package:hive/hive.dart';

part 'question.g.dart';

@HiveType(typeId: 1)
class Question extends HiveObject {
  @HiveField(0)
  int questionId;

  @HiveField(1)
  String text;

  @HiveField(2)
  String? category;

  @HiveField(3)
  bool isActive;

  Question({
    required this.questionId,
    required this.text,
    this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'text': text,
      'category': category,
      'isActive': isActive,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] as int,
      text: json['text'] as String,
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
