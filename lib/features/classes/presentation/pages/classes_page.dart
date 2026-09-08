import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';

import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'dart:async';
import 'dart:io';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  String? _selectedClassName;
  bool _isInit = true;
  String? _errorMessage;

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

      final session = await dashboardRepo.getCurrentSession();
      if (session != null && session.id != null) {
        await classRepo.fetchClasses(session.id!);
        if (classRepo.classes.isNotEmpty && mounted) {
          setState(() {
            _selectedClassName = classRepo.classes.first.name;
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
    final classes = classRepo.classNames;

    if (_selectedClassName == null && classes.isNotEmpty) {
      _selectedClassName = classes.first;
    }

    final currentClass = classRepo.getClass(_selectedClassName ?? '');

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
                      final className = classes[index];
                      final isSelected = _selectedClassName == className;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => setState(() => _selectedClassName = className),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.1),
                          selectedColor: AppColors.primary,
                          leading: Icon(
                            Icons.class_outlined,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(
                            className,
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
                          const Text('Manage timetable, teachers, and fee structure'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Management Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.8,
                    children: [
                      _buildManagementCard(
                        'Class Teacher',
                        Icons.person_pin_rounded,
                        'Main: ${currentClass.classTeacher}\nAssistant: ${currentClass.assistantTeacher ?? "None"}',
                        Colors.blue,
                        () => _showTeachersDialog(currentClass),
                      ),
                      _buildManagementCard(
                        'Fee Structure',
                        Icons.payments_rounded,
                        currentClass.feeStructure.entries.map((e) => '${e.key}: ₹${e.value.toInt()}').join('\n'),
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
                              const Text('Click cell to edit', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                                const TableRow(
                                  children: [
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Mon', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Tue', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Wed', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Thu', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Fri', style: TextStyle(fontWeight: FontWeight.bold))))),
                                    TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Sat', style: TextStyle(fontWeight: FontWeight.bold))))),
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
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              IconButton(onPressed: onTap, icon: const Icon(Icons.edit_outlined, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddClassDialog() {
    final nameController = TextEditingController();
    final sectionsController = TextEditingController(text: 'A');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              try {
                final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
                final classRepo = Provider.of<ClassRepository>(context, listen: false);
                final session = await dashboardRepo.getCurrentSession();

                if (session?.id != null) {
                  final sections = sectionsController.text.split(',').map((e) => e.trim()).toList();
                  final success = await classRepo.addClass(session!.id!, nameController.text, sections);
                  if (success && mounted) {
                    Navigator.pop(context);
                    setState(() => _selectedClassName = nameController.text);
                  }
                }
              } catch (e) {
                debugPrint('Error adding class: $e');
              }
            },
            child: const Text('Add Class'),
          ),
        ],
      ),
    );
  }

  void _showTeachersDialog(SchoolClass currentClass) {
    final mainTeacherController = TextEditingController(text: currentClass.classTeacher);
    final assistantTeacherController = TextEditingController(text: currentClass.assistantTeacher ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<ClassRepository>(context, listen: false).updateClass(
                  currentClass.copyWith(
                    classTeacher: mainTeacherController.text,
                    assistantTeacher: assistantTeacherController.text,
                  ),
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                debugPrint('Error updating teachers: $e');
              }
            },
            child: const Text('Save')
          ),
        ],
      ),
    );
  }

  void _showFeeStructureDialog(SchoolClass currentClass) {
    final Map<String, TextEditingController> controllers = {};
    currentClass.feeStructure.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toInt().toString());
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fee Structure - ${currentClass.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: e.value,
              decoration: InputDecoration(labelText: e.key, prefixText: '₹ '),
              keyboardType: TextInputType.number,
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              try {
                final Map<String, double> newFees = {};
                controllers.forEach((key, controller) {
                  newFees[key] = double.tryParse(controller.text) ?? 0.0;
                });
                Provider.of<ClassRepository>(context, listen: false).updateFeeStructure(currentClass.name, newFees);
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error updating fee structure: $e');
              }
            },
            child: const Text('Update')
          ),
        ],
      ),
    );
  }

  void _showEditTimetableDialog(SchoolClass currentClass, int pIdx, int dIdx, TimetableEntry? entry) {
    final subjectController = TextEditingController(text: entry?.subject ?? '');
    final teacherController = TextEditingController(text: entry?.teacherName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Period ${pIdx + 1} - Day ${dIdx + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 16),
            TextField(controller: teacherController, decoration: const InputDecoration(labelText: 'Teacher')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              try {
                final newEntry = TimetableEntry(
                  subject: subjectController.text,
                  teacherName: teacherController.text,
                );
                Provider.of<ClassRepository>(context, listen: false).updateTimetableEntry(
                  currentClass.name, pIdx, dIdx, newEntry
                );
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error updating timetable: $e');
              }
            },
            child: const Text('Save')
          ),
        ],
      ),
    );
  }
}
