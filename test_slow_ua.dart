import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec?action=bootstrap';
  
  final client = HttpClient();
  
  print('--- TESTING SLOW URL with User-Agent ---');
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    final response = await request.close();
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 302) {
      final loc = response.headers.value('location')!;
      print('Redirecting to: $loc');
      final req2 = await client.getUrl(Uri.parse(loc));
      req2.headers.add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      final res2 = await req2.close();
      final body = await res2.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      print('Keys: ${data.keys.toList()}');
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
