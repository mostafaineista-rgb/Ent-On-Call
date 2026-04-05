import 'package:shared_preferences/shared_preferences.dart';
import '../models/resident.dart';
import 'repository.dart';

class AuthService {
  static const String _loggedInUserIdKey = 'ent_oncall_logged_in_user_id';
  final Repository _repository;

  AuthService(this._repository);

  Future<Resident?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_loggedInUserIdKey);
    if (userId == null) return null;

    final residents = await _repository.getResidents();
    try {
      return residents.firstWhere((r) => r.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<Resident?> login(String name, String password) async {
    final residents = await _repository.getResidents();
    try {
      final resident = residents.firstWhere((r) => r.name.trim() == name.trim());
      
      // Simple verification for MVP purposes based on the rule: 
      // "Login is only by resident name and password." 
      if (resident.password.isEmpty || resident.password.trim() == password.trim()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInUserIdKey, resident.id);
        return resident;
      } else {
        throw Exception('Invalid password');
      }
    } catch (e) {
      if (e is StateError) {
        throw Exception('Resident name not found');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey);
  }
}
