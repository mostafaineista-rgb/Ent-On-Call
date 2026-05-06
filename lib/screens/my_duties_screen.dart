import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/providers.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import '../widgets/duty_card.dart';
import '../utils/date_utils.dart';

class MyDutiesScreen extends ConsumerWidget {
  const MyDutiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dutiesAsync = ref.watch(dutiesProvider);
    final residentsAsync = ref.watch(residentsProvider);
    final specialistsAsync = ref.watch(specialistsProvider);
    final assignmentsAsync = ref.watch(dailySpecialistsProvider);
    final authService = getIt<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('خفاراتي'),
        centerTitle: true,
      ),
      body: dutiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (duties) {
          return FutureBuilder<dynamic>(
            future: authService.getLoggedInUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final user = snapshot.data;
              if (user == null) {
                return const Center(child: Text('يرجى تسجيل الدخول لعرض خفاراتك'));
              }

              final isResident = user is Resident;
              final isSpecialist = user is Specialist;

              if (!isResident && !isSpecialist) {
                return const Center(child: Text('خفارات الاختصاصيين تظهر في الجدول الرئيسي', style: TextStyle(fontSize: 16, color: Colors.grey)));
              }

              final now = DutyDateUtils.getCurrentDutyDateTime();
              final today = DateTime(now.year, now.month, now.day);
              final assignments = assignmentsAsync.value ?? [];
              
              final myDuties = duties.where((d) {
                bool isMyDuty = false;
                if (isResident) {
                  isMyDuty = d.residentIds.contains(user.id);
                } else if (isSpecialist) {
                  // Check direct duty assignment
                  if (d.specialistId == user.id) {
                    isMyDuty = true;
                  } else {
                    // Check daily specialist assignments for the same date
                    final assignment = assignments.where((a) => a.date == d.date).firstOrNull;
                    if (assignment != null) {
                      if (assignment.specialistOnCallIds.contains(user.id) ||
                          assignment.orSpecialistIds.contains(user.id) ||
                          assignment.consultationSpecialistIds.contains(user.id)) {
                        isMyDuty = true;
                      }
                    }
                  }
                }

                if (!isMyDuty) return false;
                
                final dutyDate = DutyDateUtils.parseDate(d.date);
                if (dutyDate == null) return false;

                final normalizedDutyDate = DateTime(dutyDate.year, dutyDate.month, dutyDate.day);
                return !normalizedDutyDate.isBefore(today);
              }).toList();

              // Sort ascending (closest duties first)
              myDuties.sort((a, b) {
                final dateA = DutyDateUtils.parseDate(a.date) ?? DateTime(9999);
                final dateB = DutyDateUtils.parseDate(b.date) ?? DateTime(9999);
                return dateA.compareTo(dateB);
              });

              if (myDuties.isEmpty) {
                return _buildEmptyState(ref);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: myDuties.length,
                itemBuilder: (context, index) {
                  final duty = myDuties[index];
                  final residents = residentsAsync.value ?? [];
                  final specialists = specialistsAsync.value ?? [];
                  final assignment = assignments.where((a) => a.date == duty.date).firstOrNull;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DutyCard(
                      duty: duty,
                      allResidents: residents,
                      allSpecialists: specialists,
                      specialistAssignment: assignment,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لا توجد خفارات مسجلة باسمك', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(dutiesProvider.notifier).loadDuties(),
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}
