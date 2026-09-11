import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
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
  List<Map<String, dynamic>> _tempDatesheet = [];
  bool _isEditingDatesheet = false;
  String? _currentSessionName;
  String? _errorMessage;

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
        _currentSessionName = session.sessionName;
        final examsRes = await examRepo.getExams(session.id!);
        final classes = await classRepo.getClasses();
        setState(() {
          _exams = examsRes['data'] ?? [];
          _classes = classes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading exam data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getHumanReadableError(e);
        });
      }
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
                : _errorMessage != null
                    ? ErrorView(
                        message: _errorMessage!,
                        onRetry: _loadInitialData,
                      )
                    : _selectedExam == null
                        ? _buildExamsList()
                        : _buildDatesheetView(),
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
              _selectedExam == null
                  ? 'Manage exam schedules'
                  : 'Datesheet for ${_selectedClass?['name'] ?? "Select Class"}',
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
                onPressed: () => setState(() {
                  _selectedExam = null;
                  _selectedClass = null;
                  _isEditingDatesheet = false;
                }),
                child: const Text('Back to Exams'),
              ),
              const SizedBox(width: 12),
              if (_isEditingDatesheet)
                ElevatedButton.icon(
                  onPressed: _saveDatesheet,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Datesheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditingDatesheet = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Datesheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedClass?['_id'],
                decoration: const InputDecoration(
                  labelText: 'Select Class',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _classes.map<DropdownMenuItem<String>>((c) {
                  final section = c['section'];
                  final sectionSuffix = (section != null &&
                          section.toString().toLowerCase() != 'null' &&
                          section.toString().isNotEmpty)
                      ? ' - $section'
                      : '';
                  return DropdownMenuItem<String>(
                    value: c['_id']?.toString(),
                    child: Text('${c['name']}$sectionSuffix'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = _classes.firstWhere((c) => c['_id'] == val);
                    _isEditingDatesheet = false;
                  });
                  _loadDatesheetForClass();
                },
              ),
            ),
            if (_selectedClass != null) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _downloadDatesheet,
                icon: const Icon(Icons.download),
                label: const Text('Class PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _downloadAllDatesheets,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('All Classes'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ],
          ],
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
                  icon: const Icon(Icons.calendar_today, color: Colors.orange),
                  onPressed: () {
                    setState(() {
                      _selectedExam = exam;
                    });
                  },
                  tooltip: 'View Datesheet',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteExam(exam),
                  tooltip: 'Delete Exam',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteExam(dynamic exam) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam['name']}"? This will remove the exam and its datesheet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final examRepo = Provider.of<ExamRepository>(context, listen: false);
              final examId = exam['_id'] ?? exam['id'];

              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                final res = await examRepo.deleteExam(examId);
                if (!mounted) return;

                if (res['success'] == true || (res['success'] == null && res['error'] == null)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Exam deleted successfully')),
                  );
                  _loadInitialData();
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(res['message'] ?? res['error'] ?? 'Failed to delete exam')),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting exam: $e');
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String? _checkCollision() {
    try {
      final timeFormat = DateFormat('h:mm a');
      for (int i = 0; i < _tempDatesheet.length; i++) {
        final item1 = _tempDatesheet[i];
        if (item1['date'] == null || item1['startTime'] == null) continue;

        final date1 = DateTime.parse(item1['date']);
        final start1Time = timeFormat.parse(item1['startTime']);
        final start1 = DateTime(date1.year, date1.month, date1.day, start1Time.hour, start1Time.minute);
        final duration1 = (item1['durationHours'] as num).toDouble();
        final end1 = start1.add(Duration(minutes: (duration1 * 60).toInt()));

        for (int j = i + 1; j < _tempDatesheet.length; j++) {
          final item2 = _tempDatesheet[j];
          if (item2['date'] == null || item2['startTime'] == null) continue;

          final date2 = DateTime.parse(item2['date']);
          if (date1.year == date2.year && date1.month == date2.month && date1.day == date2.day) {
            final start2Time = timeFormat.parse(item2['startTime']);
            final start2 = DateTime(date2.year, date2.month, date2.day, start2Time.hour, start2Time.minute);
            final duration2 = (item2['durationHours'] as num).toDouble();
            final end2 = start2.add(Duration(minutes: (duration2 * 60).toInt()));

            if (start1.isBefore(end2) && start2.isBefore(end1)) {
              return '${item2['subject']} (${item2['startTime']}) overlaps with ${item1['subject']} (${item1['startTime']}–${timeFormat.format(end1)}) on ${DateFormat('dd/MM/yyyy').format(date1)}.';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Validation error: $e');
    }
    return null;
  }

  Future<void> _saveDatesheet() async {
    // Validation
    for (var item in _tempDatesheet) {
      if (item['date'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date for ${item['subject']}')),
        );
        return;
      }
    }

    // Time collision validation (intra-class)
    final collisionError = _checkCollision();
    if (collisionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(collisionError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final examRepo = Provider.of<ExamRepository>(context, listen: false);

      // Merge temp datesheet back into the main exam datesheet
      List<dynamic> fullDatesheet = List.from(_selectedExam['datesheet'] ?? []);

      for (var newItem in _tempDatesheet) {
        int existingIdx = fullDatesheet.indexWhere(
          (item) => item['classId'] == newItem['classId'] && item['subject'] == newItem['subject'],
        );

        if (existingIdx != -1) {
          fullDatesheet[existingIdx] = newItem;
        } else {
          fullDatesheet.add(newItem);
        }
      }

      final res = await examRepo.updateExam(_selectedExam['_id'], {
        'datesheet': fullDatesheet,
      });

      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datesheet saved successfully!')));
          setState(() {
            _selectedExam = res['data'];
            _isEditingDatesheet = false;
          });
          _loadInitialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to save datesheet')));
        }
      }
    } catch (e) {
      debugPrint('Error saving datesheet: $e');
      if (mounted) {
        String errorMsg = 'An unexpected error occurred while saving datesheet.';
        if (e.toString().contains('SocketException') || e.toString().contains('Connection failed')) {
          errorMsg = 'No internet connection. Please check your network and try again.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = 'The connection timed out. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateExamDialog() {
    final nameController = TextEditingController();
    String selectedType = 'Mid Term';
    List<String> selectedClassIds = [];
    int currentStep = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(currentStep == 0 ? 'Create New Exam' : 'Select Classes'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: currentStep == 0
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Exam Name',
                            hintText: 'e.g., Half Yearly Examination 2024',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          items: ['Monthly Test', 'Mid Term', 'Half Yearly', 'Annual', 'Periodic Test', 'Final']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedType = val!),
                          decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose classes participating in this exam:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._classes.map((c) => CheckboxListTile(
                              title: Text('${c['name']} - ${c['section']}'),
                              value: selectedClassIds.contains(c['_id']),
                              dense: true,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val!) {
                                    selectedClassIds.add(c['_id']);
                                  } else {
                                    selectedClassIds.remove(c['_id']);
                                  }
                                });
                              },
                            )),
                      ],
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (currentStep == 1) {
                  setDialogState(() => currentStep = 0);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(currentStep == 1 ? 'Back' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentStep == 0) {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter exam name')));
                    return;
                  }
                  setDialogState(() => currentStep = 1);
                } else {
                  if (selectedClassIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one class')));
                    return;
                  }

                  final dashRepo = Provider.of<DashboardRepository>(context, listen: false);
                  final examRepo = Provider.of<ExamRepository>(context, listen: false);
                  final session = await dashRepo.getCurrentSession();

                  if (session != null) {
                    setState(() => _isLoading = true);
                    final res = await examRepo.createExam({
                      'name': nameController.text.trim(),
                      'type': selectedType,
                      'session': session.id,
                      'startDate': DateTime.now().toIso8601String(),
                      'classes': selectedClassIds,
                      'datesheet': [],
                      'status': 'Scheduled',
                    });

                    if (mounted) {
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                      if (res['success']) {
                        setState(() {
                          _selectedExam = res['data'];
                          _selectedClass = _classes.firstWhere((c) => c['_id'] == selectedClassIds.first);
                          _isEditingDatesheet = true;
                        });
                        _loadDatesheetForClass();
                        _loadInitialData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to create exam')));
                      }
                    }
                  }
                }
              },
              child: Text(currentStep == 0 ? 'Next' : 'Create & Build Datesheet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDatesheetForClass() async {
    if (_selectedClass == null || _selectedExam == null) return;

    final List<dynamic> fullDatesheet = _selectedExam['datesheet'] ?? [];
    final classSubjects = List<String>.from(_selectedClass['subjects'] ?? []);

    if (classSubjects.isEmpty) {
      debugPrint('No subjects found for class ${_selectedClass['name']}');
      setState(() {
        _tempDatesheet = [];
      });
      return;
    }

    setState(() {
      _tempDatesheet = [];
      for (var subject in classSubjects) {
        final existingEntry = fullDatesheet.firstWhere(
          (item) => item['classId'] == _selectedClass['_id'] && item['subject'] == subject,
          orElse: () => null,
        );

        if (existingEntry != null) {
          _tempDatesheet.add(Map<String, dynamic>.from(existingEntry));
        } else {
          _tempDatesheet.add({
            'classId': _selectedClass['_id'],
            'subject': subject,
            'date': null,
            'startTime': '09:00 AM',
            'durationHours': 3.0,
            'maxMarks': 100,
          });
        }
      }
    });
  }

  Widget _buildDatesheetView() {
    if (_selectedClass == null) {
      return const Center(child: Text('Select a class to view/edit datesheet.'));
    }

    if (_tempDatesheet.isEmpty) {
      return const Center(child: Text('No subjects defined for this class. Please add subjects to the class first.'));
    }

    final collisionError = _checkCollision();

    return Column(
      children: [
        if (collisionError != null && _isEditingDatesheet)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    collisionError,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Start Time')),
                DataColumn(label: Text('Duration (Hrs)')),
                DataColumn(label: Text('Max Marks')),
              ],
              rows: _tempDatesheet.asMap().entries.map((entry) {
                int idx = entry.key;
                var item = entry.value;
                return DataRow(
                  cells: [
                    DataCell(Text(item['subject'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      _isEditingDatesheet
                          ? InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: item['date'] != null ? DateTime.parse(item['date']) : DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() => _tempDatesheet[idx]['date'] = date.toIso8601String());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['date'])) : 'Select Date',
                                  style: TextStyle(color: item['date'] != null ? Colors.black : Colors.blue),
                                ),
                              ),
                            )
                          : Text(item['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['date'])) : '-'),
                    ),
                    DataCell(
                      _isEditingDatesheet
                          ? InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() => _tempDatesheet[idx]['startTime'] = time.format(context));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['startTime'] ?? 'Select Time',
                                  style: TextStyle(color: item['startTime'] != null ? Colors.black : Colors.blue),
                                ),
                              ),
                            )
                          : Text(item['startTime'] ?? '-'),
                    ),
                    DataCell(
                      _isEditingDatesheet
                          ? DropdownButton<double>(
                              value: (item['durationHours'] as num).toDouble(),
                              items: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]
                                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                                  .toList(),
                              onChanged: (val) => setState(() => _tempDatesheet[idx]['durationHours'] = val),
                            )
                          : Text('${item['durationHours']}'),
                    ),
                    DataCell(
                      _isEditingDatesheet
                          ? SizedBox(
                              width: 60,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true),
                                controller: TextEditingController(text: item['maxMarks']?.toString() ?? '100'),
                                onChanged: (val) => _tempDatesheet[idx]['maxMarks'] = int.tryParse(val) ?? 100,
                              ),
                            )
                          : Text('${item['maxMarks']}'),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadDatesheet() async {
    if (_selectedExam == null || _selectedClass == null) return;

    setState(() => _isLoading = true);
    try {
      final examRepo = Provider.of<ExamRepository>(context, listen: false);
      final res = await examRepo.getExams(_selectedExam['session']);

      if (res['success']) {
        final exam = (res['data'] as List).firstWhere((e) => e['_id'] == _selectedExam['_id']);
        final List<dynamic> fullDatesheet = exam['datesheet'] ?? [];
        final classDatesheet = fullDatesheet.where((d) => d['classId'] == _selectedClass['_id']).toList();

        await PdfGenerator.downloadExamDatesheet(
          exam: exam,
          datesheet: classDatesheet,
          className: _selectedClass['section'] != null
              ? '${_selectedClass['name']} - ${_selectedClass['section']}'
              : _selectedClass['name'],
          sessionName: _currentSessionName,
        );
      }
    } catch (e) {
      debugPrint('Error downloading datesheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: ${_getHumanReadableError(e)}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadAllDatesheets() async {
    if (_selectedExam == null) return;

    setState(() => _isLoading = true);
    try {
      final examRepo = Provider.of<ExamRepository>(context, listen: false);
      final res = await examRepo.getExams(_selectedExam['session']);

      if (res['success']) {
        final exam = (res['data'] as List).firstWhere((e) => e['_id'] == _selectedExam['_id']);
        final List<dynamic> fullDatesheet = exam['datesheet'] ?? [];

        final examClassIds = List<String>.from(exam['classes'] ?? []);
        final examClasses = _classes.where((c) => examClassIds.contains(c['_id'])).toList();

        await PdfGenerator.downloadAllClassesDatesheet(
          exam: exam,
          fullDatesheet: fullDatesheet,
          classes: examClasses,
          sessionName: _currentSessionName,
        );
      }
    } catch (e) {
      debugPrint('Error downloading all datesheets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: ${_getHumanReadableError(e)}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getHumanReadableError(dynamic e) {
    if (e.toString().contains('SocketException') || e.toString().contains('Connection failed')) {
      return 'No internet connection. Please connect to the internet and try again.';
    } else if (e.toString().contains('TimeoutException')) {
      return 'The connection timed out. Please try again later.';
    }
    return 'An unexpected error occurred: $e';
  }

}
