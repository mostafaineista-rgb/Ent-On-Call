import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';

class ApiService {
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbwsnZHzPeNQKPztYYCwL5W6QXPP4MgugQDrn1EOrBq2BXD7uIGXYdzsMdpS-e67ZNW0jw/exec';
  // Secret key for Apps Script access - provided in requirement
  static const String appsScriptSecret = 'ent_secret_2026';

  Future<Map<String, dynamic>> fetchData() async {
    try {
      debugPrint('ApiService: Fetching bootstrap data from $apiUrl');
      
      if (kIsWeb) {
        debugPrint('ApiService: Running on web, checking for CORS/Redirect issues...');
        try {
          final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
          debugPrint('ApiService Web GET status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final body = response.body;
            debugPrint('ApiService: Received body preview: ${body.length > 100 ? body.substring(0, 100) : body}');
            return jsonDecode(body);
          }
        } catch (e) {
          debugPrint('ApiService Web GET failed (possibly CORS): $e. Trying POST fallback...');
          // Fallback to POST which sometimes handles Apps Script CORS better on Web
          final postResponse = await http.post(
            Uri.parse(apiUrl),
            body: {'action': 'bootstrap'},
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          );
          debugPrint('ApiService Web POST status: ${postResponse.statusCode}');
          if (postResponse.statusCode == 200 || postResponse.statusCode == 302) {
             return jsonDecode(postResponse.body);
          }
        }
      }

      // Default / Native path
      final response = await http.get(Uri.parse('$apiUrl?action=bootstrap'));
      debugPrint('ApiService: Native GET status: ${response.statusCode}');
      
      // Handle Apps Script manual redirects for Native
      if (response.statusCode == 302 || response.statusCode == 301) {
        final newUrl = response.headers['location'];
        debugPrint('ApiService: Redirecting to $newUrl');
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
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error: $e');
      // On some networks, Apps Script might return a 403 or 401 if not shared correctly
      throw Exception('Network error or access denied. Please check connectivity.');
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

  Future<List<DailySpecialistAssignment>> fetchDailySpecialists() async {
    final data = await fetchData();
    final list = data['specialists_daily'] ?? data['specialist_daily'];
    
    List<DailySpecialistAssignment> assignments = [];
    if (list != null && list is List) {
      assignments = list
          .map((json) => DailySpecialistAssignment.fromJson(json))
          .where((a) => a.date.isNotEmpty) // Filter out empty dates
          .toList();
      debugPrint('Loaded ${assignments.length} daily specialist assignments');
    }
    
    // Fallback: If list is empty or doesn't have today, but we have specialists_today key
    if (data.containsKey('specialists_today')) {
      final todayJson = data['specialists_today'];
      debugPrint('Bootstrap contains specialists_today: $todayJson');
      if (todayJson is Map<String, dynamic> && todayJson['date'] != null && todayJson['date'].toString().isNotEmpty) {
        assignments.add(DailySpecialistAssignment.fromJson(todayJson));
      }
    }
    
    return assignments;
  }

  Future<Map<String, dynamic>> postAction(String action, Map<String, dynamic> data) async {
    debugPrint('--- API POST REQUEST ---');
    debugPrint('Action: $action');
    
    try {
      if (kIsWeb) {
        // Use application/x-www-form-urlencoded to avoid CORS preflight (OPTIONS)
        final Map<String, String> body = {
          'action': action,
          'secret': appsScriptSecret,
          ...data.map((key, value) => MapEntry(key, value.toString())),
        };
        
        final response = await http.post(
          Uri.parse(apiUrl),
          body: body,
        );

        debugPrint('Web POST Status: ${response.statusCode}');

        if (response.statusCode == 302 || response.statusCode == 303) {
          final newUrl = response.headers['location'];
          if (newUrl != null) {
            final redirectedResponse = await http.get(Uri.parse(newUrl));
            if (redirectedResponse.statusCode == 200) {
              return jsonDecode(redirectedResponse.body);
            }
          }
          return {'status': 'success', 'message': 'Action sent (redirected)'};
        }

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      }

      // Default / Native path (JSON)
      final payload = jsonEncode({
        'action': action,
        'secret': appsScriptSecret, // Ensure secret is always included
        ...data,
      });
      
      final response = await http.post(
        Uri.parse(apiUrl),
        body: payload,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Initial Response Status: ${response.statusCode}');

      if (response.statusCode == 302 || response.statusCode == 303) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirectedResponse = await http.get(Uri.parse(newUrl));
          if (redirectedResponse.statusCode == 200) {
            return jsonDecode(redirectedResponse.body);
          }
        }
        return {'status': 'success', 'message': 'Action completed (redirect ignored)'};
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Post Error: $e');
      throw Exception('فشل في إرسال البيانات. يرجى التأكد من الإنترنت.');
    } finally {
      debugPrint('--- END API POST REQUEST ---');
    }
  }
}
