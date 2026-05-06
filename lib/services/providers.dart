import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import 'service_locator.dart';
import 'repository.dart';
import 'auth_service.dart';

// Repository Provider
final repositoryProvider = Provider<Repository>((ref) => getIt<Repository>());

// Auth Provider
final authServiceProvider = Provider<AuthService>((ref) => getIt<AuthService>());

// Logged In User Provider
final loggedInUserProvider = FutureProvider<dynamic>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getLoggedInUser();
});

// Residents Provider
final residentsProvider = StateNotifierProvider<ResidentsNotifier, AsyncValue<List<Resident>>>((ref) {
  return ResidentsNotifier(ref.watch(repositoryProvider));
});

class ResidentsNotifier extends StateNotifier<AsyncValue<List<Resident>>> {
  final Repository _repository;
  ResidentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadResidents();
  }

  Future<void> loadResidents() async {
    state = const AsyncValue.loading();
    try {
      final residents = await _repository.getResidents();
      state = AsyncValue.data(residents);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Duties Provider
final dutiesProvider = StateNotifierProvider<DutiesNotifier, AsyncValue<List<Duty>>>((ref) {
  return DutiesNotifier(ref.watch(repositoryProvider));
});

class DutiesNotifier extends StateNotifier<AsyncValue<List<Duty>>> {
  final Repository _repository;
  DutiesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDuties();
  }

  Future<void> loadDuties() async {
    state = const AsyncValue.loading();
    try {
      final duties = await _repository.getDuties();
      state = AsyncValue.data(duties);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Specialists Provider
final specialistsProvider = StateNotifierProvider<SpecialistsNotifier, AsyncValue<List<Specialist>>>((ref) {
  return SpecialistsNotifier(ref.watch(repositoryProvider));
});

class SpecialistsNotifier extends StateNotifier<AsyncValue<List<Specialist>>> {
  final Repository _repository;
  SpecialistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSpecialists();
  }

  Future<void> loadSpecialists() async {
    state = const AsyncValue.loading();
    try {
      final specialists = await _repository.getSpecialists();
      state = AsyncValue.data(specialists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Daily Specialists Provider
final dailySpecialistsProvider = StateNotifierProvider<DailySpecialistsNotifier, AsyncValue<List<DailySpecialistAssignment>>>((ref) {
  return DailySpecialistsNotifier(ref.watch(repositoryProvider));
});

class DailySpecialistsNotifier extends StateNotifier<AsyncValue<List<DailySpecialistAssignment>>> {
  final Repository _repository;
  DailySpecialistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDailySpecialists();
  }

  Future<void> loadDailySpecialists() async {
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getDailySpecialists();
      state = AsyncValue.data(assignments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Global Sync Status
final syncStatusProvider = StateProvider<bool>((ref) => false);
