import 'package:flutter/foundation.dart';

class Duty {
  final String id;
  final String date; // Format: YYYY-MM-DD
  final List<String> residentIds;
  final String? specialistId;

  Duty({
    required this.id,
    required this.date,
    required this.residentIds,
    this.specialistId,
  });

  factory Duty.fromJson(Map<String, dynamic> json) {
    List<String> rIds = [];
    final fields = ['stage2_id', 'stage3_id', 'stage4_id', 'stage5_id', 'team_leader_id'];
    for (var field in fields) {
      if (json[field] != null && json[field].toString().trim().isNotEmpty) {
        final idStr = json[field].toString().trim();
        if (!rIds.contains(idStr)) rIds.add(idStr);
      }
    }
    
    // Handle case where residentIds might be in the JSON directly
    if (json['residentIds'] != null && json['residentIds'] is List) {
      for (var id in List<dynamic>.from(json['residentIds'])) {
        final idStr = id.toString().trim();
        if (idStr.isNotEmpty && !rIds.contains(idStr)) rIds.add(idStr);
      }
    }

    // Lenient date and ID parsing
    String dutyId = (json['id'] ?? json['duty_id'] ?? json['duty_date'] ?? '').toString().trim();
    String dutyDate = (json['duty_date'] ?? json['date'] ?? json['Date'] ?? '').toString().trim();
    
    if (dutyId.isEmpty || dutyDate.isEmpty) {
      debugPrint('Duty.fromJson: Missing key! Keys present: ${json.keys}');
    }
    
    // Normalize date format if it contains time (e.g. ISO string)
    if (dutyDate.contains('T')) {
      dutyDate = dutyDate.split('T')[0];
    }

    return Duty(
      id: dutyId,
      date: dutyDate,
      residentIds: rIds,
      specialistId: json['specialist_id']?.toString() ?? json['specialistId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'residentIds': residentIds,
      'specialist_id': specialistId,
    };
  }
}
