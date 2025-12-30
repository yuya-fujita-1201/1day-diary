import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/daily_question_state.dart';
import '../models/draft_entry.dart';
import '../models/question.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../data/question_pool.dart';

class DiaryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analytics = AnalyticsService();
  final Uuid _uuid = const Uuid();

  Question? _todayQuestion;
  DailyQuestionState? _todayState;
  DraftEntry? _currentDraft;
  DiaryEntry? _todayEntry;
  List<DiaryEntry> _allEntries = [];
  AppSettings _settings = AppSettings();

  bool _isLoading = false;
  String? _error;

  // Getters
  Question? get todayQuestion => _todayQuestion;
  DailyQuestionState? get todayState => _todayState;
  DraftEntry? get currentDraft => _currentDraft;
  DiaryEntry? get todayEntry => _todayEntry;
  List<DiaryEntry> get allEntries => _allEntries;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get canSwapQuestion => _todayState?.canSwap ?? true;
  bool get hasEntryToday => _todayEntry != null;
  int get entryCount => _db.entryCount;
  int get streak => _db.getStreak();

  String get todayDateString => _formatDate(DateTime.now());

  /// Initialize provider
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.init();
      await _notificationService.init();

      _settings = _db.getSettings();
      await _loadTodayData();
      _allEntries = _db.getAllDiaryEntries();

      _analytics.trackAppOpen();
    } catch (e) {
      _error = 'データの読み込みに失敗しました: $e';
      if (kDebugMode) {
        debugPrint('DiaryProvider init error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load today's question and entry
  Future<void> _loadTodayData() async {
    final today = todayDateString;
    
    // Load today's entry if exists
    _todayEntry = _db.getDiaryEntryByDate(today);

    // Load or create question state for today
    _todayState = _db.getQuestionState(today);
    
    if (_todayState == null) {
      // New day - select question based on date seed
      final question = QuestionPool.getQuestionForDate(DateTime.now());
      _todayState = DailyQuestionState(
        date: today,
        selectedQuestionId: question.questionId,
        swapCount: 0,
      );
      await _db.saveQuestionState(_todayState!);
      _todayQuestion = question;
    } else {
      // Load the selected question
      _todayQuestion = QuestionPool.getQuestionById(_todayState!.selectedQuestionId);
    }

    // Load draft if exists and no entry for today
    if (_todayEntry == null) {
      _currentDraft = _db.getDraft(today);
    }

    // Track question shown
    if (_todayQuestion != null) {
      _analytics.trackDailyQuestionShown(
        questionId: _todayQuestion!.questionId,
        questionCategory: _todayQuestion!.category ?? 'unknown',
      );
    }
  }

  /// Swap today's question (can only do once per day)
  Future<bool> swapQuestion() async {
    if (!canSwapQuestion || _todayQuestion == null) {
      return false;
    }

    try {
      final oldQuestionId = _todayQuestion!.questionId;
      final newQuestion = QuestionPool.getAlternateQuestion(
        DateTime.now(),
        _todayQuestion!.questionId,
      );

      await _db.updateSelectedQuestion(todayDateString, newQuestion.questionId);
      
      _todayState = _db.getQuestionState(todayDateString);
      _todayQuestion = newQuestion;

      // Update draft if exists
      if (_currentDraft != null) {
        _currentDraft = _currentDraft!.copyWith(
          questionId: newQuestion.questionId,
          questionText: newQuestion.text,
          lastUpdated: DateTime.now(),
        );
        await _db.saveDraft(_currentDraft!);
      }

      _analytics.trackQuestionSwapped(
        oldQuestionId: oldQuestionId,
        newQuestionId: newQuestion.questionId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = '質問の変更に失敗しました';
      notifyListeners();
      return false;
    }
  }

  /// Save draft automatically
  Future<void> saveDraft({
    required String answerText,
    int? mood,
    List<String>? tags,
  }) async {
    if (_todayQuestion == null) return;

    try {
      _currentDraft = DraftEntry(
        date: todayDateString,
        questionId: _todayQuestion!.questionId,
        questionText: _todayQuestion!.text,
        answerText: answerText,
        mood: mood,
        tags: tags,
        lastUpdated: DateTime.now(),
      );

      await _db.saveDraft(_currentDraft!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Draft save error: $e');
      }
    }
  }

  /// Save diary entry
  Future<bool> saveEntry({
    required String answerText,
    int? mood,
    List<String>? tags,
  }) async {
    if (_todayQuestion == null) {
      _error = '質問が読み込まれていません';
      notifyListeners();
      return false;
    }

    if (answerText.trim().isEmpty) {
      _error = '回答を入力してください';
      notifyListeners();
      return false;
    }

    if (answerText.length > 500) {
      _error = '回答は500文字以内で入力してください';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final entry = DiaryEntry(
        id: _uuid.v4(),
        date: todayDateString,
        questionId: _todayQuestion!.questionId,
        questionText: _todayQuestion!.text,
        answerText: answerText.trim(),
        mood: mood,
        tags: tags?.take(3).toList() ?? [],
        createdAt: now,
        updatedAt: now,
      );

      await _db.saveDiaryEntry(entry);
      await _db.deleteDraft(todayDateString);

      _todayEntry = entry;
      _currentDraft = null;
      _allEntries = _db.getAllDiaryEntries();

      // Update notification schedule
      await _notificationService.onEntrySaved();

      _analytics.trackEntrySaved(
        questionId: entry.questionId,
        hasMood: mood != null,
        tagCount: entry.tags.length,
        answerLength: answerText.length,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = '保存に失敗しました: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update existing entry
  Future<bool> updateEntry({
    required String entryId,
    required String answerText,
    int? mood,
    List<String>? tags,
  }) async {
    try {
      final existingEntry = _db.getDiaryEntry(entryId);
      if (existingEntry == null) {
        _error = '日記が見つかりません';
        notifyListeners();
        return false;
      }

      final updatedEntry = existingEntry.copyWith(
        answerText: answerText.trim(),
        mood: mood,
        tags: tags?.take(3).toList(),
        updatedAt: DateTime.now(),
      );

      await _db.updateDiaryEntry(updatedEntry);

      // Update local state if it's today's entry
      if (existingEntry.date == todayDateString) {
        _todayEntry = updatedEntry;
      }

      _allEntries = _db.getAllDiaryEntries();

      _analytics.trackEntryEdited(date: existingEntry.date);

      notifyListeners();
      return true;
    } catch (e) {
      _error = '更新に失敗しました: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete entry
  Future<bool> deleteEntry(String entryId) async {
    try {
      final entry = _db.getDiaryEntry(entryId);
      if (entry == null) {
        return false;
      }

      await _db.deleteDiaryEntry(entryId);

      if (entry.date == todayDateString) {
        _todayEntry = null;
      }

      _allEntries = _db.getAllDiaryEntries();

      _analytics.trackEntryDeleted(date: entry.date);

      notifyListeners();
      return true;
    } catch (e) {
      _error = '削除に失敗しました: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get entry by date
  DiaryEntry? getEntryByDate(String date) {
    return _db.getDiaryEntryByDate(date);
  }

  /// Get entries for a specific month
  List<DiaryEntry> getEntriesForMonth(int year, int month) {
    return _db.getDiaryEntriesForMonth(year, month);
  }

  /// Get dates with entries
  Set<String> getDatesWithEntries() {
    return _db.getDatesWithEntries();
  }

  /// Update notification settings
  Future<void> updateNotificationSettings({
    bool? enabled,
    int? hour,
    int? minute,
  }) async {
    try {
      if (enabled != null && enabled != _settings.notificationEnabled) {
        _analytics.trackNotificationToggled(enabled: enabled);
      }

      if (hour != null || minute != null) {
        _analytics.trackNotificationTimeChanged(
          hour: hour ?? _settings.notificationHour,
          minute: minute ?? _settings.notificationMinute,
        );
      }

      _settings = _settings.copyWith(
        notificationEnabled: enabled ?? _settings.notificationEnabled,
        notificationHour: hour ?? _settings.notificationHour,
        notificationMinute: minute ?? _settings.notificationMinute,
      );

      await _db.saveSettings(_settings);

      if (_settings.notificationEnabled) {
        await _notificationService.scheduleDailyReminder(
          hour: _settings.notificationHour,
          minute: _settings.notificationMinute,
        );
      } else {
        await _notificationService.cancelAllNotifications();
      }

      notifyListeners();
    } catch (e) {
      _error = '設定の保存に失敗しました';
      notifyListeners();
    }
  }

  /// Update app settings
  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      _settings = newSettings;
      await _db.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      _error = '設定の保存に失敗しました';
      notifyListeners();
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    _settings = _settings.copyWith(hasCompletedOnboarding: true);
    await _db.saveSettings(_settings);
    _analytics.trackOnboardingCompleted();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadTodayData();
    _allEntries = _db.getAllDiaryEntries();
    _settings = _db.getSettings();
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
