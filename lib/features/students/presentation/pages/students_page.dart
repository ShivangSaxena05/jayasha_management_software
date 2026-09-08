import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/students/presentation/pages/student_detail_page.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'dart:async';
import 'dart:io';

class StudentsPage extends StatefulWidget {
  final VoidCallback? onRegisterNewStudent;
  const StudentsPage({super.key, this.onRegisterNewStudent});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassId;
  String _selectedClassName = 'All';
  bool _isLoading = false;
  String? _errorMessage;
  List<StudentAdmission> _students = [];
  List<SchoolClass> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

      final session = await dashboardRepo.getCurrentSession();
      if (session != null && session.id != null) {
        await classRepo.fetchClasses(session.id!);
      }

      final students = await studentRepo.getStudents(
        classId: _selectedClassId,
      );

      if (mounted) {
        setState(() {
          _students = students;
          _classes = classRepo.classes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = Provider.of<StudentRepository>(context, listen: false);
      final students = await repo.getStudents(
        classId: _selectedClassId,
      );
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getHumanReadableError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _fetchData,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Student Directory',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage and view all students in the academy',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onRegisterNewStudent,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Register New Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by Name or Admission No...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_selectedClassName != 'All')
                  Chip(
                    label: Text('Class: $_selectedClassName'),
                    onDeleted: () {
                      setState(() {
                        _selectedClassId = null;
                        _selectedClassName = 'All';
                      });
                      _fetchStudents();
                    },
                    backgroundColor: AppColors.primary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Classes Grid
            const Text(
              'Select Class',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _classes.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final bool isAll = index == 0;
                  final className = isAll ? 'All' : _classes[index - 1].name;
                  final classId = isAll ? null : _classes[index - 1].id;
                  final isSelected = _selectedClassName == className;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedClassName = className;
                        _selectedClassId = classId;
                      });
                      _fetchStudents();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        className,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Student Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: _isLoading
                ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Student List - $_selectedClassName',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Showing ${_getFilteredStudents().length} students',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (_getFilteredStudents().isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No students found')),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('Admission No')),
                                DataColumn(label: Text('Student Name')),
                                DataColumn(label: Text('Class')),
                                DataColumn(label: Text('Section')),
                                DataColumn(label: Text('Father Name')),
                                DataColumn(label: Text('Contact')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _getFilteredStudents().map<DataRow>((student) {
                                return DataRow(cells: [
                                  DataCell(Text(student.admissionNumber)),
                                  DataCell(Text(student.name)),
                                  DataCell(Text(student.className ?? 'N/A')),
                                  DataCell(Text(student.section ?? 'N/A')),
                                  DataCell(Text(student.fatherName)),
                                  DataCell(Text(student.guardianPhone)),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                                        onPressed: () {
                                           Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => StudentDetailPage(student: student),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StudentAdmission> _getFilteredStudents() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _students;
    return _students.where((s) =>
      s.name.toLowerCase().contains(query) ||
      s.admissionNumber.toLowerCase().contains(query)
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
