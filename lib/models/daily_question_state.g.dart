// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_question_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyQuestionStateAdapter extends TypeAdapter<DailyQuestionState> {
  @override
  final int typeId = 2;

  @override
  DailyQuestionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuestionState(
      date: fields[0] as String,
      selectedQuestionId: fields[1] as int,
      swapCount: fields[2] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuestionState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.selectedQuestionId)
      ..writeByte(2)
      ..write(obj.swapCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
