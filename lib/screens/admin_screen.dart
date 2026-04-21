import 'dart:math';
import 'package:flutter/material.dart';
import '../models/duty.dart';
import '../models/resident.dart';
import '../models/specialist.dart';
import '../services/repository.dart';
import '../utils/date_utils.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Repository _repository = Repository();
  bool _isLoading = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _lastSyncTime = DateTime.now(); // Initially marked as now since we load from cache
  }

  Future<void> _forceSync() async {
    setState(() => _isLoading = true);
    try {
      await _repository.refreshData();
      setState(() => _lastSyncTime = DateTime.now());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم المزامنة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل المزامنة. تأكد من الاتصال بالإنترنت.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('لوحة تحكم المسؤول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_lastSyncTime != null)
                Text(
                  'آخر تحديث: ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync),
              onPressed: _isLoading ? null : _forceSync,
              tooltip: 'تحديث وسحب البيانات',
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.people_rounded), text: 'المقيمين'),
              Tab(icon: Icon(Icons.medical_services_rounded), text: 'الاختصاصيين'),
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'الجدول'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResidentManagementTab(key: ValueKey(_lastSyncTime)),
            _SpecialistManagementTab(key: ValueKey(_lastSyncTime)),
            _DutyManagementTab(key: ValueKey(_lastSyncTime)),
          ],
        ),
      ),
    );
  }
}

class _ResidentManagementTab extends StatefulWidget {
  const _ResidentManagementTab({super.key});

  @override
  State<_ResidentManagementTab> createState() => _ResidentManagementTabState();
}

