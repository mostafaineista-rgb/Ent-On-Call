import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      debugPrint('Getting Logged In User from cache...');
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.blue.shade50.withValues(alpha: 0.5),
              Colors.white,
            ],
            radius: 1.0,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: Lottie.asset(
                  'assets/images/self-protection.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ENT-ON-CALL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue.shade900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
