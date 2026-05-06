import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/repository.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'login_screen.dart';
import 'main_tab_screen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  bool _showRetryButton = false;

  Future<void> _bootstrapApp() async {
    final repository = getIt<Repository>();
    final authService = getIt<AuthService>();

    try {
      // 1. Check cache first
      final residents = await repository.getResidents();
      final specialists = await repository.getSpecialists();
      final user = await authService.getLoggedInUser();

      if (residents.isNotEmpty || specialists.isNotEmpty) {
        _navigateToNext(user != null);
        // Background sync (non-blocking)
        repository.refreshData();
        return;
      }

      // 2. No cache — first sync from server
      // On web, we use a much shorter timeout to avoid the "frozen" feel
      final timeoutDuration = const Duration(seconds: 60);
      
      await repository.refreshData().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint('Splash: Data refresh timed out');
        },
      );

      final freshResidents = await repository.getResidents();
      final freshSpecialists = await repository.getSpecialists();
      final freshUser = await authService.getLoggedInUser();

      if (freshResidents.isEmpty && freshSpecialists.isEmpty) {
        // If we're on web and it's still empty, don't just hang. 
        // Show the retry button with clear feedback.
        if (mounted) setState(() => _showRetryButton = true);
        return;
      }

      _navigateToNext(freshUser != null);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      if (mounted) setState(() => _showRetryButton = true);
    }
  }

  void _navigateToNext(bool isLoggedIn) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const MainTabScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _showRetryButton ? 'يبدو أن هناك تأخيراً في الاتصال' : 'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: _showRetryButton ? Colors.orange.shade700 : Colors.blue.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_showRetryButton) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showRetryButton = false);
                    _bootstrapApp();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة الآن'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'تلميح: تأكد من اتصال الإنترنت وحاول مرة أخرى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
