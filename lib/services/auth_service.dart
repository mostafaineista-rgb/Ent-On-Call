import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../utils/string_utils.dart';
import 'repository.dart';

class AuthService {
  static const String _loggedInUserIdKey = 'ent_oncall_logged_in_user_id';
  static const String _loggedInUserRoleKey = 'ent_oncall_logged_in_user_role';
  final Repository _repository;

  AuthService(this._repository);

  Future<dynamic> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_loggedInUserIdKey);
    final userRole = prefs.getString(_loggedInUserRoleKey) ?? 'resident';

    if (userId == null) return null;

    if (userRole == 'specialist') {
      final specialists = await _repository.getSpecialists();
      try {
        return specialists.firstWhere((s) => s.id == userId);
      } catch (e) {
        return null;
      }
    } else {
      final residents = await _repository.getResidents();
      try {
        return residents.firstWhere((r) => r.id == userId);
      } catch (e) {
        return null;
      }
    }
  }

  Future<dynamic> login(String name, String password) async {
    List<Resident> residents = await _repository.getResidents();
    List<Specialist> specialists = await _repository.getSpecialists();
    
    // If cache is empty, force a refresh once
    if (residents.isEmpty && specialists.isEmpty) {
      debugPrint('AuthService: User list empty, forcing refresh...');
      await _repository.refreshData();
      residents = await _repository.getResidents();
      specialists = await _repository.getSpecialists();
    }

    try {
      final resident = residents.firstWhere((r) => StringUtils.normalizeName(r.name) == StringUtils.normalizeName(name));
      
      // Verification for resident
      if (resident.password.isEmpty || resident.password.trim() == password.trim()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInUserIdKey, resident.id);
        await prefs.setString(_loggedInUserRoleKey, 'resident');
        return resident;
      } else {
        throw Exception('كلمة المرور غير صحيحة'); // Incorrect password
      }
    } catch (e) {
      if (e is StateError) {
        // Not a resident, try specialist
        try {
          final specialist = specialists.firstWhere((s) => StringUtils.normalizeName(s.name) == StringUtils.normalizeName(name));
          if (specialist.password.isEmpty || specialist.password.trim() == password.trim()) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_loggedInUserIdKey, specialist.id);
            await prefs.setString(_loggedInUserRoleKey, 'specialist');
            return specialist;
          } else {
            throw Exception('كلمة المرور غير صحيحة');
          }
        } catch (_) {
          // If still not found, try refreshing data one last time
          await _repository.refreshData();
          residents = await _repository.getResidents();
          specialists = await _repository.getSpecialists();
          
          try {
            final resident2 = residents.firstWhere((r) => StringUtils.normalizeName(r.name) == StringUtils.normalizeName(name));
            if (resident2.password.isEmpty || resident2.password.trim() == password.trim()) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_loggedInUserIdKey, resident2.id);
              await prefs.setString(_loggedInUserRoleKey, 'resident');
              return resident2;
            } else {
              throw Exception('كلمة المرور غير صحيحة');
            }
          } catch (_) {
            try {
              final specialist2 = specialists.firstWhere((s) => StringUtils.normalizeName(s.name) == StringUtils.normalizeName(name));
              if (specialist2.password.isEmpty || specialist2.password.trim() == password.trim()) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_loggedInUserIdKey, specialist2.id);
                await prefs.setString(_loggedInUserRoleKey, 'specialist');
                return specialist2;
              } else {
                throw Exception('كلمة المرور غير صحيحة');
              }
            } catch (_) {
              throw Exception('اسم المستخدم غير موجود. يرجى التأكد من الاسم.');
            }
          }
        }
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey);
    await prefs.remove(_loggedInUserRoleKey);
  }
}
