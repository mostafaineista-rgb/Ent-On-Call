import 'dart:convert';
import 'dart:io';

void main() async {
  final urls = [
    'https://script.google.com/macros/s/AKfycbyfc15ga-Pu-JWoaVHi0ww52Vt50dTKcFTSMPHQQCyb2KYAij-8HwdF_4V2pdHqv2Dy_A/exec',
    'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec',
    'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec',
  ];

  final client = HttpClient();
  
  for (var url in urls) {
    print('\n--- TESTING URL: $url ---');
    try {
      final request = await client.getUrl(Uri.parse('$url?action=bootstrap')).timeout(Duration(seconds: 10));
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
        
        try {
          final data = jsonDecode(body);
          print('Keys: ${data.keys.toList()}');
          if (data.containsKey('specialists')) {
            print('SUCCESS: Specialists found! Count: ${data['specialists'].length}');
          }
          if (data.containsKey('specialists_daily')) {
             print('SUCCESS: Specialists daily found! Count: ${data['specialists_daily'].length}');
          }
        } catch (e) {
          print('Failed to decode JSON. Body starts with: ${body.substring(0, body.length > 100 ? 100 : body.length)}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  client.close();
}
