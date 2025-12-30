// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DraftEntryAdapter extends TypeAdapter<DraftEntry> {
  @override
  final int typeId = 3;

  @override
  DraftEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DraftEntry(
      date: fields[0] as String,
      questionId: fields[1] as int,
      questionText: fields[2] as String,
      answerText: fields[3] as String? ?? '',
      mood: fields[4] as int?,
      tags: (fields[5] as List?)?.cast<String>() ?? [],
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DraftEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.questionText)
      ..writeByte(3)
      ..write(obj.answerText)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
