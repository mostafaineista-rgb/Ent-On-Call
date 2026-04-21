import 'package:flutter/material.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../models/daily_specialist.dart';
import '../utils/date_utils.dart';

class DutyCard extends StatelessWidget {
  final Duty duty;
  final List<Resident> allResidents;
  final List<Specialist> allSpecialists;
  final DailySpecialistAssignment? specialistAssignment;
  final bool isToday;

  const DutyCard({
    super.key,
    required this.duty,
    required this.allResidents,
    required this.allSpecialists,
    this.specialistAssignment,
    this.isToday = false,
  });

  Widget _buildRoleRow(String title, String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
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
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
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
    // Stage-based role logic (Unchanged as requested)
    Resident? stage5;
    Resident? stage4;
    Resident? stage3;
    Resident? stage2;

    for (final id in duty.residentIds) {
      final res = allResidents.where((r) => r.id == id).firstOrNull;
      if (res != null) {
        if (res.stage == 5) {
          stage5 = res;
        } else if (res.stage == 4) {
          stage4 = res;
        } else if (res.stage == 3) {
          stage3 = res;
        } else if (res.stage == 2) {
          stage2 = res;
        }
      }
    }

    Resident? teamLeader = stage5 ?? stage4;
    Resident? thirdCall = stage5 != null ? stage4 : null;
    Resident? secondCall = stage3;
    Resident? firstCall = stage2;

    final specialist = duty.specialistId != null 
      ? allSpecialists.where((s) => s.id == duty.specialistId).firstOrNull 
      : null;

    final Color primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        DutyDateUtils.formatArabicReadableDate(duty.date),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withBlue(255)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'خفارة اليوم',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'الفريق المناوب',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Divider(height: 1),
            ),
            
            // Specialist row
            _buildRoleRow(
              'الاختصاصي الخفر', 
              specialist?.name ?? 'لا يوجد اختصاص خفر', 
              Icons.medical_services, 
              Colors.red.shade700
            ),
            
            // Resident roles
            if (teamLeader != null) 
              _buildRoleRow('رئيس الفريق (Team Leader)', teamLeader.name, Icons.star_rounded, Colors.amber.shade800),
            if (thirdCall != null) 
              _buildRoleRow('الكول الثالث (Third Call)', thirdCall.name, Icons.looks_3_rounded, Colors.purple.shade600),
            if (secondCall != null) 
              _buildRoleRow('الكول الثاني (Second Call)', secondCall.name, Icons.looks_two_rounded, Colors.orange.shade700),
            if (firstCall != null) 
              _buildRoleRow('الكول الأول (First Call)', firstCall.name, Icons.looks_one_rounded, Colors.teal.shade600),
            
            if (duty.residentIds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('لم يتم تحديد فريق بعد', style: TextStyle(color: Colors.grey)),
                ),
              ),

            // --- Specialist Team Section ---
            const SizedBox(height: 24),
            const Text(
              'فريق الاختصاصيين',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Divider(height: 1),
            ),

            if (DutyDateUtils.isFridayDate(duty.date))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'جمعة مباركة',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              )
            else if (specialistAssignment != null)
              Column(
                children: [
                   _buildRoleRow(
                    'الاختصاصي خفر العمليات', 
                    specialistAssignment!.orSpecialistNames.isNotEmpty 
                        ? specialistAssignment!.orSpecialistNames.join(' / ') 
                        : 'غير محدد', 
                    Icons.biotech_rounded, 
                    Colors.blue.shade700
                  ),
                  _buildRoleRow(
                    'الاختصاصي في الاستشارية', 
                    specialistAssignment!.consultationSpecialistNames.isNotEmpty 
                        ? specialistAssignment!.consultationSpecialistNames.join(' / ') 
                        : 'غير محدد', 
                    Icons.assignment_ind_rounded, 
                    Colors.teal.shade700
                  ),
                ],
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('لم يتم تحديد جدول الاختصاصيين بعد', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
