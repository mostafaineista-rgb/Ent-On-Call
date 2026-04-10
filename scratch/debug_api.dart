import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String apiUrl = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  print('Fetching from $apiUrl...');
  
  try {
    final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
    
    String body = '';
    if (response.statusCode == 302 || response.statusCode == 301) {
      final newUrl = response.headers['location'];
      print('Following redirect to $newUrl...');
      final redirectedResponse = await http.get(Uri.parse(newUrl!));
      body = redirectedResponse.body;
    } else {
      body = response.body;
    }
    
    final data = jsonDecode(body);
    print('Keys found in JSON: ${data.keys.toList()}');
    
    if (data.containsKey('specialists_today')) {
      print('specialists_today found! Content: ${data['specialists_today']}');
    }
    
    if (data.containsKey('specialists_daily')) {
      final list = data['specialists_daily'] as List;
      print('specialists_daily found! Length: ${list.length}');
      for (var i = 0; i < (list.length > 5 ? 5 : list.length); i++) {
        print('Entry $i: ${list[i]}');
      }
    }
    
    if (data.containsKey('duties')) {
       final list = data['duties'] as List;
       print('Duties found! Length: ${list.length}');
       for (var i = 0; i < (list.length > 3 ? 3 : list.length); i++) {
         print('Duty $i: ${list[i]}');
       }
    }

  } catch (e) {
    print('Error: $e');
  }
}
