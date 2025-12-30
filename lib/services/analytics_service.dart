import 'package:flutter/foundation.dart';

/// Simple analytics service for tracking user events
/// In production, integrate with Firebase Analytics or other providers
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Track app open event
  void trackAppOpen() {
    _logEvent('app_open');
  }

  /// Track daily question shown
  void trackDailyQuestionShown({
    required int questionId,
    required String questionCategory,
  }) {
    _logEvent('daily_question_shown', {
      'question_id': questionId,
      'question_category': questionCategory,
    });
  }

  /// Track entry saved
  void trackEntrySaved({
    required int questionId,
    required bool hasMood,
    required int tagCount,
    required int answerLength,
  }) {
    _logEvent('entry_saved', {
      'question_id': questionId,
      'has_mood': hasMood,
      'tag_count': tagCount,
      'answer_length': answerLength,
    });
  }

  /// Track question swapped
  void trackQuestionSwapped({
    required int oldQuestionId,
    required int newQuestionId,
  }) {
    _logEvent('question_swapped', {
      'old_question_id': oldQuestionId,
      'new_question_id': newQuestionId,
    });
  }

  /// Track notification enabled/disabled
  void trackNotificationToggled({required bool enabled}) {
    _logEvent(enabled ? 'notification_enabled' : 'notification_disabled');
  }

  /// Track notification time changed
  void trackNotificationTimeChanged({
    required int hour,
    required int minute,
  }) {
    _logEvent('notification_time_changed', {
      'hour': hour,
      'minute': minute,
    });
  }

  /// Track speech input used
  void trackSpeechInputUsed({
    required bool successful,
    required int resultLength,
  }) {
    _logEvent('speech_input_used', {
      'successful': successful,
      'result_length': resultLength,
    });
  }

  /// Track entry viewed from history
  void trackEntryViewed({required String date}) {
    _logEvent('entry_viewed', {
      'date': date,
    });
  }

  /// Track entry edited
  void trackEntryEdited({required String date}) {
    _logEvent('entry_edited', {
      'date': date,
    });
  }

  /// Track entry deleted
  void trackEntryDeleted({required String date}) {
    _logEvent('entry_deleted', {
      'date': date,
    });
  }

  /// Track onboarding completed
  void trackOnboardingCompleted() {
    _logEvent('onboarding_completed');
  }

  /// Track screen view
  void trackScreenView(String screenName) {
    _logEvent('screen_view', {
      'screen_name': screenName,
    });
  }

  void _logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    if (kDebugMode) {
      debugPrint('Analytics Event: $eventName');
      if (parameters != null) {
        debugPrint('  Parameters: $parameters');
      }
    }

    // TODO: Integrate with Firebase Analytics or other analytics provider
    // Example:
    // FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: parameters,
    // );
  }
}
