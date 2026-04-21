import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/repository.dart';
import '../utils/date_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('حول التطبيق'),
          _buildInfoCard(
            'الإصدار الحالي',
            '$_version ($_buildNumber)',
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          _buildSectionTitle('تشخيص البيئة'),
          _buildInfoCard(
            'نوع المنصة',
            kIsWeb ? 'متصفح ويب (Chrome)' : 'تطبيق أصلي',
            Icons.phonelink_setup_rounded,
          ),
          const SizedBox(height: 12),
          _buildDataDiagnosticCard(),
          const SizedBox(height: 20),
          if (isAndroid) ...[
            _buildSectionTitle('التحديثات'),
            _buildActionCard(
              'تحميل أحدث نسخة (APK)',
              'قم بتحميل التطبيق يدوياً من GitHub',
              Icons.android_rounded,
              Colors.green,
              () async {
                final url = Uri.parse('https://github.com/mostafaineista-rgb/Ent-On-Call/releases/latest');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Text(
              'ENT-ON-CALL © 2026',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDiagnosticCard() {
    final repository = Repository();
    
    return FutureBuilder(
      future: Future.wait([
        repository.getResidents(),
        repository.getSpecialists(),
        repository.getDuties(),
        repository.getDailySpecialists(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return _buildInfoCard('جاري التحميل...', '...', Icons.hourglass_empty_rounded);
        }
        
        final residentsCount = (snapshot.data![0] as List).length;
        final specialistsCount = (snapshot.data![1] as List).length;
        final dutiesCount = (snapshot.data![2] as List).length;
        final dailyCount = (snapshot.data![3] as List).length;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: Colors.blue.shade700),
                  const SizedBox(width: 16),
                  const Text('إحصائيات البيانات المخزنة', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              _buildStatRow('المقيمين', residentsCount.toString()),
              _buildStatRow('الاختصاصيين', specialistsCount.toString()),
              _buildStatRow('الخفارات الكلي', dutiesCount.toString()),
              _buildStatRow('جداول العمليات', dailyCount.toString()),
              const Divider(height: 24),
              _buildStatRow('تاريخ اليوم (Baghdad)', DutyDateUtils.getCurrentDutyDate()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
