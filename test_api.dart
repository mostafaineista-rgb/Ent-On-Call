import 'lib/services/api_service.dart';

void main() async {
  final api = ApiService();
  try {
    print('Fetching data...');
    final residents = await api.fetchResidents();
    print('Residents loaded: ${residents.length}');
    for (var resident in residents) {
      print('Resident: ${resident.id} - ${resident.name} (Admin: ${resident.isAdmin}, Pass: ${resident.password})');
    }

    final duties = await api.fetchDuties();
    print('Duties loaded: ${duties.length}');
    if (duties.isNotEmpty) {
      final firstDuty = duties.firstWhere((d) => d.residentIds.isNotEmpty, orElse: () => duties.first);
      print('Duty for ${firstDuty.date} has residents: ${firstDuty.residentIds}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
