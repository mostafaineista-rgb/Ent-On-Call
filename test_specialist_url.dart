import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  const secret = 'ent_secret_2026';
  
  final client = HttpClient();
  
  print('--- TESTING URL with secret: $url ---');
  try {
    final request = await client.getUrl(Uri.parse('$url?action=bootstrap&secret=$secret')).timeout(Duration(seconds: 20));
    final response = await request.close();
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 302) {
      String body;
      if (response.statusCode == 302) {
        final loc = response.headers.value('location')!;
        print('Redirecting to: $loc');
        final req2 = await client.getUrl(Uri.parse(loc));
        final res2 = await req2.close();
        body = await res2.transform(utf8.decoder).join();
      } else {
        body = await response.transform(utf8.decoder).join();
      }
      
      final data = jsonDecode(body);
      print('Keys: ${data.keys.toList()}');
      if (data.containsKey('specialists')) {
        print('SUCCESS: Specialists found! Count: ${data['specialists'].length}');
      }
      if (data.containsKey('specialists_daily')) {
        print('SUCCESS: Specialists daily found! Count: ${data['specialists_daily'].length}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
