import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/repository.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  final Repository _repository = Repository();
  List<Resident> _residents = [];
  List<Specialist> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repository.getResidents();
      final spec = await _repository.getSpecialists();
      setState(() {
        _residents = res;
        _specialists = spec.where((s) => s.isActive).toList();
        // Sort residents by stage
        _residents.sort((a, b) => b.stage.compareTo(a.stage));
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إجراء المكالمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('دليل الهواتف', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'المقيمين', icon: Icon(Icons.people_alt_rounded, size: 20)),
              Tab(text: 'الأخصائيين', icon: Icon(Icons.medical_services_rounded, size: 20)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildResidentList(),
                  _buildSpecialistList(),
                ],
              ),
      ),
    );
  }

  Widget _buildResidentList() {
    if (_residents.isEmpty) {
      return _buildEmptyState('لا يوجد مقيمين حالياً');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _residents.length,
      itemBuilder: (context, index) {
        final res = _residents[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: res.isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
              child: Text(
                res.name.isNotEmpty ? res.name[0] : '?',
                style: TextStyle(
                  color: res.isAdmin ? Colors.red.shade900 : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Stage ${res.stage}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(res.phoneNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            trailing: _buildCallButton(res.phoneNumber),
          ),
        );
      },
    );
  }

  Widget _buildSpecialistList() {
    if (_specialists.isEmpty) {
      return _buildEmptyState('لا يوجد أخصائيين حالياً');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _specialists.length,
      itemBuilder: (context, index) {
        final specialist = _specialists[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.medical_information_rounded, color: Colors.blue.shade900, size: 24),
            ),
            title: Text(specialist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('أخصائي', style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(specialist.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            trailing: _buildCallButton(specialist.phone),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCallButton(String phone) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 22),
        onPressed: () => _callPhone(phone),
        tooltip: 'الاتصال بالرقم',
      ),
    );
  }
}
