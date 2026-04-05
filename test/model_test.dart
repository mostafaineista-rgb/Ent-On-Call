import 'package:flutter_test/flutter_test.dart';
import 'package:ent_on_call/models/resident.dart';
import 'package:ent_on_call/models/duty.dart';

void main() {
  group('Resident Model Tests', () {
    test('Resident.fromJson should parse correctly', () {
      final json = {
        'id': 'res123',
        'name': 'Dr. Ahmad',
        'stage': '4',
        'phone': '07701234567',
        'is_admin': true,
        'password': 'password123',
        'is_active': true
      };

      final resident = Resident.fromJson(json);

      expect(resident.id, 'res123');
      expect(resident.name, 'Dr. Ahmad');
      expect(resident.stage, 4);
      expect(resident.phoneNumber, '07701234567');
      expect(resident.accountType, 'admin');
      expect(resident.isAdmin, true);
      expect(resident.isActive, true);
    });

    test('Resident.copyWith should update fields correctly', () {
      final resident = Resident(
        id: '1',
        name: 'Old Name',
        stage: 1,
        phoneNumber: '000',
        accountType: 'resident',
        password: 'pwd',
        isActive: true,
      );

      final updated = resident.copyWith(name: 'New Name', isActive: false);

      expect(updated.name, 'New Name');
      expect(updated.isActive, false);
      expect(updated.id, '1'); // Unchanged
    });
  });

  group('Duty Model Tests', () {
    test('Duty.fromJson should parse correctly with stage specific fields', () {
      final json = {
        'id': '2024-04-01',
        'duty_date': '2024-04-01',
        'stage2_id': 'res1',
        'stage3_id': 'res2',
        'team_leader_id': 'admin1'
      };

      final duty = Duty.fromJson(json);

      expect(duty.date, '2024-04-01');
      expect(duty.residentIds, containsAll(['res1', 'res2', 'admin1']));
    });
  });
}
