import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import 'web_http_client.dart' if (dart.library.io) 'web_http_client_stub.dart';

class ApiService {
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbzBcWqCUHr3ETfVTNJIiskoIefy3AONlL4ZS3Y-92UcF9pEqNqqcmynimWDLaXYRH09ww/exec';
  // Secret key for Apps Script access - provided in requirement
  static const String appsScriptSecret = 'ent_secret_2026';

  static const String browserUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Future<Map<String, dynamic>> fetchData() async {
    if (kIsWeb) {
      return _fetchDataWeb();
    }

    try {
      // 1. Native GET with browser User-Agent
      final url = '$apiUrl?action=bootstrap';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': browserUserAgent},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 302 || response.statusCode == 301) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirected = await http.get(
            Uri.parse(newUrl),
            headers: {'User-Agent': browserUserAgent},
          ).timeout(const Duration(seconds: 30));
          if (redirected.statusCode == 200) return jsonDecode(redirected.body);
        }
      }
      
      debugPrint('Native GET failed (status ${response.statusCode}). Trying POST fallback...');
    } catch (e) {
      debugPrint('Native GET error: $e. Trying POST fallback...');
    }

    // 2. Native POST Fallback
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'User-Agent': browserUserAgent},
        body: {'action': 'bootstrap', 'secret': appsScriptSecret},
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) return jsonDecode(response.body);
      
      // Manual redirect for POST if needed (though GAS usually returns 200 for successful doPost)
      if (response.statusCode == 302 || response.statusCode == 301) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirected = await http.get(
            Uri.parse(newUrl),
            headers: {'User-Agent': browserUserAgent},
          ).timeout(const Duration(seconds: 30));
          if (redirected.statusCode == 200) return jsonDecode(redirected.body);
        }
      }
      
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      debugPrint('Native POST fallback also failed: $e');
      rethrow;
    }
  }

  /// Web-specific fetch using native fetch().
  /// Simplest approach: use GET which is most compatible with GAS.
  Future<Map<String, dynamic>> _fetchDataWeb() async {
    try {
      debugPrint('Web fetchData: Fetching data via GET...');
      final url = '$apiUrl?action=bootstrap';
      
      try {
        final body = await webFetchGet(url).timeout(const Duration(seconds: 45));
        final Map<String, dynamic> data = jsonDecode(body);
        
        if (data.containsKey('residents') || data.containsKey('duties') || data.containsKey('specialists')) {
          debugPrint('Web fetchData: SUCCESS! Valid data received via GET.');
          return data;
        }
        debugPrint('Web fetchData: GET response missing keys. Trying POST...');
      } catch (e) {
        debugPrint('Web fetchData: GET failed or timed out: $e. Falling back to POST...');
      }
      
      // Fallback to POST
      final postBody = await webFetchPost(apiUrl, {
        'action': 'bootstrap', 
        'secret': appsScriptSecret
      }, userAgent: browserUserAgent).timeout(const Duration(seconds: 45));
      
      final Map<String, dynamic> data = jsonDecode(postBody);
      debugPrint('Web fetchData: SUCCESS! Data received via POST.');
      return data;
    } catch (e) {
      debugPrint('Web fetchData Error (all methods failed): $e');
      rethrow;
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
    final body = {
      'action': action,
      'secret': appsScriptSecret,
      ...data.map((key, value) => MapEntry(key, value.toString())),
    };

    try {
      if (kIsWeb) {
        final responseBody = await webFetchPost(apiUrl, body).timeout(const Duration(seconds: 30));
        if (responseBody.trim().startsWith('{')) {
          return jsonDecode(responseBody);
        }
        return {'status': 'success', 'data': responseBody};
      }

      // Native path
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'User-Agent': browserUserAgent},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 302 || response.statusCode == 301) {
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final redirected = await http.get(Uri.parse(newUrl)).timeout(const Duration(seconds: 30));
          if (redirected.statusCode == 200) return jsonDecode(redirected.body);
        }
      }

      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('API Post Error: $e');
      throw Exception('فشل في إرسال البيانات: $e');
    }
  }
}
