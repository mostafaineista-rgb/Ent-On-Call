import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';
import '../utils/date_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'specialists_page.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import '../utils/platform_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBackgroundDownloading = false;
  double _backgroundDownloadProgress = 0.0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _backgroundRefresh();
  }

  Future<void> _checkForUpdate() async {
    // Only support auto-updates on Android and Web
    if (!kIsWeb && Theme.of(context).platform != TargetPlatform.android) return;

    try {
      // Use GitHub as the source of truth for the latest version
      // This ensures the app detects updates as soon as they are pushed to GitHub
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/mostafaineista-rgb/Ent-On-Call/main/web/version.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'];
        final latestBuild = data['build_number'] ?? 0;
        final downloadUrl = data['download_url'];
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

        // Check version string OR build number
        if (_isVersionNewer(latestVersion, currentVersion) || 
           (latestVersion == currentVersion && latestBuild > currentBuild)) {
          if (!mounted) return;
          
          if (kIsWeb) {
            _showWebUpdateDialog(latestVersion);
          } else {
            // Automatically start background download on Android as requested
            _startBackgroundDownload(latestVersion, downloadUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  bool _isVersionNewer(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();
    
    for (int i = 0; i < latestParts.length; i++) {
      int cur = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > cur) return true;
      if (latestParts[i] < cur) return false;
    }
    return false;
  }

  void _showWebUpdateDialog(String version) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تتوفر نسخة جديدة ($version). يرجى تحديث الصفحة.'),
        duration: const Duration(days: 1), // Stay until dismissed
        action: SnackBarAction(
          label: 'تحديث الآن',
          onPressed: () => reloadBrowser(),
        ),
      ),
    );
  }

  Future<void> _startBackgroundDownload(String version, String url) async {
    if (_isBackgroundDownloading) return;

    setState(() {
      _isBackgroundDownloading = true;
      _backgroundDownloadProgress = 0.0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/app_update_$version.apk';
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      // Inject User-Agent to bypass ISP/Carrier blocks
      request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
      
      final response = await http.Client().send(request);
      
      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      final sink = file.openWrite();
      await response.stream.map((chunk) {
        downloaded += chunk.length;
        if (contentLength > 0) {
          setState(() {
            _backgroundDownloadProgress = downloaded / contentLength;
          });
        }
        return chunk;
      }).pipe(sink);

      setState(() => _isBackgroundDownloading = false);
      
      if (mounted) {
        _showInstallDialog(version, filePath);
      }
    } catch (e) {
      debugPrint('Background download error: $e');
      setState(() => _isBackgroundDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تنزيل التحديث التلقائي.')),
        );
      }
    }
  }

  void _showInstallDialog(String version, String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تحديث جاهز للتثبيت', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('تم تنزيل الإصدار $version بنجاح. هل تريد تثبيته الآن؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await OpenFilex.open(filePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تثبيت الآن'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _backgroundRefresh() async {
    try {
      final repository = ref.read(repositoryProvider);
      final authService = ref.read(authServiceProvider);
      
      ref.read(syncStatusProvider.notifier).state = true;
      await repository.refreshData();
      
      // Update Providers
      ref.read(dutiesProvider.notifier).loadDuties();
      ref.read(residentsProvider.notifier).loadResidents();
      ref.read(specialistsProvider.notifier).loadSpecialists();
      ref.read(dailySpecialistsProvider.notifier).loadDailySpecialists();
      
      NotificationService.scheduleDutyReminders(authService, repository);
      
      if (mounted) {
        setState(() => _lastSyncTime = DateTime.now());
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    } finally {
      ref.read(syncStatusProvider.notifier).state = false;
    }
  }

  Widget _buildRoleRow(String title, String name, IconData icon, Color color) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
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
    final dutiesAsync = ref.watch(dutiesProvider);
    final residentsAsync = ref.watch(residentsProvider);
    final specialistsAsync = ref.watch(specialistsProvider);
    final dailyAssignmentsAsync = ref.watch(dailySpecialistsProvider);
    final isSyncing = ref.watch(syncStatusProvider);
    

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الخفارة الحالية'),
        actions: [
          if (isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _backgroundRefresh,
          ),
        ],
        bottom: _isBackgroundDownloading 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _backgroundDownloadProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: const Text(
                      'جاري تنزيل التحديث الجديد في الخلفية...',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : null,
      ),
      body: dutiesAsync.when(
        loading: () => _buildLoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (duties) {
          final todayDate = DutyDateUtils.getCurrentDutyDate();
          final currentDuty = duties.where((d) => d.date == todayDate).firstOrNull;
          
          if (currentDuty == null) return _buildNoDutyState();

          return RefreshIndicator(
            onRefresh: _backgroundRefresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              children: [
                _buildHeroAnimation(),
                _buildDutyDetailsCard(currentDuty, residentsAsync, specialistsAsync, dailyAssignmentsAsync),
                const SizedBox(height: 24),
                _buildSpecialistsSection(dailyAssignmentsAsync, specialistsAsync),
                const SizedBox(height: 32),
                _buildSyncStatus(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset('assets/images/self-protection.json', fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Text('جاري تحميل البيانات...', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNoDutyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('لا توجد خفارة مسجلة لليوم', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAnimation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Colors.blue.shade50, Colors.white.withValues(alpha: 0.0)]),
          ),
          child: Lottie.asset('assets/images/virus-disinfectant.json', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildDutyDetailsCard(
    Duty duty, 
    AsyncValue<List<Resident>> residentsAsync, 
    AsyncValue<List<Specialist>> specialistsAsync,
    AsyncValue<List<DailySpecialistAssignment>> dailyAssignmentsAsync
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    final allResidents = residentsAsync.value ?? [];
    final allSpecialists = specialistsAsync.value ?? [];
    final dailyAssignments = dailyAssignmentsAsync.value ?? [];
    final todayDate = DutyDateUtils.getCurrentDutyDate();
    final todayAssignment = dailyAssignments.where((a) => a.date == todayDate).firstOrNull;

    final specialist = duty.specialistId != null 
        ? allSpecialists.where((s) => s.id == duty.specialistId).firstOrNull 
        : null;

    final uniqueResidents = duty.residentIds
        .map((id) => allResidents.where((r) => r.id == id).firstOrNull)
        .whereType<Resident>()
        .toSet() 
        .toList();
    uniqueResidents.sort((a, b) => b.stage.compareTo(a.stage));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(DutyDateUtils.formatArabicReadableDate(duty.date), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const Spacer(),
              _buildTimeBadge(),
            ],
          ),
          const SizedBox(height: 32),
          _buildTeamHeader(primaryColor),
          const SizedBox(height: 20),
          
          if (todayAssignment != null && todayAssignment.specialistOnCallNames.isNotEmpty)
            ...todayAssignment.specialistOnCallNames.map((name) => 
              _buildRoleRow('الاختصاصي الخفر', name, Icons.medical_services_rounded, Colors.red.shade700)
            )
          else
            _buildRoleRow('الاختصاصي الخفر', specialist?.name ?? 'لا يوجد اختصاص خفر', Icons.medical_services_rounded, Colors.red.shade700),
          
          const SizedBox(height: 8),

          ...List.generate(uniqueResidents.length, (index) {
            final res = uniqueResidents[index];
            final config = _getResidentRoleConfig(index, uniqueResidents.length);
            return _buildRoleRow(config.label, res.name, config.icon, config.color);
          }),
        ],
      ),
    );
  }

  Widget _buildTimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade800, size: 16),
          const SizedBox(width: 4),
          Text('8:00 ص', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(Color primaryColor) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        const Text('الفريق المناوب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSpecialistsSection(AsyncValue<List<DailySpecialistAssignment>> assignmentsAsync, AsyncValue<List<Specialist>> specialistsAsync) {
    if (DutyDateUtils.isFriday()) return _buildFridayGreeting();

    return assignmentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (assignments) {
        final todayDate = DutyDateUtils.getCurrentDutyDate();
        final todayAssignment = assignments.where((a) => a.date == todayDate).firstOrNull;
        if (todayAssignment == null) return const SizedBox.shrink();

        return _buildSpecialistTeamCard(todayAssignment, specialistsAsync.value ?? []);
      },
    );
  }

  Widget _buildFridayGreeting() {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor.withValues(alpha: 0.9), primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.stars_rounded, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text('جمعة مباركة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('لا توجد عيادات استشارية اليوم', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSpecialistTeamCard(DailySpecialistAssignment assignment, List<Specialist> allSpecialists) {
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistsPage())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor.withValues(alpha: 0.9), primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text('فريق الاختصاصيين اليوم', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildSpecialistMiniInfo('خفر العمليات', _getDisplayNames(assignment.orSpecialistIds, assignment.orSpecialistNames, allSpecialists))),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(child: _buildSpecialistMiniInfo('الاستشارية', _getDisplayNames(assignment.consultationSpecialistIds, assignment.consultationSpecialistNames, allSpecialists))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistMiniInfo(String label, String name) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSyncStatus() {
    if (_lastSyncTime == null) return const SizedBox.shrink();
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text('آخر تحديث: ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  String _getDisplayNames(List<String> ids, List<String> fallbackNames, List<Specialist> allSpecialists) {
    if (fallbackNames.isNotEmpty) return fallbackNames.join(' / ');
    if (ids.isEmpty) return 'غير معروف';
    final names = ids.map((id) => allSpecialists.where((s) => s.id == id).firstOrNull?.name).whereType<String>().toList();
    return names.isNotEmpty ? names.join(' / ') : 'غير معروف';
  }

  _ResidentRoleConfig _getResidentRoleConfig(int index, int total) {
    if (total >= 4) {
      if (index == 0) return _ResidentRoleConfig('رئيس الفريق', Icons.star_rounded, Colors.amber.shade800);
      if (index == 1) return _ResidentRoleConfig('الاستدعاء الثالث', Icons.looks_3_rounded, Colors.purple.shade600);
      if (index == 2) return _ResidentRoleConfig('الاستدعاء الثاني', Icons.looks_two_rounded, Colors.orange.shade700);
      return _ResidentRoleConfig('الاستدعاء الأول', Icons.looks_one_rounded, Colors.teal.shade600);
    } else if (total == 3) {
      if (index == 0) return _ResidentRoleConfig('رئيس الفريق', Icons.star_rounded, Colors.amber.shade800);
      if (index == 1) return _ResidentRoleConfig('الاستدعاء الثاني', Icons.looks_two_rounded, Colors.orange.shade700);
      return _ResidentRoleConfig('الاستدعاء الأول', Icons.looks_one_rounded, Colors.teal.shade600);
    } else if (total == 2) {
      if (index == 0) return _ResidentRoleConfig('رئيس الفريق', Icons.star_rounded, Colors.amber.shade800);
      return _ResidentRoleConfig('الاستدعاء الأول', Icons.looks_one_rounded, Colors.teal.shade600);
    }
    return _ResidentRoleConfig('رئيس الفريق', Icons.star_rounded, Theme.of(context).primaryColor);
  }
}

class _ResidentRoleConfig {
  final String label;
  final IconData icon;
  final Color color;
  _ResidentRoleConfig(this.label, this.icon, this.color);
}
