import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../utils/date_utils.dart';
import '../widgets/duty_card.dart';

class UpcomingDutiesScreen extends ConsumerStatefulWidget {
  const UpcomingDutiesScreen({super.key});

  @override
  ConsumerState<UpcomingDutiesScreen> createState() => _UpcomingDutiesScreenState();
}

class _UpcomingDutiesScreenState extends ConsumerState<UpcomingDutiesScreen> {
  final GlobalKey _todayKey = GlobalKey();
  bool _hasScrolled = false;

  void _scrollToToday() {
    if (_hasScrolled) return;
    
    // Use a small delay to ensure the list is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_todayKey.currentContext != null) {
        Scrollable.ensureVisible(
          _todayKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _hasScrolled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          final todayStr = DutyDateUtils.getCurrentDutyDate();
          final now = DutyDateUtils.getCurrentDutyDateTime();
          final startOfMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          
          final filteredDuties = duties.where((d) => d.date.compareTo(startOfMonth) >= 0).toList();
          filteredDuties.sort((a, b) => a.date.compareTo(b.date));

          if (filteredDuties.isEmpty) {
            return _buildEmptyState(ref);
          }

          // Trigger scroll after build if we found today
          if (!_hasScrolled) {
             _scrollToToday();
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

              final isToday = DutyDateUtils.isSameDay(duty.date, todayStr);

              return Padding(
                key: isToday ? _todayKey : null,
                padding: const EdgeInsets.only(bottom: 12),
                child: DutyCard(
                  duty: duty,
                  allResidents: residents,
                  allSpecialists: specialists,
                  specialistAssignment: assignment,
                  isToday: isToday,
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