class _ResidentManagementTabState extends State<_ResidentManagementTab> {
  final Repository _repository = Repository();
  List<Resident> _residents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repository.getResidents();
      setState(() {
        _residents = res;
        _residents.sort((a, b) => b.stage.compareTo(a.stage));
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResidentDialog(Resident? resident) {
    final nameController = TextEditingController(text: resident?.name);
    final stageController = TextEditingController(text: resident?.stage.toString());
    final phoneController = TextEditingController(text: resident?.phoneNumber);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(resident == null ? 'إضافة مقيم جديد' : 'تعديل بيانات المقيم'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resident != null) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('Internal ID: ${resident.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'المرحلة (Stage)'),
                      controller: stageController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    if (resident == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(labelText: 'الرقم السري المعين'),
                        controller: passwordController,
                        obscureText: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.isEmpty || stageController.text.isEmpty || (resident == null && passwordController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')));
                      return;
                    }

                    setDialogState(() => isSaving = true);
                    try {
                      if (resident == null) {
                        final newResident = Resident(
                          id: '', 
                          name: nameController.text,
                          stage: int.tryParse(stageController.text) ?? 0,
                          phoneNumber: phoneController.text,
                          accountType: 'resident',
                          password: passwordController.text,
                          isActive: true,
                        );
                        await _repository.createResident(newResident, passwordController.text);
                      } else {
                        final updatedResident = resident.copyWith(
                          name: nameController.text,
                          stage: int.tryParse(stageController.text) ?? 0,
                          phoneNumber: phoneController.text,
                        );
                        await _repository.updateResident(updatedResident);
                      }
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حفظ'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _generateTempPassword(Resident resident) {
    final tempPass = (Random().nextInt(9000) + 1000).toString();
    showDialog(
      context: context,
      builder: (context) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إعادة تعيين كلمة المرور'),
              content: Text('هل أنت متأكد من إعادة تعيين كلمة مرور المقيم\n${resident.name}؟\n\nستكون كلمة المرور الجديدة:\n$tempPass'),
              actions: [
                TextButton(onPressed: isProcessing ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isProcessing ? null : () async {
                    setDialogState(() => isProcessing = true);
                    try {
                      await _repository.resetResidentPassword(resident.id, tempPass);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
                      }
                    } catch (e) {
                      setDialogState(() => isProcessing = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('تأكيد التغيير', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _toggleResident(Resident resident) async {
    setState(() => _isLoading = true);
    try {
      await _repository.toggleResidentStatus(resident.id, !resident.isActive);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resident.isActive ? 'تم إيقاف الحساب' : 'تم تفعيل الحساب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _residents.length,
          itemBuilder: (context, index) {
            final res = _residents[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: res.isActive ? (res.isAdmin ? Colors.red.shade50 : Colors.blue.shade50) : Colors.grey.shade100,
                  child: Text(
                    res.name.isNotEmpty ? res.name[0] : '?',
                    style: TextStyle(
                      color: res.isActive ? (res.isAdmin ? Colors.red.shade900 : Colors.blue.shade900) : Colors.grey.shade400, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  res.name, 
                  style: TextStyle(
                    decoration: res.isActive ? null : TextDecoration.lineThrough, 
                    color: res.isActive ? Colors.black87 : Colors.grey, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Stage ${res.stage}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          if (res.isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('مسؤول', style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('مقيم', style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${res.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showResidentDialog(res);
                    } else if (value == 'reset') {
                      _generateTempPassword(res);
                    } else if (value == 'toggle') {
                      _toggleResident(res);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('تعديل البيانات')])),
                    const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.password_rounded, size: 18), SizedBox(width: 8), Text('إعادة تعيين كلمة المرور')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [Icon(res.isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded, size: 18), SizedBox(width: 8), Text(res.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب')])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showResidentDialog(null),
        backgroundColor: Colors.red.shade800,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class _DutyManagementTab extends StatefulWidget {
  const _DutyManagementTab({super.key});

  @override
  State<_DutyManagementTab> createState() => _DutyManagementTabState();
}

class _DutyManagementTabState extends State<_DutyManagementTab> {
  final Repository _repository = Repository();
  List<Duty> _duties = [];
  List<Resident> _residents = [];
  List<Specialist> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final duties = await _repository.getDuties();
      final residents = await _repository.getResidents();
      final specialists = await _repository.getSpecialists();
      setState(() {
        _duties = duties;
        _duties.sort((a, b) => b.date.compareTo(a.date));
        _residents = residents.where((r) => r.isActive).toList();
        _specialists = specialists.where((s) => s.isActive).toList();
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDutyDialog(Duty? duty) {
    String date = duty?.date ?? DutyDateUtils.getCurrentDutyDate();
    List<String> selectedResidentIds = List.from(duty?.residentIds ?? []);
    String? selectedSpecialistId = duty?.specialistId;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(duty == null ? 'إضافة خفارة جديدة' : 'تعديل خفارة'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('التاريخ'),
                        subtitle: Text(DutyDateUtils.formatArabicReadableDate(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: duty != null ? null : () async {
                           final picked = await showDatePicker(
                             context: context, 
                             initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                             firstDate: DateTime(2024), 
                             lastDate: DateTime(2030),
                           );
                           if (picked != null) {
                             setDialogState(() => date = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                           }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSpecialistId,
                        decoration: const InputDecoration(
                          labelText: 'الاختصاصي الخفر',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('لا يوجد')),
                          ..._specialists.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              )),
                        ],
                        onChanged: (val) {
                          setDialogState(() => selectedSpecialistId = val);
                        },
                      ),
                      const Divider(),
                      const Text('المقيمين المكلفين:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._residents.map((res) {
                        final isSelected = selectedResidentIds.contains(res.id);
                        return CheckboxListTile(
                          title: Text(res.name),
                          subtitle: Text('Stage ${res.stage}'),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                if (!selectedResidentIds.contains(res.id)) selectedResidentIds.add(res.id);
                              } else {
                                selectedResidentIds.remove(res.id);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);
                    try {
                      final newDuty = Duty(
                        id: duty?.id ?? date,
                        date: date,
                        residentIds: selectedResidentIds,
                        specialistId: selectedSpecialistId,
                      );
                      
                      if (duty == null) {
                        await _repository.addDuty(newDuty);
                      } else {
                        await _repository.updateDuty(newDuty);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حفظ'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _deleteDutyConfirm(Duty duty) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('حذف خفارة'),
              content: Text('هل أنت متأكد من حذف خفارة يوم ${DutyDateUtils.formatArabicReadableDate(duty.date)}؟'),
              actions: [
                TextButton(onPressed: isDeleting ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isDeleting ? null : () async {
                    setDialogState(() => isDeleting = true);
                    try {
                      await _repository.deleteDuty(duty.id);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
                      }
                    } catch (e) {
                      setDialogState(() => isDeleting = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: isDeleting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حذف', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _importScheduleDialog() {
    final TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isImporting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('استيراد جدول شهري'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('أدخل البيانات بصيغة:\nYYYY-MM-DD, ID1, ID2, ...\nكل يوم في سطر منفصل', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '2024-04-01, res_1, res_2\n2024-04-02, res_3, res_4',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: isImporting ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isImporting ? null : () async {
                    if (importController.text.trim().isEmpty) return;
                    setDialogState(() => isImporting = true);
                    try {
                      List<Duty> dutiesToImport = [];
                      final lines = importController.text.split('\n');
                      for (var line in lines) {
                        if (line.trim().isEmpty) continue;
                        final parts = line.split(',');
                        if (parts.length >= 2) {
                          final date = parts[0].trim();
                          final ids = parts.sublist(1).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                          dutiesToImport.add(Duty(id: date, date: date, residentIds: ids));
                        }
                      }
                      
                      if (dutiesToImport.isNotEmpty) {
                        await _repository.importSchedule(dutiesToImport);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استيراد ${dutiesToImport.length} خفارة بنجاح')));
                        }
                      }
                    } catch (e) {
                      setDialogState(() => isImporting = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في البيانات: $e')));
                    }
                  },
                  child: isImporting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('استيراد'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          itemCount: _duties.length,
          itemBuilder: (context, index) {
            final duty = _duties[index];
             return Card(
               elevation: 0,
               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(16),
                 side: BorderSide(color: Colors.grey.shade200),
               ),
               child: ListTile(
                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 leading: CircleAvatar(
                   radius: 24,
                   backgroundColor: primaryColor.withValues(alpha: 0.05),
                   child: Icon(Icons.calendar_month_rounded, color: primaryColor, size: 24),
                 ),
                 title: Text(
                   DutyDateUtils.formatArabicReadableDate(duty.date),
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                 ),
                 subtitle: Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey.shade600),
                           const SizedBox(width: 4),
                           Text(
                             'الاختصاصي: ${_specialists.firstWhere((s) => s.id == duty.specialistId, orElse: () => Specialist(id: '', name: 'لا يوجد', phone: '', isActive: false)).name}',
                             style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                           ),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey.shade600),
                           const SizedBox(width: 4),
                           Text(
                             'عدد المقيمين: ${duty.residentIds.length}',
                             style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                       onPressed: () => _showDutyDialog(duty),
                       tooltip: 'تعديل',
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                       onPressed: () => _deleteDutyConfirm(duty),
                       tooltip: 'حذف',
                     ),
                   ],
                 ),
               ),
             );
           },
         ),
       ),
       floatingActionButton: Column(
         mainAxisAlignment: MainAxisAlignment.end,
         children: [
           FloatingActionButton(
             heroTag: 'add_duty',
             mini: true,
             onPressed: () => _showDutyDialog(null),
             backgroundColor: Colors.green.shade600,
             elevation: 4,
             child: const Icon(Icons.add_rounded, color: Colors.white),
           ),
           const SizedBox(height: 16),
           FloatingActionButton.extended(
             heroTag: 'import_duty',
             onPressed: _importScheduleDialog,
             backgroundColor: primaryColor,
             elevation: 4,
             icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
             label: const Text('استيراد جدول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           ),
         ],
       ),
    );
  }
}

class _SpecialistManagementTab extends StatefulWidget {
  const _SpecialistManagementTab({super.key});

  @override
  State<_SpecialistManagementTab> createState() => _SpecialistManagementTabState();
}

class _SpecialistManagementTabState extends State<_SpecialistManagementTab> {
  final Repository _repository = Repository();
  List<Specialist> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final spec = await _repository.getSpecialists();
      setState(() {
        _specialists = spec;
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSpecialistDialog(Specialist? specialist) {
    final nameController = TextEditingController(text: specialist?.name);
    final phoneController = TextEditingController(text: specialist?.phone);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(specialist == null ? 'إضافة اختصاصي جديد' : 'تعديل بيانات الاختصاصي'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم مطلوب')));
                      return;
                    }

                    setDialogState(() => isSaving = true);
                    try {
                      final updatedSpecialist = Specialist(
                        id: specialist?.id ?? '',
                        name: nameController.text,
                        phone: phoneController.text,
                        isActive: specialist?.isActive ?? true,
                      );
                      
                      await _repository.updateSpecialist(updatedSpecialist);
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حفظ'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _toggleSpecialist(Specialist specialist) async {
    setState(() => _isLoading = true);
    try {
      await _repository.toggleSpecialistStatus(specialist.id, !specialist.isActive);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: _specialists.length,
          itemBuilder: (context, index) {
            final spec = _specialists[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: spec.isActive ? Colors.red.shade50 : Colors.grey.shade100,
                  child: Icon(
                    Icons.medical_services_rounded, 
                    color: spec.isActive ? Colors.red.shade900 : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                title: Text(
                  spec.name, 
                  style: TextStyle(
                    decoration: spec.isActive ? null : TextDecoration.lineThrough, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: spec.isActive ? Colors.black87 : Colors.grey,
                  )
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(spec.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${spec.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showSpecialistDialog(spec);
                    } else if (value == 'toggle') {
                      _toggleSpecialist(spec);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('تعديل البيانات')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [Icon(spec.isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded, size: 18), SizedBox(width: 8), Text(spec.isActive ? 'إيقاف' : 'تفعيل')])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_specialist',
        onPressed: () => _showSpecialistDialog(null),
        backgroundColor: primaryColor,
        elevation: 4,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}
