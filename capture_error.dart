import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbyGlstjMt5TgU_ZDjNFb7jb9yNnU-xcTrEO7QQZpJpomAZzjQSBIRQ-jrH1muldqGgXXw/exec?action=bootstrap';
  
  final client = HttpClient();
  
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    
    String body;
    if (response.statusCode == 302) {
      final loc = response.headers.value('location')!;
      final req2 = await client.getUrl(Uri.parse(loc));
      final res2 = await req2.close();
      body = await res2.transform(utf8.decoder).join();
    } else {
      body = await response.transform(utf8.decoder).join();
    }
    
    print('Body (first 1000 chars):');
    print(body.substring(0, body.length > 1000 ? 1000 : body.length));

  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
