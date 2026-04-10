import 'package:flutter/material.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/repository.dart';
import '../utils/date_utils.dart';
import '../widgets/duty_card.dart';
import '../models/daily_specialist.dart';

class UpcomingDutiesScreen extends StatefulWidget {
  const UpcomingDutiesScreen({super.key});

  @override
  State<UpcomingDutiesScreen> createState() => _UpcomingDutiesScreenState();
}

class _UpcomingDutiesScreenState extends State<UpcomingDutiesScreen> {
  final Repository _repository = Repository();
  List<Duty> _duties = [];
  List<Resident> _allResidents = [];
  List<Specialist> _allSpecialists = [];
  List<DailySpecialistAssignment> _allSpecialistAssignments = [];
  bool _isLoading = true;

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
      final specialistAssignments = await _repository.getDailySpecialists();
      final todayDate = DutyDateUtils.getCurrentDutyDate();

      setState(() {
        _allResidents = residents;
        _allSpecialists = specialists;
        _allSpecialistAssignments = specialistAssignments;
        // Filter out past duties, keep today and future
        _duties = duties.where((d) => d.date.compareTo(todayDate) > 0).toList();
        // Sort by date ascending
        _duties.sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (e) {
      debugPrint('Error loading upcoming duties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الخفارات القادمة', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _duties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: _duties.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DutyCard(
                        duty: _duties[index],
                        allResidents: _allResidents,
                        allSpecialists: _allSpecialists,
                        specialistAssignment: _allSpecialistAssignments.where((a) => a.date == _duties[index].date).firstOrNull,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_outlined, size: 64, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد خفارات قادمة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم عرض الجدول حال توفره',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
