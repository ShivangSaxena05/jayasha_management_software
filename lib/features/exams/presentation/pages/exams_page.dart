import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  bool _isLoading = false;
  List<dynamic> _exams = [];
  List<dynamic> _classes = [];
  dynamic _selectedExam;
  dynamic _selectedClass;
  List<StudentAdmission> _students = [];
  Map<String, List<Map<String, dynamic>>> _marksEntry = {}; // studentId -> list of subject marks

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final dashRepo = Provider.of<DashboardRepository>(context, listen: false);
      final examRepo = Provider.of<ExamRepository>(context, listen: false);
      final classRepo = Provider.of<ClassRepository>(context, listen: false);

      final session = await dashRepo.getCurrentSession();
      if (session != null) {
        final examsRes = await examRepo.getExams(session.id!);
        final classes = await classRepo.getClasses();
        setState(() {
          _exams = examsRes['data'] ?? [];
          _classes = classes;
        });
      }
    } catch (e) {
      debugPrint('Error loading exam data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForMarks() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final allStudents = await studentRepo.getStudents();
      final classStudents = allStudents.where((s) => s.currentClassId == _selectedClass['_id']).toList();

      setState(() {
        _students = classStudents;
        // Initialize marks entry with default subjects (can be dynamic later)
        _marksEntry = {
          for (var s in classStudents)
            s.id!: [
              {'subject': 'English', 'theoryMarks': 0, 'maxMarks': 100},
              {'subject': 'Hindi', 'theoryMarks': 0, 'maxMarks': 100},
              {'subject': 'Mathematics', 'theoryMarks': 0, 'maxMarks': 100},
              {'subject': 'Science', 'theoryMarks': 0, 'maxMarks': 100},
              {'subject': 'Social Science', 'theoryMarks': 0, 'maxMarks': 100},
            ]
        };
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSelectors(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedExam == null
                    ? _buildExamsList()
                    : _buildMarksEntryTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedExam == null ? 'Examinations' : 'Marks Entry: ${_selectedExam['name']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedExam == null
                  ? 'Manage exam schedules and result declaration'
                  : 'Entering marks for ${_selectedClass?['name'] ?? "Selected Class"}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        if (_selectedExam == null)
          ElevatedButton.icon(
            onPressed: () => _showCreateExamDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          )
        else
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _selectedExam = null),
                child: const Text('Back to Exams'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saveMarks,
                icon: const Icon(Icons.save),
                label: const Text('Save Marks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectors() {
    if (_selectedExam == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<dynamic>(
            value: _selectedClass,
            decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
            items: _classes
                .map((c) => DropdownMenuItem(value: c, child: Text('${c['name']} - ${c['section']}')))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedClass = val);
              _loadStudentsForMarks();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamsList() {
    if (_exams.isEmpty) {
      return const Center(child: Text('No exams scheduled yet.'));
    }

    return ListView.builder(
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(exam['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Type: ${exam['type']} | Status: ${exam['status']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppColors.primary),
                  onPressed: () => setState(() => _selectedExam = exam),
                  tooltip: 'Enter Marks',
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.blue),
                  onPressed: () => _showPrintReportCardsDialog(exam),
                  tooltip: 'Print Report Cards',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarksEntryTable() {
    if (_students.isEmpty) {
      return const Center(child: Text('Select a class to enter marks.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Roll')),
            const DataColumn(label: Text('Student Name')),
            ...(_marksEntry[_students.first.id] ?? []).map((s) => DataColumn(label: Text(s['subject']))),
          ],
          rows: _students.map((student) {
            final marks = _marksEntry[student.id]!;
            return DataRow(
              cells: [
                DataCell(Text(student.rollNumber ?? '-')),
                DataCell(Text(student.name)),
                ...marks.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return DataCell(
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true),
                        onChanged: (val) {
                          marks[idx]['theoryMarks'] = int.tryParse(val) ?? 0;
                          marks[idx]['totalMarks'] = marks[idx]['theoryMarks'];
                        },
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCreateExamDialog() {
    final nameController = TextEditingController();
    String selectedType = 'Monthly Test';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Exam Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['Periodic Test', 'Half Yearly', 'Annual', 'Monthly Test']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dashRepo = Provider.of<DashboardRepository>(context, listen: false);
              final examRepo = Provider.of<ExamRepository>(context, listen: false);
              final session = await dashRepo.getCurrentSession();

              if (session != null && nameController.text.isNotEmpty) {
                await examRepo.createExam({
                  'name': nameController.text,
                  'type': selectedType,
                  'session': session.id,
                  'startDate': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                _loadInitialData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPrintReportCardsDialog(dynamic exam) {
    dynamic selectedClassForPrint;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Print Report Cards: ${exam['name']}'),
          content: DropdownButtonFormField<dynamic>(
            value: selectedClassForPrint,
            decoration: const InputDecoration(labelText: 'Select Class'),
            items: _classes
                .map((c) => DropdownMenuItem(value: c, child: Text('${c['name']} - ${c['section']}')))
                .toList(),
            onChanged: (val) => setDialogState(() => selectedClassForPrint = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedClassForPrint == null
                  ? null
                  : () async {
                      final examRepo = Provider.of<ExamRepository>(context, listen: false);
                      final res = await examRepo.getMarks(exam['_id'], selectedClassForPrint['_id']);
                      if (res['success'] && res['data'] != null) {
                        for (var markRecord in res['data']) {
                          await PdfGenerator.generateReportCard(markRecord: markRecord);
                        }
                      }
                      Navigator.pop(context);
                    },
              child: const Text('Print All'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMarks() async {
    setState(() => _isLoading = true);
    try {
      final examRepo = Provider.of<ExamRepository>(context, listen: false);
      final List<Map<String, dynamic>> marksData = _marksEntry.entries.map((e) => {
        'studentId': e.key,
        'subjectMarks': e.value,
      }).toList();

      final res = await examRepo.submitMarks(
        examId: _selectedExam['_id'],
        classId: _selectedClass['_id'],
        marksData: marksData,
      );

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved successfully!')));
        setState(() => _selectedExam = null);
        _loadInitialData();
      }
    } catch (e) {
      debugPrint('Error saving marks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
