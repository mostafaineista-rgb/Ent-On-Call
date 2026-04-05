import 'package:flutter/material.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import '../widgets/duty_card.dart';

class MyDutiesScreen extends StatefulWidget {
  const MyDutiesScreen({super.key});

  @override
  State<MyDutiesScreen> createState() => _MyDutiesScreenState();
}

class _MyDutiesScreenState extends State<MyDutiesScreen> {
  final Repository _repository = Repository();
  late final AuthService _authService = AuthService(_repository);
  List<Duty> _myDuties = [];
  List<Resident> _allResidents = [];
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
      final user = await _authService.getLoggedInUser();
      if (user == null) return;

      final duties = await _repository.getDuties();
      final residents = await _repository.getResidents();
      final specialists = await _repository.getSpecialists();

      setState(() {
        _allResidents = residents;
        _allSpecialists = specialists;
        _myDuties = duties.where((d) => d.residentIds.contains(user.id)).toList();
        _myDuties.sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (e) {
      debugPrint('Error loading my duties: $e');
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
        title: const Text('خفاراتي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myDuties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: _myDuties.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DutyCard(
                        duty: _myDuties[index],
                        allResidents: _allResidents,
                        allSpecialists: _allSpecialists,
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
            child: Icon(Icons.person_pin_circle_outlined, size: 64, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد خفارات مسجلة لك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيظهر جدول خفاراتك الخاصة هنا',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
