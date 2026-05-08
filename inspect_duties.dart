import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec?action=bootstrap';
  
  final client = HttpClient();
  
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    
    if (data['duties'] != null && data['duties'].isNotEmpty) {
      print('First duty keys: ${data['duties'][0].keys.toList()}');
      print('First duty data: ${data['duties'][0]}');
    }
    
    if (data['specialists'] != null && data['specialists'].isNotEmpty) {
       print('First specialist keys: ${data['specialists'][0].keys.toList()}');
    }

  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
