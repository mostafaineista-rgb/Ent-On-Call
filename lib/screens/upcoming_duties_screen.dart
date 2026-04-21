import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/providers.dart';
import '../utils/date_utils.dart';
import '../widgets/duty_card.dart';

class UpcomingDutiesScreen extends ConsumerWidget {
  const UpcomingDutiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dutiesAsync = ref.watch(dutiesProvider);
    final residentsAsync = ref.watch(residentsProvider);
    final specialistsAsync = ref.watch(specialistsProvider);
    final assignmentsAsync = ref.watch(dailySpecialistsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('جدول الخفارات'),
        centerTitle: true,
      ),
      body: dutiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (duties) {
          final now = DutyDateUtils.getCurrentDutyDateTime();
          final startOfMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          
          final filteredDuties = duties.where((d) => d.date.compareTo(startOfMonth) >= 0).toList();
          filteredDuties.sort((a, b) => a.date.compareTo(b.date));

          if (filteredDuties.isEmpty) {
            return _buildEmptyState(ref);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: filteredDuties.length,
            itemBuilder: (context, index) {
              final duty = filteredDuties[index];
              final residents = residentsAsync.value ?? [];
              final specialists = specialistsAsync.value ?? [];
              final assignments = assignmentsAsync.value ?? [];
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
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لا توجد خفارات مسجلة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
