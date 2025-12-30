import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
import '../models/daily_question_state.dart';
import '../models/draft_entry.dart';
import '../models/app_settings.dart';

class DatabaseService {
  static const String diaryBoxName = 'diary_entries';
  static const String questionStateBoxName = 'question_states';
  static const String draftBoxName = 'drafts';
  static const String settingsBoxName = 'settings';

  late Box<DiaryEntry> _diaryBox;
  late Box<DailyQuestionState> _questionStateBox;
  late Box<DraftEntry> _draftBox;
  late Box<AppSettings> _settingsBox;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiaryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyQuestionStateAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DraftEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    // Open boxes
    _diaryBox = await Hive.openBox<DiaryEntry>(diaryBoxName);
    _questionStateBox = await Hive.openBox<DailyQuestionState>(questionStateBoxName);
    _draftBox = await Hive.openBox<DraftEntry>(draftBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(settingsBoxName);

    _isInitialized = true;
  }

  // ============ Diary Entry Operations ============

  /// Save a new diary entry
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    await _diaryBox.put(entry.id, entry);
  }

  /// Get diary entry by ID
  DiaryEntry? getDiaryEntry(String id) {
    return _diaryBox.get(id);
  }

  /// Get diary entry for a specific date
  DiaryEntry? getDiaryEntryByDate(String date) {
    try {
      return _diaryBox.values.firstWhere((entry) => entry.date == date);
    } catch (e) {
      return null;
    }
  }

  /// Check if entry exists for today
  bool hasEntryForDate(String date) {
    return _diaryBox.values.any((entry) => entry.date == date);
  }

  /// Get all diary entries
  List<DiaryEntry> getAllDiaryEntries() {
    return _diaryBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get diary entries for a month
  List<DiaryEntry> getDiaryEntriesForMonth(int year, int month) {
    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr';
    return _diaryBox.values
        .where((entry) => entry.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Update diary entry
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    await _diaryBox.put(entry.id, entry);
  }

  /// Delete diary entry
  Future<void> deleteDiaryEntry(String id) async {
    await _diaryBox.delete(id);
  }

  /// Get dates with entries (for calendar marking)
  Set<String> getDatesWithEntries() {
    return _diaryBox.values.map((e) => e.date).toSet();
  }

  // ============ Question State Operations ============

  /// Get question state for a date
  DailyQuestionState? getQuestionState(String date) {
    return _questionStateBox.get(date);
  }

  /// Save question state
  Future<void> saveQuestionState(DailyQuestionState state) async {
    await _questionStateBox.put(state.date, state);
  }

  /// Update question state (increment swap count)
  Future<void> incrementSwapCount(String date) async {
    final state = _questionStateBox.get(date);
    if (state != null && state.canSwap) {
      state.swapCount = state.swapCount + 1;
      await state.save();
    }
  }

  /// Update selected question
  Future<void> updateSelectedQuestion(String date, int questionId) async {
    final state = _questionStateBox.get(date);
    if (state != null) {
      state.selectedQuestionId = questionId;
      state.swapCount = state.swapCount + 1;
      await state.save();
    }
  }

  // ============ Draft Operations ============

  /// Get draft for a date
  DraftEntry? getDraft(String date) {
    return _draftBox.get(date);
  }

  /// Save draft
  Future<void> saveDraft(DraftEntry draft) async {
    await _draftBox.put(draft.date, draft);
  }

  /// Delete draft
  Future<void> deleteDraft(String date) async {
    await _draftBox.delete(date);
  }

  /// Check if draft exists
  bool hasDraft(String date) {
    return _draftBox.containsKey(date);
  }

  // ============ Settings Operations ============

  /// Get app settings
  AppSettings getSettings() {
    return _settingsBox.get('settings') ?? AppSettings();
  }

  /// Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings);
  }

  /// Update notification settings
  Future<void> updateNotificationSettings({
    bool? enabled,
    int? hour,
    int? minute,
  }) async {
    final settings = getSettings();
    final updatedSettings = settings.copyWith(
      notificationEnabled: enabled ?? settings.notificationEnabled,
      notificationHour: hour ?? settings.notificationHour,
      notificationMinute: minute ?? settings.notificationMinute,
    );
    await saveSettings(updatedSettings);
  }

  // ============ Utility Methods ============

  /// Close all boxes
  Future<void> close() async {
    await _diaryBox.close();
    await _questionStateBox.close();
    await _draftBox.close();
    await _settingsBox.close();
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    await _diaryBox.clear();
    await _questionStateBox.clear();
    await _draftBox.clear();
    await _settingsBox.clear();
  }

  /// Get entry count
  int get entryCount => _diaryBox.length;

  /// Get consecutive days streak
  int getStreak() {
    final entries = getAllDiaryEntries();
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final dateStr = _formatDate(checkDate);
      if (hasEntryForDate(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // Today doesn't have entry yet, check from yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }
    
    return streak;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
