import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_specialist.dart';
import '../models/specialist.dart';
import '../services/repository.dart';
import '../utils/date_utils.dart';
import '../widgets/resident_pixel_sprite.dart';

class SpecialistsPage extends StatefulWidget {
  const SpecialistsPage({super.key});

  @override
  State<SpecialistsPage> createState() => _SpecialistsPageState();
}

class _SpecialistsPageState extends State<SpecialistsPage> {
  final Repository _repository = Repository();
  List<DailySpecialistAssignment> _allAssignments = [];
  List<Specialist> _allSpecialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await _repository.getDailySpecialists();
      final specialists = await _repository.getSpecialists();
      
      setState(() {
        _allAssignments = assignments;
        _allSpecialists = specialists;
      });
    } catch (e) {
      debugPrint('Error loading specialists data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _getSpecialistPhone(String id, String? fallbackPhone) {
    if (fallbackPhone != null && fallbackPhone.isNotEmpty) return fallbackPhone;
    return _allSpecialists.where((s) => s.id == id).firstOrNull?.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final todayDateStr = DutyDateUtils.getCurrentDutyDate();
    final todayAssignment = _allAssignments.where((a) => a.date == todayDateStr).firstOrNull;
    
    final upcomingAssignments = _allAssignments.where((a) {
      if (a.date == todayDateStr) return true;
      try {
        final aDate = DateTime.parse(a.date);
        final tDate = DateTime.parse(todayDateStr);
        // Show today and future dates
        return aDate.isAfter(tDate) || a.date == todayDateStr;
      } catch (_) {
        // If parsing fails, still show it just in case
        return true;
      }
    }).toList();
    
    // Sort and remove duplicates (if any)
    upcomingAssignments.sort((a, b) => a.date.compareTo(b.date));
    final seenDates = <String>{};
    upcomingAssignments.retainWhere((a) => seenDates.add(a.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('فريق الاختصاصيين'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // --- Today's Roles Section ---
                  _buildSectionTitle('جدول عمل اليوم', context),
                  const SizedBox(height: 16),
                  if (DutyDateUtils.isFriday())
                    _buildFridayState(context)
                  else if (todayAssignment == null)
                    _buildEmptyState('لا توجد تعيينات مسجلة لليوم')
                  else
                    Column(
                      children: [
                        ...todayAssignment.specialistOnCallNames.map((name) => 
                          _buildRoleCard(
                            'الاخصائي الخفر',
                            name,
                            _getSpecialistPhone(todayAssignment.specialistOnCallId, todayAssignment.specialistOnCallPhone),
                            Colors.red.shade700,
                            Icons.medical_services_rounded,
                          ),
                        ),
                        if (todayAssignment.specialistOnCallNames.isNotEmpty) const SizedBox(height: 12),
                        
                        ...todayAssignment.orSpecialistNames.map((name) => 
                          _buildRoleCard(
                            'الاختصاصي خفر العمليات',
                            name,
                            _getSpecialistPhone(todayAssignment.orSpecialistId, todayAssignment.orSpecialistPhone),
                            Colors.blue.shade700,
                            Icons.biotech_rounded,
                          ),
                        ),
                        if (todayAssignment.orSpecialistNames.isNotEmpty) const SizedBox(height: 12),
                        
                        ...todayAssignment.consultationSpecialistNames.map((name) => 
                          _buildRoleCard(
                            'الاختصاصي في الاستشارية',
                            name,
                            _getSpecialistPhone(todayAssignment.consultationSpecialistId, todayAssignment.consultationSpecialistPhone),
                            Colors.teal.shade700,
                            Icons.assignment_ind_rounded,
                          ),
                        ),
                        
                        if (todayAssignment.notes != null && todayAssignment.notes!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.note_alt_rounded, color: Colors.orange.shade800, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    todayAssignment.notes!,
                                    style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 40),

                  // --- Upcoming Schedule Section ---
                  _buildSectionTitle('الجدول القادم', context),
                  const SizedBox(height: 16),
                  if (upcomingAssignments.isEmpty)
                    _buildEmptyState('لا توجد خفارات قادمة مسجلة')
                  else
                    ...upcomingAssignments.map((assignment) => _buildScheduleRow(assignment)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, String name, String phone, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const ResidentPixelSprite(
            size: 55,
            scale: 1.8,
            useCircleBackground: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.2), size: 32),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(DailySpecialistAssignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DutyDateUtils.formatArabicReadableDate(assignment.date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const Spacer(),
              if (assignment.updatedAt != null)
                Text(
                  'تحديث: ${DateFormat('MM/dd').format(assignment.updatedAt!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildCompactRoleInfo('خفر العمليات', _getDisplayNames(assignment.orSpecialistIds, assignment.orSpecialistNames)),
              _buildCompactRoleInfo('الاستشارية', _getDisplayNames(assignment.consultationSpecialistIds, assignment.consultationSpecialistNames)),
              _buildCompactRoleInfo('الخافر', _getDisplayNames(assignment.specialistOnCallIds, assignment.specialistOnCallNames)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRoleInfo(String role, String name) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFridayState(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: primaryColor, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'جمعة مباركة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد عيادات استشارية أو عمليات باردة خلال يوم الجمعة. نتمنى لكم يوم استراحة سعيد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
