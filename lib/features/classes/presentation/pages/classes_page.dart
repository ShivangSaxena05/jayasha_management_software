import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:collection/collection.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/features/fees/data/models/fee_structure.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';

import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'dart:async';
import 'dart:io';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  String? _selectedClassId;
  bool _isInit = true;
  String? _errorMessage;
  List<Teacher> _teachers = [];
  List<FeeStructure> _allFeeStructures = [];

  static const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadData();
      _isInit = false;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final staffRepo = Provider.of<StaffRepository>(context, listen: false);
      final feeRepo = Provider.of<FeeRepository>(context, listen: false);

      final session = await dashboardRepo.getCurrentSession();
      if (session != null && session.id != null) {
        await classRepo.fetchClasses(session.id!);
        final teachers = await staffRepo.getTeachers();
        final structures = await feeRepo.getFeeStructures();
        if (mounted) {
          setState(() {
            _teachers = teachers;
            _allFeeStructures = structures.map((json) => FeeStructure.fromJson(json)).toList();
            if (classRepo.classes.isNotEmpty && _selectedClassId == null) {
              _selectedClassId = classRepo.classes.first.id;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading classes data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getHumanReadableError(e);
        });
      }
    }
  }

  String _getHumanReadableError(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return 'The connection timed out. Please try again later.';
    }
    return 'An unexpected error occurred while loading classes. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final classRepo = Provider.of<ClassRepository>(context);
    final classes = classRepo.classes;

    if (_selectedClassId == null && classes.isNotEmpty) {
      _selectedClassId = classes.first.id;
    }

    final currentClass = classes.firstWhereOrNull(
      (c) => c.id == _selectedClassId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side: Dynamic Class List
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Classes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box_rounded, color: AppColors.primary),
                        onPressed: _showAddClassDialog,
                        tooltip: 'Add New Class',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: classRepo.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      final isSelected = _selectedClassId == cls.id;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => setState(() => _selectedClassId = cls.id),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.1),
                          selectedColor: AppColors.primary,
                          leading: Icon(
                            Icons.class_outlined,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(
                            cls.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side: Class Details
          Expanded(
            child: classRepo.isLoading
                ? const Center(child: CircularProgressIndicator())
                : classes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No classes found',
                              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text('Add a new class from the sidebar to get started', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : currentClass == null
                        ? const Center(child: Text("Select a class from the list"))
                        : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentClass.name} Management',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text('Sections: ${currentClass.sections.isEmpty ? "None" : currentClass.sections.join(', ')}'),
                          const Text('Manage timetable, teachers, and fee structure'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Management Cards
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.5,
                    children: [
                      _buildManagementCard(
                        'Class Teacher',
                        Icons.person_pin_rounded,
                        'Main: ${currentClass.classTeacher}\nAssistant: ${currentClass.assistantTeacher ?? "None"}',
                        Colors.blue,
                        () => _showTeachersDialog(currentClass),
                      ),
                      _buildManagementCard(
                        'Subjects',
                        Icons.book_rounded,
                        currentClass.subjects.isEmpty
                          ? 'No subjects added'
                          : currentClass.subjects.join(', '),
                        Colors.orange,
                        () => _showSubjectsDialog(currentClass),
                      ),
                      _buildManagementCard(
                        'Fee Structure',
                        Icons.payments_rounded,
                        _getFeeDisplay(currentClass),
                        Colors.green,
                        () => _showFeeStructureDialog(currentClass),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Timetable Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Weekly Timetable (Subject + Teacher)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                                    onPressed: () async {
                                      final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
                                      final session = await dashboardRepo.getCurrentSession();
                                      if (mounted) {
                                        PdfGenerator.downloadClassTimetable(
                                          schoolClass: currentClass,
                                          sessionName: session?.sessionName,
                                        );
                                      }
                                    },
                                    tooltip: 'Download Timetable',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.settings_outlined, size: 20),
                                    onPressed: () => _showTimetableSettingsDialog(currentClass),
                                    tooltip: 'Timetable Settings',
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Click cell to edit', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade200),
                              defaultColumnWidth: const FixedColumnWidth(120),
                              children: [
                                // Header
                                TableRow(
                                  children: [
                                    const TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    ..._days.map((day) => TableCell(
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                                // Rows
                                ...List.generate(currentClass.timetable.length, (pIdx) {
                                  return TableRow(
                                    children: [
                                      TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('P${pIdx + 1}')))),
                                      ...List.generate(6, (dIdx) {
                                        final entry = currentClass.timetable[pIdx][dIdx];
                                        return TableCell(
                                          child: InkWell(
                                            onTap: () => _showEditTimetableDialog(currentClass, pIdx, dIdx, entry),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              color: entry?.subject == 'LUNCH' ? Colors.grey.shade100 : Colors.transparent,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    entry?.subject ?? '-',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  if (entry != null && entry.subject != 'LUNCH')
                                                    Text(
                                                      entry.teacherName,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(String title, IconData icon, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, height: 1.2, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _showTimetableSettingsDialog(SchoolClass currentClass) {
    final periodController = TextEditingController(text: currentClass.timetable.length.toString());
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Timetable Settings - ${currentClass.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adjusting the number of periods will reset the timetable if reduced, or add empty slots if increased.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Number of Periods Per Day'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final newCount = int.tryParse(periodController.text);
                if (newCount == null || newCount < 1 || newCount > 12) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number of periods (1-12)')));
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  final success = await Provider.of<ClassRepository>(context, listen: false).updateNumberOfPeriods(currentClass.id!, newCount);
                  if (success && mounted) {
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update periods')));
                  }
                } catch (e) {
                  debugPrint('Error updating periods: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')));
                  }
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
      ),
    ).then((_) => periodController.dispose());
  }

  void _showAddClassDialog() {
    final nameController = TextEditingController();
    final sectionsController = TextEditingController(text: 'A');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g. Class 9 or Nursery',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectionsController,
                decoration: const InputDecoration(
                  labelText: 'Sections (comma separated)',
                  hintText: 'e.g. A, B, C',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isEmpty) return;

                final classRepo = Provider.of<ClassRepository>(context, listen: false);
                if (classRepo.classes.any((c) => c.name.toLowerCase() == nameController.text.toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A class with this name already exists')),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
                  final session = await dashboardRepo.getCurrentSession();

                  if (session?.id != null) {
                    final sections = sectionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final success = await classRepo.addClass(session!.id!, nameController.text, sections);
                    if (success && mounted) {
                      final newClass = classRepo.classes.lastWhere((c) => c.name == nameController.text);
                      Navigator.pop(context);
                      setState(() => _selectedClassId = newClass.id);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add class. Please try again.')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error adding class: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')),
                    );
                  }
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Class'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      sectionsController.dispose();
    });
  }

  void _showTeachersDialog(SchoolClass currentClass) {
    final mainTeacherController = TextEditingController(text: currentClass.classTeacher);
    final assistantTeacherController = TextEditingController(text: currentClass.assistantTeacher ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Teachers - ${currentClass.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: mainTeacherController, decoration: const InputDecoration(labelText: 'Class Teacher')),
              const SizedBox(height: 16),
              TextField(controller: assistantTeacherController, decoration: const InputDecoration(labelText: 'Assistant Teacher')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  final success = await Provider.of<ClassRepository>(context, listen: false).updateClass(
                    currentClass.copyWith(
                      classTeacher: mainTeacherController.text,
                      assistantTeacher: assistantTeacherController.text,
                    ),
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update teachers')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating teachers: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')),
                    );
                  }
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      mainTeacherController.dispose();
      assistantTeacherController.dispose();
    });
  }

  String _getFeeDisplay(SchoolClass currentClass) {
    final structure = _allFeeStructures.firstWhereOrNull((s) => s.classId == currentClass.id);
    final components = (structure != null && structure.components.isNotEmpty)
        ? structure.components
        : currentClass.feeStructure;

    if (components.isEmpty) return 'No fees configured';
    return components.map((e) => '${e.name}: ₹${e.amount.toInt()}').join('\n');
  }

  void _showFeeStructureDialog(SchoolClass currentClass) {
    final structure = _allFeeStructures.firstWhereOrNull((s) => s.classId == currentClass.id);

    // Default components if none found
    final List<FeeComponent> initialComponents = (structure != null && structure.components.isNotEmpty)
        ? structure.components.map((c) => c.copyWith()).toList()
        : (currentClass.feeStructure.isNotEmpty
            ? currentClass.feeStructure.map((c) => c.copyWith()).toList()
            : [
                FeeComponent(name: 'Monthly Tuition Fee', amount: 0, frequency: 'monthly'),
                FeeComponent(name: 'Annual Admission Fee', amount: 0, frequency: 'annually'),
                FeeComponent(name: 'Examination Fee', amount: 0, frequency: 'annually'),
              ]);

    final Map<String, TextEditingController> controllers = {};
    for (var component in initialComponents) {
      controllers[component.name] = TextEditingController(text: component.amount.toInt().toString());
    }
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Fee Structure - ${currentClass.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: initialComponents.map((component) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[component.name],
                  decoration: InputDecoration(labelText: component.name, prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  final feeRepo = Provider.of<FeeRepository>(context, listen: false);
                  final classRepo = Provider.of<ClassRepository>(context, listen: false);
                  final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

                  final session = await dashboardRepo.getCurrentSession();
                  if (session == null) throw Exception('No active session found');

                  final List<FeeComponent> newFees = initialComponents.map((component) {
                    final newAmount = double.tryParse(controllers[component.name]?.text ?? '0') ?? 0.0;
                    return component.copyWith(amount: newAmount);
                  }).toList();

                  // 1. Save to FeeStructure collection (Source of Truth)
                  final feeData = [{
                    'academicSessionId': session.id,
                    'classId': currentClass.id,
                    'components': newFees.map((c) => c.toJson()).toList(),
                  }];

                  final feeSuccess = await feeRepo.saveFeeStructure(feeData);

                  // 2. Update embedded class structure
                  final classSuccess = await classRepo.updateFeeStructure(currentClass.id!, newFees);

                  if ((feeSuccess || classSuccess) && mounted) {
                    // Refresh local structures
                    final updatedStructures = await feeRepo.getFeeStructures();
                    if (mounted) {
                      setState(() {
                        _allFeeStructures = updatedStructures.map((json) => FeeStructure.fromJson(json)).toList();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fee structure updated successfully'), backgroundColor: Colors.green),
                      );
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update fee structure')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating fee structure: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')),
                    );
                  }
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    ).then((_) {
      controllers.forEach((_, c) => c.dispose());
    });
  }

  bool _isTeacherBusy(List<SchoolClass> allClasses, String teacherName, int pIdx, int dIdx, String? excludeClassId) {
    for (final cls in allClasses) {
      if (cls.id == excludeClassId) continue;
      if (pIdx >= cls.timetable.length) continue;
      final entry = cls.timetable[pIdx][dIdx];
      if (entry?.teacherName == teacherName) return true;
    }
    return false;
  }

  void _showEditTimetableDialog(SchoolClass currentClass, int pIdx, int dIdx, TimetableEntry? entry) {
    String? selectedSubject = entry?.subject;
    String? selectedTeacher = entry?.teacherName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter teachers based on selected subject
          List<Teacher> subjectTeachers = [];
          if (selectedSubject != null) {
            subjectTeachers = _teachers.where((t) => t.subjects.contains(selectedSubject)).toList();
          }

          final List<Teacher> otherTeachers = _teachers.where((t) => !subjectTeachers.contains(t)).toList();

          return AlertDialog(
            title: Text('Edit Period ${pIdx + 1} - Day ${_days[dIdx]}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: (selectedSubject != null && (currentClass.subjects.contains(selectedSubject) || selectedSubject == 'LUNCH'))
                      ? selectedSubject : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'LUNCH', child: Text('LUNCH')),
                      ...currentClass.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      const DropdownMenuItem(value: 'ADD_NEW', child: Text('+ Add New Subject', style: TextStyle(color: AppColors.primary))),
                    ],
                    onChanged: isSaving ? null : (val) async {
                      if (val == 'ADD_NEW') {
                        final newSub = await _showAddNewSubjectDialog();
                        if (newSub != null && newSub.isNotEmpty) {
                          final success = await Provider.of<ClassRepository>(context, listen: false).addSubjectToClass(currentClass.id!, newSub);
                          if (success) {
                            setDialogState(() {
                              selectedSubject = newSub;
                              selectedTeacher = null; // Reset teacher when subject changes
                            });
                          }
                        }
                      } else {
                        setDialogState(() {
                          selectedSubject = val;
                          selectedTeacher = null; // Reset teacher when subject changes
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: (selectedTeacher != null && _teachers.any((t) => t.name == selectedTeacher)) ? selectedTeacher : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Select Teacher',
                    ),
                    items: [
                      if (subjectTeachers.isNotEmpty) ...[
                        const DropdownMenuItem(enabled: false, child: Text('Subject Teachers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        ...subjectTeachers.map((t) => DropdownMenuItem(value: t.name, child: Text(t.name))),
                      ],
                      if (otherTeachers.isNotEmpty) ...[
                        const DropdownMenuItem(enabled: false, child: Text('Other Teachers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        ...otherTeachers.map((t) => DropdownMenuItem(value: t.name, child: Text(t.name))),
                      ],
                    ],
                    onChanged: isSaving ? null : (val) => setDialogState(() => selectedTeacher = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (selectedSubject == null) return;

                  final classRepo = Provider.of<ClassRepository>(context, listen: false);
                  if (selectedTeacher != null && selectedTeacher != 'N/A') {
                    if (_isTeacherBusy(classRepo.classes, selectedTeacher!, pIdx, dIdx, currentClass.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$selectedTeacher is already assigned to another class in this period')),
                      );
                      return;
                    }
                  }

                  setDialogState(() => isSaving = true);
                  try {
                    final newEntry = TimetableEntry(
                      subject: selectedSubject!,
                      teacherName: selectedTeacher ?? 'N/A',
                    );
                    final success = await classRepo.updateTimetableEntry(
                      currentClass.id!, pIdx, dIdx, newEntry
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update timetable')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error updating timetable: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')),
                      );
                    }
                  } finally {
                    if (mounted) setDialogState(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<String?> _showAddNewSubjectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showSubjectsDialog(SchoolClass currentClass) {
    final controller = TextEditingController();
    List<String> tempSubjects = List.from(currentClass.subjects);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Manage Subjects - ${currentClass.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: !isSaving,
                        decoration: const InputDecoration(hintText: 'Add new subject...'),
                        onSubmitted: (val) {
                          if (val.isNotEmpty && !tempSubjects.contains(val)) {
                            setDialogState(() {
                              tempSubjects.add(val);
                              controller.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed: isSaving ? null : () {
                        if (controller.text.isNotEmpty && !tempSubjects.contains(controller.text)) {
                          setDialogState(() {
                            tempSubjects.add(controller.text);
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tempSubjects.map((s) => Chip(
                    label: Text(s),
                    onDeleted: isSaving ? null : () => setDialogState(() => tempSubjects.remove(s)),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  final success = await Provider.of<ClassRepository>(context, listen: false).updateClassSubjects(
                    currentClass.id!, tempSubjects
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update subjects')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating subjects: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${_getHumanReadableError(e)}')),
                    );
                  }
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      controller.dispose();
    });
  }
}
