import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool notificationEnabled;

  @HiveField(1)
  int notificationHour; // 0-23

  @HiveField(2)
  int notificationMinute; // 0-59

  @HiveField(3)
  bool isDarkMode; // null = system, true = dark, false = light

  @HiveField(4)
  bool hasCompletedOnboarding;

  @HiveField(5)
  bool hasRequestedNotificationPermission;

  @HiveField(6)
  bool hasSpeechRecognitionConsent;

  AppSettings({
    this.notificationEnabled = true,
    this.notificationHour = 21,
    this.notificationMinute = 0,
    this.isDarkMode = false,
    this.hasCompletedOnboarding = false,
    this.hasRequestedNotificationPermission = false,
    this.hasSpeechRecognitionConsent = false,
  });

  AppSettings copyWith({
    bool? notificationEnabled,
    int? notificationHour,
    int? notificationMinute,
    bool? isDarkMode,
    bool? hasCompletedOnboarding,
    bool? hasRequestedNotificationPermission,
    bool? hasSpeechRecognitionConsent,
  }) {
    return AppSettings(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasRequestedNotificationPermission: hasRequestedNotificationPermission ?? this.hasRequestedNotificationPermission,
      hasSpeechRecognitionConsent: hasSpeechRecognitionConsent ?? this.hasSpeechRecognitionConsent,
    );
  }

  String get notificationTimeString {
    final hour = notificationHour.toString().padLeft(2, '0');
    final minute = notificationMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
