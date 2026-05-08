import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec?action=bootstrap';
  
  final client = HttpClient();
  
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    print('Body length: ${body.length}');
    print('First 500 chars: ${body.substring(0, body.length > 500 ? 500 : body.length)}');
    
    final data = jsonDecode(body);
    print('\nAll keys: ${data.keys.toList()}');
    print('Generated at: ${data['generated_at']}');
    
    if (data['duties'] != null && data['duties'] is List) {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      print('Searching for duty on $todayStr');
      final todayDuty = data['duties'].firstWhere((d) => d['duty_date'] == todayStr, orElse: () => null);
      if (todayDuty != null) {
        print('Today duty: $todayDuty');
      } else {
        print('No duty found for today.');
      }
    }

  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
