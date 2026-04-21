import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import 'main_tab_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الاسم وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = Repository();
      final authService = AuthService(repository);
      
      try {
        await authService.login(name, password);
      } catch (e) {
        // If login failed (e.g. resident not found in cache), try refreshing from network once
        if (e.toString().contains('Resident name not found')) {
          await repository.refreshData();
          await authService.login(name, password);
        } else {
          rethrow;
        }
      }
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('Network error') || errorMsg.contains('فشل في إرسال البيانات')) {
        errorMsg = 'فشل الاتصال بالخادم. يرجى التأكد من الإنترنت.';
        if (kIsWeb) {
          errorMsg += '\n(ملاحظة: قد تكون هناك قيود في المتصفح تمنع الاتصال)';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'إغلاق', onPressed: () {}),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo section
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.medical_services_rounded, size: 40, color: primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'ENT ON-CALL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32, 
                    fontWeight: FontWeight.w900, 
                    color: primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نظام إدارة الخفارات الذكي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.grey.shade600, 
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Form section
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل (بالعربي)',
                    hintText: 'أدخل اسمك كما هو مسجل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل الرقم السري الخاص بك',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action section
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text('دخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'إذا نسيت كلمة المرور، يرجى التواصل مع مسؤول النظام لإعادة تعيينها.',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
