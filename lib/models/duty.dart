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
      if (json[field] != null && json[field].toString().isNotEmpty) {
        final idStr = json[field].toString();
        if (!rIds.contains(idStr)) rIds.add(idStr);
      }
    }
    if (json['residentIds'] != null) {
      for (var id in List<String>.from(json['residentIds'])) {
        if (!rIds.contains(id)) rIds.add(id);
      }
    }

    return Duty(
      id: json['id']?.toString() ?? json['duty_date']?.toString() ?? '',
      date: json['duty_date']?.toString() ?? json['date']?.toString() ?? '',
      residentIds: rIds,
      specialistId: json['specialist_id']?.toString(),
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
