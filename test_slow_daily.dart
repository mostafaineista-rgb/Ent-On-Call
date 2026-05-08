import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  const secret = 'ent_secret_2026';
  
  final client = HttpClient();
  
  print('--- TESTING SLOW URL with action=getSpecialistsDaily ---');
  try {
    final request = await client.getUrl(Uri.parse('$url?action=getSpecialistsDaily&secret=$secret')).timeout(Duration(seconds: 30));
    final response = await request.close();
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 302) {
      final loc = response.headers.value('location')!;
      print('Redirecting to: $loc');
      final req2 = await client.getUrl(Uri.parse(loc));
      final res2 = await req2.close();
      final body = await res2.transform(utf8.decoder).join();
      if (body.startsWith('{')) {
        final data = jsonDecode(body);
        print('Keys: ${data.keys.toList()}');
      } else {
        print('Response: $body');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
