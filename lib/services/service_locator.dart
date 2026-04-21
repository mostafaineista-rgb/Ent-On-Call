import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'repository.dart';
import 'auth_service.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // Services
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    
    getIt.registerLazySingleton<ApiService>(() => ApiService());
    getIt.registerLazySingleton<CacheService>(() => CacheService());
    getIt.registerLazySingleton<Repository>(() => Repository());
    
    // AuthService depends on Repository
    getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<Repository>()));
  }
}
