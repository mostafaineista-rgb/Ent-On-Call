import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec';
  const secret = 'ent_secret_2026';
  
  final client = HttpClient();
  
  print('--- TESTING URL with action=getSpecialistsDaily ---');
  try {
    final request = await client.getUrl(Uri.parse('$url?action=getSpecialistsDaily&secret=$secret')).timeout(Duration(seconds: 20));
    final response = await request.close();
    
    print('Status: ${response.statusCode}');
    String body = await response.transform(utf8.decoder).join();
    
    if (body.startsWith('{')) {
      final data = jsonDecode(body);
      print('Keys: ${data.keys.toList()}');
      if (data.containsKey('data')) {
        print('Data count: ${data['data'].length}');
      }
    } else {
      print('Response: $body');
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
