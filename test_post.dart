import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbyfc15ga-Pu-JWoaVHi0ww52Vt50dTKcFTSMPHQQCyb2KYAij-8HwdF_4V2pdHqv2Dy_A/exec';
  const secret = 'ent_secret_2026';

  final client = HttpClient();
  
  print('--- TESTING POST with secret ---');
  try {
    final request = await client.postUrl(Uri.parse(url)).timeout(Duration(seconds: 15));
    request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
    request.write('action=bootstrap&secret=$secret');
    
    final response = await request.close();
    print('Status: ${response.statusCode}');
    
    String body;
    if (response.statusCode == 302 || response.statusCode == 301) {
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
    } else {
      print('FAILURE: Specialists still missing.');
    }
    
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
