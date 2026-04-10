import 'package:flutter/foundation.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import 'api_service.dart';
import 'cache_service.dart';

class Repository {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  Future<void> refreshData() async {
    try {
      final data = await _apiService.fetchData();
      
      if (data.containsKey('residents')) {
        final residents = (data['residents'] as List)
            .map((json) => Resident.fromJson(json))
            .toList();
        await _cacheService.saveResidents(residents);
      }

      if (data.containsKey('specialists')) {
        final specialists = (data['specialists'] as List)
            .map((json) => Specialist.fromJson(json))
            .toList();
        await _cacheService.saveSpecialists(specialists);
      }

      if (data.containsKey('duties')) {
        final duties = (data['duties'] as List)
            .map((json) => Duty.fromJson(json))
            .toList();
        await _cacheService.saveDuties(duties);
      }

      if (data.containsKey('specialists_daily')) {
        final dailySpecialists = (data['specialists_daily'] as List)
            .map((json) => DailySpecialistAssignment.fromJson(json))
            .toList();
        await _cacheService.saveDailySpecialists(dailySpecialists);
      }
    } catch (e) {
      debugPrint('Refresh failed: $e');
      throw Exception('Could not refresh data. Check internet connection.');
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
    if (kIsWeb) {
      await _apiService.updateResidentWeb(
        id: resident.id,
        phone: resident.phoneNumber,
      );
    } else {
      await _apiService.postAction('updateResident', resident.toJson());
    }
    // Give Google Apps Script some time to process and update the spreadsheet before we fetch again
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
      'id': specialist.id,
      'name': specialist.name,
      'phone': specialist.phone,
      'is_active': specialist.isActive,
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
