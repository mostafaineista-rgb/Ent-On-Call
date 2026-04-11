import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../widgets/resident_pixel_sprite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'specialists_page.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Repository _repository = Repository();
  late final AuthService _authService = AuthService(_repository);
  Duty? _currentDuty;
  Resident? _currentUser;
  List<Resident> _allResidents = [];
  List<Specialist> _allSpecialists = [];
  DailySpecialistAssignment? _todaySpecialistAssignment;
  bool _isLoading = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    // Only check on Android devices (non-web)
    // iOS users should use the web version and not be prompted to download APK
    if (kIsWeb || Theme.of(context).platform != TargetPlatform.android) return;

    try {
      final response = await http.get(Uri.parse('https://ent-on-call.web.app/version.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'];
        final downloadUrl = data['download_url'];
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isVersionNewer(latestVersion, currentVersion)) {
          if (!mounted) return;
          _showUpdateDialog(latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  bool _isVersionNewer(String latest, String current) {
    // Simple semantic version comparison
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();
    
    for (int i = 0; i < latestParts.length; i++) {
      int cur = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > cur) return true;
      if (latestParts[i] < cur) return false;
    }
    return false;
  }

  void _showUpdateDialog(String version, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تحديث جديد متاح', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('يتوفر إصدار رقم $version من تطبيق ENT-ON-CALL.'),
            const SizedBox(height: 8),
            const Text('يرجى تحديث التطبيق للحصول على آخر المميزات والتحسينات.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData({bool refreshFromNetwork = false}) async {
    setState(() => _isLoading = true);
    try {
      final duties = await _repository.getDuties();
      final residents = await _repository.getResidents();
      final todayDate = DutyDateUtils.getCurrentDutyDate();
      final specialists = await _repository.getSpecialists();
      final user = await _authService.getLoggedInUser();
      final dailyAssignments = await _repository.getDailySpecialists();

      setState(() {
        _allResidents = residents;
        _allSpecialists = specialists;
        _currentDuty = duties.where((d) => d.date == todayDate).firstOrNull;
        
        debugPrint('--- DATA LOAD DEBUG ---');
        debugPrint('Today Duty Date (Baghdad): $todayDate');
        debugPrint('System Timestamp: ${DateTime.now().toIso8601String()}');
        debugPrint('Found ${dailyAssignments.length} daily assignments in cache.');
        
        if (dailyAssignments.isNotEmpty) {
          debugPrint('Available assignment dates: ${dailyAssignments.map((a) => a.date).join(', ')}');
        }
        
        _todaySpecialistAssignment = dailyAssignments.where((a) => a.date == todayDate).firstOrNull;
        
        if (_todaySpecialistAssignment != null) {
          debugPrint('✅ MATCH FOUND for $todayDate');
          debugPrint('Has Any Specialist Details: ${_todaySpecialistAssignment!.hasAnySpecialist}');
        } else {
          debugPrint('❌ NO MATCH FOUND for $todayDate in available assignments.');
        }
        
        _currentUser = user;
        _lastSyncTime = DateTime.now();
        debugPrint('-----------------------');
      });

      // Schedule notifications in the background
      NotificationService.scheduleDutyReminders(_authService, _repository);

      // After showing cached data, silently refresh from network
      if (!refreshFromNetwork) {
        _backgroundRefresh();
      }
    } catch (e) {
      debugPrint('Error loading current duty: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fetches fresh data from network without blocking UI, then reloads.
  Future<void> _backgroundRefresh() async {
    try {
      debugPrint('Background refresh started...');
      await _repository.refreshData();
      debugPrint('Background refresh complete. Reloading UI...');
      if (mounted) {
        _loadData(refreshFromNetwork: true);
      }
    } catch (e) {
      debugPrint('Background refresh failed (using cached data): $e');
    }
  }

  Widget _buildRoleRow(String title, String name, IconData icon, Color color, {String? residentId}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الخفارة الحالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
            tooltip: 'التنبيهات',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'الإعدادات',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await _repository.refreshData();
                await _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('فشل التحديث. تأكد من الاتصال بالإنترنت.')),
                );
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.asset(
                      'assets/images/self-protection.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _repository.refreshData();
                await _loadData();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                children: [
                  if (_currentDuty == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد خفارة مسجلة لليوم',
                              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final specialist = _currentDuty!.specialistId != null 
                          ? _allSpecialists.where((s) => s.id == _currentDuty!.specialistId).firstOrNull 
                          : null;

                        // 1. Get unique residents assigned to this duty, sorted by seniority (stage descending)
                        final uniqueResidents = _currentDuty!.residentIds
                            .map((id) => _allResidents.where((r) => r.id == id).firstOrNull)
                            .whereType<Resident>()
                            .toSet() 
                            .toList();
                        
                        final seenNames = <String>{};
                        final distinctResidents = <Resident>[];
                        for (var r in uniqueResidents) {
                          if (!seenNames.contains(r.name.trim())) {
                            seenNames.add(r.name.trim());
                            distinctResidents.add(r);
                          }
                        }
                        
                        distinctResidents.sort((a, b) => b.stage.compareTo(a.stage));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 0. Doctor Hero Animation
                            // 0. Hero Animation
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.05),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Lottie.asset(
                                    'assets/images/virus-disinfectant.json',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              DutyDateUtils.formatArabicReadableDate(_currentDuty!.date),
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade800, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '8:00 ص',
                                              style: TextStyle(
                                                color: Colors.orange.shade900,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'الفريق المناوب',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                   // Specialist row at the top
                                  if (_todaySpecialistAssignment != null && _todaySpecialistAssignment!.specialistOnCallNames.isNotEmpty)
                                    ..._todaySpecialistAssignment!.specialistOnCallNames.map((name) => 
                                      _buildRoleRow(
                                        'الأخصائي الخفر', 
                                        name, 
                                        Icons.medical_services_rounded, 
                                        Colors.red.shade700
                                      )
                                    )
                                  else
                                    _buildRoleRow(
                                      'الأخصائي الخفر', 
                                      specialist?.name ?? 'لا يوجد اختصاص خفر', 
                                      Icons.medical_services_rounded, 
                                      Colors.red.shade700
                                    ),
                                  const SizedBox(height: 8),

                                  ...List.generate(distinctResidents.length, (index) {
                                    final res = distinctResidents[index];
                                    String label = '';
                                    IconData icon = Icons.person_rounded;
                                    Color color = Colors.grey;

                                    if (distinctResidents.length >= 4) {
                                      if (index == 0) {
                                        label = 'رئيس الفريق (Team Leader)';
                                        icon = Icons.star_rounded;
                                        color = Colors.amber.shade800;
                                      } else if (index == 1) {
                                        label = 'الاستدعاء الثالث (3rd Call)';
                                        icon = Icons.looks_3_rounded;
                                        color = Colors.purple.shade600;
                                      } else if (index == 2) {
                                        label = 'الاستدعاء الثاني (2nd Call)';
                                        icon = Icons.looks_two_rounded;
                                        color = Colors.orange.shade700;
                                      } else {
                                        label = 'الاستدعاء الأول (1st Call)';
                                        icon = Icons.looks_one_rounded;
                                        color = Colors.teal.shade600;
                                      }
                                    } else if (distinctResidents.length == 3) {
                                      if (index == 0) {
                                        label = 'رئيس الفريق (Team Leader)';
                                        icon = Icons.star_rounded;
                                        color = Colors.amber.shade800;
                                      } else if (index == 1) {
                                        label = 'الاستدعاء الثاني (2nd Call)';
                                        icon = Icons.looks_two_rounded;
                                        color = Colors.orange.shade700;
                                      } else {
                                        label = 'الاستدعاء الأول (1st Call)';
                                        icon = Icons.looks_one_rounded;
                                        color = Colors.teal.shade600;
                                      }
                                    } else if (distinctResidents.length == 2) {
                                      if (index == 0) {
                                        label = 'رئيس الفريق (Team Leader)';
                                        icon = Icons.star_rounded;
                                        color = Colors.amber.shade800;
                                      } else {
                                        label = 'الاستدعاء الأول (1st Call)';
                                        icon = Icons.looks_one_rounded;
                                        color = Colors.teal.shade600;
                                      }
                                    } else {
                                      label = 'رئيس الفريق (Team Leader)';
                                      icon = Icons.star_rounded;
                                      color = primaryColor;
                                    }

                                    return _buildRoleRow(label, res.name, icon, color, residentId: res.id);
                                  }),

                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // --- NEW: Daily Specialist Assignments Section ---
                  const SizedBox(height: 24),
                  if (DutyDateUtils.isFriday())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withValues(alpha: 0.9), primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'جمعة مباركة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لا توجد عيادات استشارية اليوم',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_todaySpecialistAssignment != null)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SpecialistsPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withValues(alpha: 0.9), primaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                const Text(
                                  'فريق الاختصاصيين اليوم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: _buildSpecialistMiniInfo(
                                    'خفر العمليات',
                                    _getDisplayNames(_todaySpecialistAssignment!.orSpecialistIds, _todaySpecialistAssignment!.orSpecialistNames),
                                  ),
                                ),
                                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                                Expanded(
                                  child: _buildSpecialistMiniInfo(
                                    'الالاستشارية',
                                    _getDisplayNames(_todaySpecialistAssignment!.consultationSpecialistIds, _todaySpecialistAssignment!.consultationSpecialistNames),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),
                  if (_lastSyncTime != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'آخر تحديث: ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSpecialistMiniInfo(String label, String name) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  String _getDisplayNames(List<String> ids, List<String> fallbackNames) {
    if (fallbackNames.isNotEmpty) return fallbackNames.join(' / ');
    
    if (ids.isEmpty) return 'غير معروف';
    
    List<String> foundNames = [];
    for (var id in ids) {
      final name = _allSpecialists.where((s) => s.id == id).firstOrNull?.name;
      if (name != null) foundNames.add(name);
    }
    
    return foundNames.isNotEmpty ? foundNames.join(' / ') : 'غير معروف';
  }
}
