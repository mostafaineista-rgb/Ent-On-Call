import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String apiUrl = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  print('Fetching bootstrap data...');
  
  try {
    final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
    
    String body = '';
    if (response.statusCode == 302) {
      final newUrl = response.headers['location'];
      if (newUrl != null) {
        final redirectedResponse = await http.get(Uri.parse(newUrl));
        body = redirectedResponse.body;
      }
    } else {
      body = response.body;
    }

    final data = jsonDecode(body);
    
    print('\n--- ALL KEYS ---');
    print(data.keys.toList());

    if (data.containsKey('specialists_daily')) {
      print('\n--- Specialists Daily (First 2 items) ---');
      final list = data['specialists_daily'] as List;
      for (var i = 0; i < (list.length > 2 ? 2 : list.length); i++) {
        print('Item $i: ${list[i]}');
      }
    } else {
      print('\n--- Specialists Daily key NOT FOUND ---');
    }

    if (data.containsKey('specialists_today')) {
      print('\n--- Specialists Today ---');
      print(data['specialists_today']);
    }

  } catch (e) {
    print('Error: $e');
  }
}
