import 'package:intl/intl.dart';

class DutyDateUtils {
  /// Returns the DateTime object of the current duty date (Baghdad time).
  static DateTime getCurrentDutyDateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    DateTime dutyDate = now;
    if (dutyDate.hour < 8) {
      dutyDate = dutyDate.subtract(const Duration(days: 1));
    }
    return dutyDate;
  }

  /// Returns true if the current duty date is Friday.
  static bool isFriday() {
    return getCurrentDutyDateTime().weekday == DateTime.friday;
  }

  /// Returns true if the given date string (YYYY-MM-DD) is Friday.
  static bool isFridayDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return dateTime.weekday == DateTime.friday;
    } catch (_) {
      return false;
    }
  }

  /// Returns the current duty date in YYYY-MM-DD format based on Baghdad time (UTC+3).
  /// A duty day starts at 8:00 AM and ends at 7:59 AM the next day.
  static String getCurrentDutyDate() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    
    DateTime dutyDate = now;
    if (dutyDate.hour < 8) {
      dutyDate = dutyDate.subtract(const Duration(days: 1));
    }
    
    final year = dutyDate.year.toString().padLeft(4, '0');
    final month = dutyDate.month.toString().padLeft(2, '0');
    final day = dutyDate.day.toString().padLeft(2, '0');
    
    return '$year-$month-$day';
  }

  /// Parses YYYY-MM-DD to a more readable Arabic format (e.g. Day, dd/MM/yyyy)
  static String formatArabicReadableDate(String dateString) {
    if (dateString.isEmpty) return 'تاريخ غير معروف';
    try {
      final dateTime = DateTime.parse(dateString);
      // Try fancy Arabic format first
      try {
        return DateFormat('EEEE، d/M/yyyy', 'ar').format(dateTime);
      } catch (intlError) {
        // Fallback to simple format if intl fails on Web
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      // Fallback for non-iso dates
      return dateString;
    }
  }
}
