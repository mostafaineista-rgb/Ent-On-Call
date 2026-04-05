import 'lib/utils/date_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('ar', null);
  
  final dates = [
    '2026-04-01', // Wednesday
    '2026-04-02', // Thursday
    '2026-04-03', // Friday
    '2026-04-04', // Saturday
    '2026-04-05', // Sunday
    '2026-04-06', // Monday
    '2026-04-07', // Tuesday
  ];
  
  for (final date in dates) {
    final formatted = DutyDateUtils.formatArabicReadableDate(date);
    print('$date -> $formatted');
  }
}
