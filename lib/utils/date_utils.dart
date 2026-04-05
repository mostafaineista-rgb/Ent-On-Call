import 'package:intl/intl.dart';

class DutyDateUtils {
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
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('EEEE، d/M/yyyy', 'ar').format(dateTime);
    } catch (e) {
      // Fallback for non-iso dates or parse errors
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      } catch (_) {}
    }
    return dateString;
  }
}
