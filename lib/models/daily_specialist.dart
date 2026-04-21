import 'package:flutter/foundation.dart';

class DailySpecialistAssignment {
  final String date; // Format: yyyy-MM-dd
  final String specialistOnCallId;
  final String? specialistOnCallName;
  final String? specialistOnCallPhone;
  final String orSpecialistId;
  final String? orSpecialistName;
  final String? orSpecialistPhone;
  final String consultationSpecialistId;
  final String? consultationSpecialistName;
  final String? consultationSpecialistPhone;
  final String? notes;
  final DateTime? updatedAt;

  DailySpecialistAssignment({
    required this.date,
    required this.specialistOnCallId,
    this.specialistOnCallName,
    this.specialistOnCallPhone,
    required this.orSpecialistId,
    this.orSpecialistName,
    this.orSpecialistPhone,
    required this.consultationSpecialistId,
    this.consultationSpecialistName,
    this.consultationSpecialistPhone,
    this.notes,
    this.updatedAt,
  });

  factory DailySpecialistAssignment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      
      // Handle Numeric Serial Dates (from Google Sheets/Excel)
      if (d is int || d is double) {
        try {
          // Google Sheets/Excel start from 1899-12-30
          // For just dates (integers), we can use this
          return DateTime(1899, 12, 30).add(Duration(days: d.toInt()));
        } catch (_) {
          return null;
        }
      }

      if (d is String) {
        if (d.isEmpty) return null;
        // Try standard ISO first
        var parsed = DateTime.tryParse(d);
        if (parsed != null) return parsed;
        
        // Handle M/D/YYYY or D/M/YYYY (common in sheets)
        try {
          final parts = d.split(RegExp(r'[/-]'));
          if (parts.length >= 3) {
            int first = int.parse(parts[0]);
            int second = int.parse(parts[1]);
            int third = int.parse(parts[2]);
            
            if (first > 1000) { // YYYY/M/D
              return DateTime(first, second, third);
            } else if (third > 1000) { // M/D/YYYY or D/M/YYYY
              // Use Baghdad/International common D/M/YYYY if month isn't clear,
              // but Sheets often defaults to M/D/YYYY. Let's try to be smart.
              int month = first;
              int day = second;
              if (month > 12) {
                month = second;
                day = first;
              }
              return DateTime(third, month, day);
            }
          }
        } catch (e) {
          debugPrint('Failed to parse complex date string: $d - Error: $e');
        }
      }
      return null;
    }

    DateTime? parseUpdatedAt(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d);
      return null;
    }

    final dateValue = parseDate(json['date'] ?? json['duty_date'] ?? '');

    return DailySpecialistAssignment(
      date: dateValue != null 
          ? "${dateValue.year}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}" 
          : '',
      specialistOnCallId: json['specialist_on_call_id']?.toString() ?? '',
      specialistOnCallName: json['specialist_on_call_name']?.toString(),
      specialistOnCallPhone: json['specialist_on_call_phone']?.toString(),
      orSpecialistId: json['or_specialist_id']?.toString() ?? '',
      orSpecialistName: json['or_specialist_name']?.toString(),
      orSpecialistPhone: json['or_specialist_phone']?.toString(),
      consultationSpecialistId: json['consultation_specialist_id']?.toString() ?? '',
      consultationSpecialistName: json['consultation_specialist_name']?.toString(),
      consultationSpecialistPhone: json['consultation_specialist_phone']?.toString(),
      notes: json['notes']?.toString(),
      updatedAt: parseUpdatedAt(json['updated_at']),
    );
  }

  // --- Helpers for Multiple Specialists ---

  List<String> _splitBySpecialist(String? text) {
    if (text == null || text.isEmpty) return [];
    
    // Replace newlines with spaces for easier splitting
    String normalized = text.replaceAll('\n', ' ').trim();
    
    // If it contains " د." (case where multiple names are joined), split by it
    // But keep the "د." prefix for each
    if (normalized.contains(' د.')) {
      List<String> parts = normalized.split(' د.');
      return parts.indexed.map((entry) {
        int index = entry.$1;
        String val = entry.$2.trim();
        if (index == 0) return val; // First one already has "د." usually
        return 'د. $val'; // Add back the prefix for subsequent ones
      }).where((s) => s.isNotEmpty).toList();
    }
    
    // Otherwise, just keep as is (single name)
    return [normalized];
  }

  List<String> _splitIds(String? text) {
    if (text == null || text.isEmpty) return [];
    return text.toString().split(RegExp(r'[\s\n]+')).where((s) => s.isNotEmpty).toList();
  }

  List<String> get specialistOnCallNames => _splitBySpecialist(specialistOnCallName);
  List<String> get orSpecialistNames => _splitBySpecialist(orSpecialistName);
  List<String> get consultationSpecialistNames => _splitBySpecialist(consultationSpecialistName);

  List<String> get specialistOnCallIds => _splitIds(specialistOnCallId);
  List<String> get orSpecialistIds => _splitIds(orSpecialistId);
  List<String> get consultationSpecialistIds => _splitIds(consultationSpecialistId);

  bool get hasAnySpecialist {
    return (specialistOnCallName?.isNotEmpty ?? false) ||
           (orSpecialistName?.isNotEmpty ?? false) ||
           (consultationSpecialistName?.isNotEmpty ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'specialist_on_call_id': specialistOnCallId,
      'specialist_on_call_name': specialistOnCallName,
      'specialist_on_call_phone': specialistOnCallPhone,
      'or_specialist_id': orSpecialistId,
      'or_specialist_name': orSpecialistName,
      'or_specialist_phone': orSpecialistPhone,
      'consultation_specialist_id': consultationSpecialistId,
      'consultation_specialist_name': consultationSpecialistName,
      'consultation_specialist_phone': consultationSpecialistPhone,
      'notes': notes,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
