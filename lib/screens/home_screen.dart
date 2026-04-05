import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/repository.dart';
import '../utils/date_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Repository _repository = Repository();
  Duty? _currentDuty;
  List<Resident> _allResidents = [];
  List<Specialist> _allSpecialists = [];
  bool _isLoading = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final duties = await _repository.getDuties();
      final residents = await _repository.getResidents();
      final specialists = await _repository.getSpecialists();
      final todayDate = DutyDateUtils.getCurrentDutyDate();

      setState(() {
        _allResidents = residents;
        _allSpecialists = specialists;
        _currentDuty = duties.where((d) => d.date == todayDate).firstOrNull;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading current duty: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleRow(String title, String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الخفارة الحالية'),
        actions: [
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('جاري تحميل البيانات...', style: TextStyle(color: Colors.grey.shade600)),
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
                            // 0. Lottie Animation Hero
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Lottie.asset(
                                  'assets/images/DOCTOR.json',
                                  height: 180,
                                  repeat: true,
                                  animate: true,
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
                                    color: Colors.black.withOpacity(0.05),
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
                                          color: primaryColor.withOpacity(0.1),
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

                                    return _buildRoleRow(label, res.name, icon, color);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
}
