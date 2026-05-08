import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  
  final client = HttpClient();
  
  print('--- TESTING USER-PROVIDED URL ---');
  try {
    // Using action=bootstrap which is what the app uses
    final request = await client.getUrl(Uri.parse('$url?action=bootstrap')).timeout(Duration(seconds: 60));
    final response = await request.close();
    print('Status: ${response.statusCode}');
    
    String body;
    if (response.statusCode == 302 || response.statusCode == 301) {
      final loc = response.headers.value('location')!;
      print('Redirecting...');
      final req2 = await client.getUrl(Uri.parse(loc));
      final res2 = await req2.close();
      body = await res2.transform(utf8.decoder).join();
    } else {
      body = await response.transform(utf8.decoder).join();
    }
    
    final data = jsonDecode(body);
    print('Keys: ${data.keys.toList()}');
    
    if (data.containsKey('specialists_daily')) {
      print('SUCCESS: specialists_daily found!');
    } else {
      print('FAILURE: specialists_daily missing from keys.');
    }
    
    if (data.containsKey('specialists_today')) {
       print('specialists_today found: ${data['specialists_today']}');
    }

  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
