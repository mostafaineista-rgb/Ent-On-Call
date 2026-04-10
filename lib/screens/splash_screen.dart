import 'package:flutter/material.dart';
import '../services/repository.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_tab_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    debugPrint('--- SPLASH BOOTSTRAP START ---');
    final repository = Repository();
    
    try {
      debugPrint('Refreshing Data...');
      // Attempt to refresh data from network with a timeout.
      // If the connection is slow, we proceed with cached data.
      await repository.refreshData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Data refresh timed out after 10s, using cached data.');
        },
      );
      debugPrint('Data Refreshed.');
    } catch (e) {
      debugPrint('Offline or refresh failed, using cache. Error: $e');
    }

    try {
      debugPrint('Getting Logged In User...');
      final authService = AuthService(repository);
      final user = await authService.getLoggedInUser();
      debugPrint('User found: ${user?.name ?? "Guest"}');

      if (!mounted) {
        debugPrint('Splash Screen not mounted, aborting navigation.');
        return;
      }

      if (user != null) {
        debugPrint('Navigating to MainTabScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainTabScreen()),
        );
      } else {
        debugPrint('Navigating to LoginScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e, stack) {
      debugPrint('FATAL ERROR during bootstrap: $e');
      debugPrint(stack.toString());
    } finally {
      debugPrint('--- SPLASH BOOTSTRAP END ---');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building SplashScreen...');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'جاري التحميل...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
