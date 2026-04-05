class Specialist {
  final String id;
  final String name;
  final String phone;
  final bool isActive;

  Specialist({
    required this.id,
    required this.name,
    required this.phone,
    this.isActive = true,
  });

  factory Specialist.fromJson(Map<String, dynamic> json) {
    return Specialist(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      phone: json['phone']?.toString().trim() ?? '',
      isActive: json['is_active'] == true || json['isActive'] == true || json['is_active'].toString() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'is_active': isActive,
    };
  }

  Specialist copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isActive,
  }) {
    return Specialist(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
