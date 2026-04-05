import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = 'https://script.google.com/macros/s/AKfycbyfc15ga-Pu-JWoaVHi0ww52Vt50dTKcFTSMPHQQCyb2KYAij-8HwdF_4V2pdHqv2Dy_A/exec';

void main() async {
  print('--- ENT ON-CALL LOCAL DIAGNOSTIC ---');
  
  // Step 1: Bootstrap Fetch
  print('\nStep 1: Fetching data with action=bootstrap...');
  try {
    final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 302 || response.statusCode == 200) {
      String body = response.body;
      if (response.statusCode == 302) {
        final newUrl = response.headers['location']!;
        final redirected = await http.get(Uri.parse(newUrl));
        body = redirected.body;
      }
      
      final data = jsonDecode(body);
      if (data['ok'] == true) {
        print('[SUCCESS] Connected to script.');
        print('Residents count: ${data['residents']?.length ?? 0}');
        print('Duties count: ${data['duties']?.length ?? 0}');
        
        if (data['residents'] != null && data['residents'].isNotEmpty) {
          final first = data['residents'][0];
          print('\nTesting Update on resident: ${first['name']} (ID: ${first['id']})');
          
          // Step 2: Update Resident
          print('Step 2: Sending updateResident request...');
          final updatePayload = {
            'action': 'updateResident',
            'id': first['id'],
            'phone': '077054734' // Testing with a valid number
          };
          
          final postResponse = await http.post(
            Uri.parse(apiUrl),
            body: jsonEncode(updatePayload),
            headers: {'Content-Type': 'application/json'}
          );
          
          print('POST Status: ${postResponse.statusCode}');
          
          // Check for redirect
          String postBody = postResponse.body;
          if (postResponse.statusCode == 302 || postResponse.statusCode == 303) {
            final loc = postResponse.headers['location']!;
            final finalRes = await http.get(Uri.parse(loc));
            postBody = finalRes.body;
          }
          
          final updateResult = jsonDecode(postBody);
          print('Update Result: $updateResult');
          
          if (updateResult['ok'] == true) {
            print('\n[FINAL SUCCESS] Script is 100% operational.');
          } else {
            print('\n[FAILURE] Update failed: ${updateResult['message']}');
          }
        }
      } else {
        print('[FAILURE] Script returned error: ${data['message']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
