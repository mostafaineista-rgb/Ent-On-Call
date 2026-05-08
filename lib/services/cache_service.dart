import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import 'service_locator.dart';

class CacheService {
  static const String residentsKey = 'ent_oncall_residents';
  static const String dutiesKey = 'ent_oncall_duties';
  static const String specialistsKey = 'ent_oncall_specialists';
  static const String dailySpecialistsKey = 'ent_oncall_daily_specialists';

  final SharedPreferences _prefs = getIt<SharedPreferences>();

  Future<void> saveResidents(List<Resident> residents) async {
    final jsonList = residents.map((r) => r.toJson()).toList();
    await _prefs.setString(residentsKey, jsonEncode(jsonList));
  }

  Future<List<Resident>> getResidents() async {
    final jsonString = _prefs.getString(residentsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Resident.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error decoding residents: $e');
      return [];
    }
  }

  Future<void> saveSpecialists(List<Specialist> specialists) async {
    final jsonList = specialists.map((s) => s.toJson()).toList();
    await _prefs.setString(specialistsKey, jsonEncode(jsonList));
  }

  Future<List<Specialist>> getSpecialists() async {
    final jsonString = _prefs.getString(specialistsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Specialist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error decoding specialists: $e');
      return [];
    }
  }

  Future<void> saveDuties(List<Duty> duties) async {
    final jsonList = duties.map((d) => d.toJson()).toList();
    await _prefs.setString(dutiesKey, jsonEncode(jsonList));
  }

  Future<List<Duty>> getDuties() async {
    final jsonString = _prefs.getString(dutiesKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Duty.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error decoding duties: $e');
      return [];
    }
  }

  Future<void> saveDailySpecialists(List<DailySpecialistAssignment> assignments) async {
    final jsonList = assignments.map((a) => a.toJson()).toList();
    await _prefs.setString(dailySpecialistsKey, jsonEncode(jsonList));
  }

  Future<List<DailySpecialistAssignment>> getDailySpecialists() async {
    final jsonString = _prefs.getString(dailySpecialistsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DailySpecialistAssignment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error decoding daily specialists: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    await _prefs.remove(residentsKey);
    await _prefs.remove(specialistsKey);
    await _prefs.remove(dutiesKey);
    await _prefs.remove(dailySpecialistsKey);
    // Also clear auth related keys if any
    await _prefs.remove('ent_oncall_logged_in_user');
    await _prefs.remove('ent_oncall_user_role');
  }
}
