import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';

class CacheService {
  static const String residentsKey = 'ent_oncall_residents';
  static const String dutiesKey = 'ent_oncall_duties';
  static const String specialistsKey = 'ent_oncall_specialists';

  Future<void> saveResidents(List<Resident> residents) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = residents.map((r) => r.toJson()).toList();
    await prefs.setString(residentsKey, jsonEncode(jsonList));
  }

  Future<List<Resident>> getResidents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(residentsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Resident.fromJson(json)).toList();
  }

  Future<void> saveSpecialists(List<Specialist> specialists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = specialists.map((s) => s.toJson()).toList();
    await prefs.setString(specialistsKey, jsonEncode(jsonList));
  }

  Future<List<Specialist>> getSpecialists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(specialistsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Specialist.fromJson(json)).toList();
  }

  Future<void> saveDuties(List<Duty> duties) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = duties.map((d) => d.toJson()).toList();
    await prefs.setString(dutiesKey, jsonEncode(jsonList));
  }

  Future<List<Duty>> getDuties() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(dutiesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Duty.fromJson(json)).toList();
  }
}
