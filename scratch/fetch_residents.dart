import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = 'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec';

void main() async {
  print('Fetching data...');
  try {
    final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
    String body = response.body;
    if (response.statusCode == 302 || response.statusCode == 303 || response.statusCode == 307) {
      final newUrl = response.headers['location']!;
      final redirected = await http.get(Uri.parse(newUrl));
      body = redirected.body;
    }
    
    final data = jsonDecode(body);
    final residents = data['residents'] as List;
    print('Residents loaded: ${residents.length}');
    for (var r in residents) {
      print('ID: ${r['id']} | Name: ${r['name']} | Account: ${r['is_admin'] == true ? "Admin" : "Resident"}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
