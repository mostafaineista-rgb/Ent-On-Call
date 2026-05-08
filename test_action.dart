import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbyfc15ga-Pu-JWoaVHi0ww52Vt50dTKcFTSMPHQQCyb2KYAij-8HwdF_4V2pdHqv2Dy_A/exec';
  const secret = 'ent_secret_2026';
  
  final client = HttpClient();
  
  print('--- TESTING URL with action=getSpecialists ---');
  try {
    final request = await client.getUrl(Uri.parse('$url?action=getSpecialists&secret=$secret')).timeout(Duration(seconds: 20));
    final response = await request.close();
    
    print('Status: ${response.statusCode}');
    String body = await response.transform(utf8.decoder).join();
    
    if (body.startsWith('{')) {
      final data = jsonDecode(body);
      print('Keys: ${data.keys.toList()}');
    } else {
      print('Response: $body');
    }
  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
