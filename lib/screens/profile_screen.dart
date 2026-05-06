import 'package:flutter/material.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import '../services/cache_service.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Repository _repository = Repository();
  late final AuthService _authService = AuthService(_repository);
  dynamic _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getLoggedInUser();
      setState(() => _user = user);
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editName() {
    final controller = TextEditingController(text: _user!.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الاسم'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'الاسم الجديد',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                await _updateUser(_user!.copyWith(name: newName));
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _editPhoneNumber() {
    final controller = TextEditingController(text: _user is Resident ? _user!.phoneNumber : _user!.phone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل رقم الهاتف'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف الجديد',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPhone = controller.text.trim();
                if (newPhone.isEmpty) return;
                if (_user is Resident) {
                  await _updateUser(_user!.copyWith(phoneNumber: newPhone));
                } else {
                  await _updateUser(_user!.copyWith(phone: newPhone));
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUser(dynamic updatedUser) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cache = CacheService();
      
      // 1. Update Remote Backend and local cache
      if (updatedUser is Resident) {
        await _repository.updateResident(updatedUser);
        final residents = await cache.getResidents();
        final index = residents.indexWhere((r) => r.id == updatedUser.id);
        if (index != -1) {
          residents[index] = updatedUser;
          await cache.saveResidents(residents);
        }
      } else if (updatedUser is Specialist) {
        await _repository.updateSpecialist(updatedUser);
        final specialists = await cache.getSpecialists();
        final index = specialists.indexWhere((s) => s.id == updatedUser.id);
        if (index != -1) {
          specialists[index] = updatedUser;
          await cache.saveSpecialists(specialists);
        }
      }

      // 2. Update local state
      if (mounted) setState(() => _user = updatedUser);
      
      if (!mounted) return;
      // Pop loading dialog and then pop the original edit dialog
      Navigator.pop(context); // Pop loading
      Navigator.pop(context); // Pop edit dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('خطأ في تحميل البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: _user is Resident && _user!.isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
                          child: Text(
                            _user!.name.isNotEmpty ? _user!.name[0] : '?',
                            style: TextStyle(
                              fontSize: 40,
                              color: _user is Resident && _user!.isAdmin ? Colors.red.shade900 : Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_user is Resident && _user!.isAdmin)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user is Resident 
                        ? (_user!.isAdmin ? 'مسؤول النظام' : 'مقيم - المرحلة ${_user!.stage}') 
                        : 'اختصاصي',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات الشخصية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildProfileTile(
                          icon: Icons.person_outline_rounded,
                          title: 'الاسم الكامل',
                          value: _user!.name,
                          onTap: _editName,
                        ),
                        Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                        _buildProfileTile(
                          icon: Icons.phone_android_rounded,
                          title: 'رقم الهاتف',
                          value: _user is Resident ? _user!.phoneNumber : _user!.phone,
                          onTap: _editPhoneNumber,
                        ),
                        if (_user is Resident) ...[
                          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                          _buildProfileTile(
                            icon: Icons.workspace_premium_rounded,
                            title: 'المرحلة الدراسية',
                            value: 'Stage ${_user!.stage}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_user is Resident && _user!.isAdmin) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'إدارة النظام',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.admin_panel_settings_rounded, color: Colors.red.shade800),
                        ),
                        title: const Text('لوحة تحكم المسؤول', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('إدارة المقيمين، الاختصاصيين، والجدول'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminScreen()),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.red.shade50.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'v1.2.1 • ENT On-Call',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue.shade800, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      trailing: onTap != null ? const Icon(Icons.edit_rounded, size: 18, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}
