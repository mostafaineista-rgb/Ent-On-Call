import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';

class ApiService {
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbx_jz3sdpZEq-wDiKVkyCuglFYmG7_itoJstcFzVhlnPL1hjBEMI6l0Rnk7u1bCrwXM7Q/exec';
  // Secret key for Apps Script access - provided in requirement
  static const String appsScriptSecret = 'ent_secret_2026';

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
      
      if (response.statusCode == 302) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirectedResponse = await http.get(Uri.parse(newUrl));
          if (redirectedResponse.statusCode == 200) {
            return jsonDecode(redirectedResponse.body);
          }
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data from server. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Resident>> fetchResidents() async {
    final data = await fetchData();
    if (data.containsKey('residents')) {
      return (data['residents'] as List)
          .map((json) => Resident.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Specialist>> fetchSpecialists() async {
    final data = await fetchData();
    if (data.containsKey('specialists')) {
      return (data['specialists'] as List)
          .map((json) => Specialist.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Duty>> fetchDuties() async {
    final data = await fetchData();
    if (data.containsKey('duties')) {
      return (data['duties'] as List)
          .map((json) => Duty.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Specialized updateResident to handle Web CORS issues
  Future<Map<String, dynamic>> updateResidentWeb({
    required String id,
    required String phone,
    String? secret,
  }) async {
    final Map<String, String> body = {
      'action': 'updateResident',
      'secret': secret ?? appsScriptSecret,
      'id': id,
      'phone': phone,
    };

    debugPrint('--- API WEB UPDATE RESIDENT ---');
    debugPrint('Parameters: $body');

    try {
      // Use simple form POST (application/x-www-form-urlencoded) to avoid CORS preflight
      final response = await http.post(
        Uri.parse(apiUrl),
        body: body,
      );

      debugPrint('Web Response Status: ${response.statusCode}');

      // Handle Apps Script redirects (usually 302/303)
      if (response.statusCode == 302 || response.statusCode == 303) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirectedResponse = await http.get(Uri.parse(newUrl));
          if (redirectedResponse.statusCode == 200) {
            return jsonDecode(redirectedResponse.body);
          }
        }
        return {'ok': true, 'message': 'Update sent (redirected)'};
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error during update: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Web Update Error: $e');
      throw Exception('Network error during web update: $e');
    } finally {
      debugPrint('--- END API WEB UPDATE RESIDENT ---');
    }
  }

  Future<Map<String, dynamic>> postAction(String action, Map<String, dynamic> data) async {
    // If it's a web update for a resident, we could redirect here, 
    // but better to use the specialized method for clarity as requested.
    
    final payload = jsonEncode({
      'action': action,
      ...data,
    });
    
    debugPrint('--- API POST REQUEST ---');
    debugPrint('Action: $action');
    debugPrint('Payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: payload,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Initial Response Status: ${response.statusCode}');

      // Google Apps Script 302/303 redirects from POST must be followed with a GET
      if (response.statusCode == 302 || response.statusCode == 303) {
        final newUrl = response.headers['location'];
        debugPrint('Redirect Location: $newUrl');
        
        if (newUrl != null) {
          final redirectedResponse = await http.get(Uri.parse(newUrl));
          debugPrint('Redirected Response Status: ${redirectedResponse.statusCode}');
          debugPrint('Redirected Body: ${redirectedResponse.body}');
          
          if (redirectedResponse.statusCode == 200) {
            return jsonDecode(redirectedResponse.body);
          }
        }
        return {'status': 'success', 'message': 'Action completed (redirect ignored)'};
      }

      if (response.statusCode == 200) {
        debugPrint('Response Body: ${response.body}');
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Post Error: $e');
      throw Exception('Network error during $action: $e');
    } finally {
      debugPrint('--- END API POST REQUEST ---');
    }
  }
}
