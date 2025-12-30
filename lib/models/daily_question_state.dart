import 'package:hive/hive.dart';

part 'daily_question_state.g.dart';

@HiveType(typeId: 2)
class DailyQuestionState extends HiveObject {
  @HiveField(0)
  String date; // YYYY-MM-DD format

  @HiveField(1)
  int selectedQuestionId;

  @HiveField(2)
  int swapCount; // 0 or 1 (can swap only once per day)

  DailyQuestionState({
    required this.date,
    required this.selectedQuestionId,
    this.swapCount = 0,
  });

  bool get canSwap => swapCount < 1;

  DailyQuestionState copyWith({
    String? date,
    int? selectedQuestionId,
    int? swapCount,
  }) {
    return DailyQuestionState(
      date: date ?? this.date,
      selectedQuestionId: selectedQuestionId ?? this.selectedQuestionId,
      swapCount: swapCount ?? this.swapCount,
    );
  }
}
