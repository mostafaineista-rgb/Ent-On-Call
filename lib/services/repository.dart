import 'package:flutter/foundation.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'service_locator.dart';

class Repository {
  final ApiService _apiService = getIt<ApiService>();
  final CacheService _cacheService = getIt<CacheService>();

  Future<void> clearCache() async {
    await _cacheService.clearAll();
  }

  Future<void> refreshData() async {
    debugPrint('Repository: Starting data refresh...');
    try {
      final data = await _apiService.fetchData();
      debugPrint('Repository: Received data keys: ${data.keys.toList()}');
      
      // On web, compute() doesn't work (no real isolates) — parse on main thread.
      // On native, use compute() for background parsing.
      final _ParsedBootstrapData parsedData;
      if (kIsWeb) {
        parsedData = _parseBootstrapData(data);
      } else {
        parsedData = await compute(_parseBootstrapData, data);
      }

      // Parallelize saving to cache
      final List<Future> saveFutures = [];
      
      if (parsedData.residents != null) {
        saveFutures.add(_cacheService.saveResidents(parsedData.residents!));
      }
      
      if (parsedData.specialists != null) {
        saveFutures.add(_cacheService.saveSpecialists(parsedData.specialists!));
      }
      
      if (parsedData.duties != null) {
        saveFutures.add(_cacheService.saveDuties(parsedData.duties!));
      }
      
      if (parsedData.dailyAssignments != null) {
        saveFutures.add(_cacheService.saveDailySpecialists(parsedData.dailyAssignments!));
      }

      await Future.wait(saveFutures);
    } catch (e) {
      debugPrint('Repository: Refresh failed with error: $e');
      rethrow;
    }
  }

  Future<List<Resident>> getResidents() async {
    return await _cacheService.getResidents();
  }

  Future<List<Specialist>> getSpecialists() async {
    return await _cacheService.getSpecialists();
  }

  Future<List<Duty>> getDuties() async {
    return await _cacheService.getDuties();
  }

  Future<List<DailySpecialistAssignment>> getDailySpecialists() async {
    return await _cacheService.getDailySpecialists();
  }

  // Admin Actions - Residents
  Future<void> createResident(Resident resident, String password) async {
    await _apiService.postAction('updateResident', {
      ...resident.toJson(),
      'password': password,
    });
    // Add a delay for GS sync
    await Future.delayed(const Duration(seconds: 3));
    await refreshData();
  }

  Future<void> updateResident(Resident resident) async {
    await _apiService.postAction('updateResident', resident.toJson());
    await Future.delayed(const Duration(seconds: 3));
    await refreshData();
  }

  Future<void> toggleResidentStatus(String id, bool isActive) async {
    await _apiService.postAction('updateResident', {
      'id': id,
      'is_active': isActive,
    });
    await Future.delayed(const Duration(seconds: 3));
    await refreshData();
  }

  Future<void> resetResidentPassword(String id, String newPassword) async {
    await _apiService.postAction('updateResident', {
      'id': id,
      'password': newPassword,
    });
  }

  // Admin Actions - Specialists
  Future<void> updateSpecialist(Specialist specialist) async {
    await _apiService.postAction('updateSpecialist', {
      ...specialist.toJson(),
      'secret': ApiService.appsScriptSecret,
    });
    await Future.delayed(const Duration(seconds: 3));
    await refreshData();
  }

  Future<void> toggleSpecialistStatus(String id, bool isActive) async {
    await _apiService.postAction('updateSpecialist', {
      'id': id,
      'is_active': isActive,
      'secret': ApiService.appsScriptSecret,
    });
    await Future.delayed(const Duration(seconds: 3));
    await refreshData();
  }

  // Admin Actions - Duties
  Future<void> addDuty(Duty duty) async {
    await _apiService.postAction('add_duty', duty.toJson());
    await refreshData();
  }

  Future<void> updateDuty(Duty duty) async {
    await _apiService.postAction('update_duty', duty.toJson());
    await refreshData();
  }

  Future<void> deleteDuty(String dutyId) async {
    await _apiService.postAction('delete_duty', {'id': dutyId});
    await refreshData();
  }

  Future<void> importSchedule(List<Duty> duties) async {
    await _apiService.postAction('import_schedule', {
      'duties': duties.map((d) => d.toJson()).toList(),
    });
    await refreshData();
  }
}

// Helper class for parsed data
class _ParsedBootstrapData {
  final List<Resident>? residents;
  final List<Specialist>? specialists;
  final List<Duty>? duties;
  final List<DailySpecialistAssignment>? dailyAssignments;

  _ParsedBootstrapData({
    this.residents,
    this.specialists,
    this.duties,
    this.dailyAssignments,
  });
}

// Top-level function for compute
_ParsedBootstrapData _parseBootstrapData(Map<String, dynamic> data) {
  T? findData<T>(List<String> possibleKeys) {
    for (var key in possibleKeys) {
      if (data.containsKey(key) && data[key] is T) return data[key] as T;
      final match = data.keys.firstWhere(
        (k) => k.toLowerCase() == key.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty && data[match] is T) return data[match] as T;
    }
    return null;
  }

  List<Resident>? residents;
  final residentsList = findData<List<dynamic>>(['residents', 'Residents']);
  if (residentsList != null) {
    residents = residentsList.map((json) => Resident.fromJson(json)).toList();
  }

  List<Specialist>? specialists;
  final specialistsList = findData<List<dynamic>>(['specialists', 'Specialists']);
  if (specialistsList != null) {
    specialists = specialistsList.map((json) => Specialist.fromJson(json)).toList();
  }

  List<Duty>? duties;
  final dutiesList = findData<List<dynamic>>(['duties', 'Duties', 'schedule', 'Duty']);
  if (dutiesList != null) {
    duties = dutiesList.map((json) => Duty.fromJson(json)).toList();
  }

  List<DailySpecialistAssignment>? dailyAssignments;
  final dailyList = findData<List<dynamic>>(['specialists_daily', 'specialist_daily', 'daily_specialists']);
  if (dailyList != null) {
    dailyAssignments = dailyList.map((json) => DailySpecialistAssignment.fromJson(json)).toList();
  }

  return _ParsedBootstrapData(
    residents: residents,
    specialists: specialists,
    duties: duties,
    dailyAssignments: dailyAssignments,
  );
}
