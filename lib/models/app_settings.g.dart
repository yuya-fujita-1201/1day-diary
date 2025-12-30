// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      notificationEnabled: fields[0] as bool? ?? true,
      notificationHour: fields[1] as int? ?? 21,
      notificationMinute: fields[2] as int? ?? 0,
      isDarkMode: fields[3] as bool? ?? false,
      hasCompletedOnboarding: fields[4] as bool? ?? false,
      hasRequestedNotificationPermission: fields[5] as bool? ?? false,
      hasSpeechRecognitionConsent: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.notificationEnabled)
      ..writeByte(1)
      ..write(obj.notificationHour)
      ..writeByte(2)
      ..write(obj.notificationMinute)
      ..writeByte(3)
      ..write(obj.isDarkMode)
      ..writeByte(4)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(5)
      ..write(obj.hasRequestedNotificationPermission)
      ..writeByte(6)
      ..write(obj.hasSpeechRecognitionConsent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
