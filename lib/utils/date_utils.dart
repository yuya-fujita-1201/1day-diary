import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('M月d日(E)', 'ja_JP');
  static final DateFormat _displayDateFormatFull = DateFormat('yyyy年M月d日(E)', 'ja_JP');
  static final DateFormat _monthYearFormat = DateFormat('yyyy年M月', 'ja_JP');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Format DateTime to YYYY-MM-DD string
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Parse YYYY-MM-DD string to DateTime
  static DateTime parseDate(String dateString) {
    return _dateFormat.parse(dateString);
  }

  /// Format date for display (e.g., "12月25日(月)")
  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  /// Format date for display with year (e.g., "2024年12月25日(月)")
  static String formatDisplayDateFull(DateTime date) {
    return _displayDateFormatFull.format(date);
  }

  /// Format month and year (e.g., "2024年12月")
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format time (e.g., "21:00")
  static String formatTime(int hour, int minute) {
    final time = DateTime(2000, 1, 1, hour, minute);
    return _timeFormat.format(time);
  }

  /// Get today's date string
  static String get todayString => formatDate(DateTime.now());

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get relative date string
  static String getRelativeDateString(String dateString) {
    final date = parseDate(dateString);
    if (isToday(date)) {
      return '今日';
    } else if (isYesterday(date)) {
      return '昨日';
    } else {
      return formatDisplayDate(date);
    }
  }

  /// Get week day name in Japanese
  static String getWeekdayName(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get the start of the day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of the day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get days in month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get first day of month
  static DateTime firstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// Get last day of month
  static DateTime lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0);
  }
}
