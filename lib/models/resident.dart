class Resident {
  final String id;
  final String name;
  final int stage;
  final String phoneNumber;
  final String accountType; // 'admin' or 'resident'
  final String password;
  final bool isActive;

  Resident({
    required this.id,
    required this.name,
    required this.stage,
    required this.phoneNumber,
    required this.accountType,
    required this.password,
    this.isActive = true,
  });

  factory Resident.fromJson(Map<String, dynamic> json) {
    return Resident(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      stage: int.tryParse(json['stage']?.toString() ?? '0') ?? 0,
      phoneNumber: (json['phone'] ?? json['phoneNumber'] ?? '').toString().trim(),
      accountType: (json['is_admin'] == true || json['accountType'].toString() == 'admin' || json['is_admin'].toString() == 'true') ? 'admin' : 'resident',
      password: json['password']?.toString().trim() ?? '',
      isActive: json['is_active'] == true || json['isActive'] == true || json['is_active'].toString() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stage': stage,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber, // Alias
      'accountType': accountType,
      'is_admin': isAdmin, // Alias
      'isAdmin': isAdmin, // Alias
      'password': password,
      'isActive': isActive,
      'is_active': isActive, // Alias
    };
  }

  Resident copyWith({
    String? id,
    String? name,
    int? stage,
    String? phoneNumber,
    String? accountType,
    String? password,
    bool? isActive,
  }) {
    return Resident(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountType: accountType ?? this.accountType,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isAdmin => accountType == 'admin';
}
