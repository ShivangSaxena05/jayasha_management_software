import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/attendance/data/repositories/attendance_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  dynamic _selectedClass;
  List<dynamic> _classes = [];
  List<StudentAdmission> _students = [];
  List<StudentAdmission> _searchResults = [];
  List<dynamic> _recentUpdates = [];
  Map<String, String> _attendanceStatus = {}; // studentId -> status
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final classes = await classRepo.getClasses();
      setState(() {
        _classes = classes;
      });
      await _fetchRecentUpdates();
    } catch (e) {
      _showError('Failed to load initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentUpdates() async {
    // In a real app, this would be a specific API call.
    // For now, we'll mock or leave empty if no class is selected.
    setState(() => _recentUpdates = []);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      // Assuming getStudents can take a search query or we filter locally
      final allStudents = await studentRepo.getStudents();
      final results = allStudents.where((s) =>
        s.name.toLowerCase().contains(query.toLowerCase()) ||
        s.admissionNumber.toLowerCase().contains(query.toLowerCase()) ||
        (s.rollNumber != null && s.rollNumber!.toLowerCase().contains(query.toLowerCase()))
      ).toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      _showError('Search failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null) return;
    setState(() {
      _isLoading = true;
      _searchController.clear();
      _searchResults = [];
    });
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final students = await studentRepo.getStudents();
      final classStudents = students.where((s) =>
        s.currentClassId == _selectedClass['_id'] ||
        s.currentClassId == (_selectedClass['_id'] is String ? _selectedClass['_id'] : _selectedClass['_id'].toString())
      ).toList();

      final attResponse = await attRepo.getAttendanceByClass(_selectedClass['_id'], dateStr);

      final Map<String, String> existingAtt = {};
      if (attResponse['success'] == true && attResponse['data'] != null) {
        for (var record in attResponse['data']) {
          final sId = record['student'] is Map ? record['student']['_id'] : record['student'];
          existingAtt[sId.toString()] = record['status'];
        }
      }

      setState(() {
        _students = classStudents;
        _attendanceStatus = { for (var s in classStudents) s.id! : existingAtt[s.id!] ?? 'Present' };
      });
    } catch (e) {
      _showError('Error loading class attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _students.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);
      final dashRepo = Provider.of<DashboardRepository>(context, listen: false);
      final session = await dashRepo.getCurrentSession();

      if (session == null) {
        _showError('Active academic session not found. Please setup session first.');
        return;
      }

      final records = _attendanceStatus.entries.map((e) => {
        'studentId': e.key,
        'classId': _selectedClass['_id'],
        'status': e.value,
        'remarks': ''
      }).toList();

      final response = await attRepo.markAttendance(
        attendanceRecords: records,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        sessionId: session.id!,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showError(response['message'] ?? 'Failed to save attendance');
      }
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showStudentAttendanceCalendar(StudentAdmission student) async {
    setState(() => _isLoading = true);
    try {
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      final endDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));

      final result = await attRepo.getStudentAttendanceReport(
        studentId: student.id!,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => StudentAttendanceDialog(
            student: student,
            reportData: result['data'],
          ),
        );
      } else {
        _showError(result['message'] ?? 'Could not fetch attendance report');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
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
          const SizedBox(height: 20),
          _buildTopActions(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMainContent(),
          ),
          if (_selectedClass != null && _students.isNotEmpty && _searchController.text.isEmpty) _buildFooter(),
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
            const Text(
              'Attendance',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
            ),
            Text(
              _selectedClass != null
                ? 'Managing attendance for ${_selectedClass['name']} - ${_selectedClass['section']}'
                : 'Search student or select a class to begin',
              style: const TextStyle(color: AppColors.textSecondary)
            ),
          ],
        ),
        if (_selectedClass != null && _searchController.text.isEmpty)
          ElevatedButton.icon(
            onPressed: _students.isEmpty || _isSaving ? null : _saveAttendance,
            icon: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
            label: const Text('Update Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  Widget _buildTopActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Class Picker
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<dynamic>(
              value: _selectedClass,
              decoration: InputDecoration(
                hintText: 'Select Class',
                prefixIcon: const Icon(Icons.class_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text('${c['name']} - ${c['section']}'))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClass = val;
                });
                _loadStudents();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Date Picker
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  if (_selectedClass != null) _loadStudents();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM, yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search Bar
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search Name / Roll / Adm No...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    })
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_selectedClass == null) {
      return _buildRecentUpdatesSection();
    }

    if (_students.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAttendanceList();
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No students found matching "${_searchController.text}"', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final student = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(student.name[0], style: const TextStyle(color: AppColors.primary)),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Class: ${student.className ?? 'N/A'} | Adm: ${student.admissionNumber}'),
            trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
            onTap: () => _showStudentAttendanceCalendar(student),
          ),
        );
      },
    );
  }

  Widget _buildRecentUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Recent Attendance Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: _recentUpdates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    const Text('Select a class to mark today\'s attendance', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _recentUpdates.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Class ${index + 1} marked'),
                  subtitle: const Text('Today at 10:00 AM'),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _students.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = _students[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text(student.rollNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _showStudentAttendanceCalendar(student),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text('Adm: ${student.admissionNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusButton(student.id!, 'Present', Colors.green),
                            const SizedBox(width: 8),
                            _buildStatusButton(student.id!, 'Absent', Colors.red),
                            const SizedBox(width: 8),
                            _buildStatusButton(student.id!, 'Late', Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String studentId, String status, Color color) {
    final isSelected = _attendanceStatus[studentId] == status;
    return InkWell(
      onTap: () => setState(() => _attendanceStatus[studentId] = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No students found in this class.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    int present = _attendanceStatus.values.where((s) => s == 'Present').length;
    int absent = _attendanceStatus.values.where((s) => s == 'Absent').length;
    int late = _attendanceStatus.values.where((s) => s == 'Late').length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _statChip('Present: $present', Colors.green),
          const SizedBox(width: 12),
          _statChip('Absent: $absent', Colors.red),
          const SizedBox(width: 12),
          _statChip('Late: $late', Colors.orange),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class StudentAttendanceDialog extends StatelessWidget {
  final StudentAdmission student;
  final Map<String, dynamic> reportData;

  const StudentAttendanceDialog({
    super.key,
    required this.student,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final records = reportData['records'] as List? ?? [];
    final stats = reportData['stats'] ?? {};

    // Map dates to status for the calendar
    final Map<int, String> statusMap = {};
    for (var record in records) {
      final date = DateTime.parse(record['date']);
      statusMap[date.day] = record['status'];
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfWeek = DateTime(now.year, now.month, 1).weekday;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Attendance: ${DateFormat('MMMM yyyy').format(now)}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatsSummary(stats),
            const SizedBox(height: 20),
            _buildCalendarGrid(daysInMonth, firstDayOfWeek, statusMap),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('P', stats['Present']?.toString() ?? '0', Colors.green),
        _statItem('A', stats['Absent']?.toString() ?? '0', Colors.red),
        _statItem('L', stats['Late']?.toString() ?? '0', Colors.orange),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCalendarGrid(int days, int firstDay, Map<int, String> statusMap) {
    final List<Widget> dayWidgets = [];

    // Days of week header
    const daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var d in daysOfWeek) {
      dayWidgets.add(Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))));
    }

    // Empty spaces before first day
    for (int i = 1; i < firstDay; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Days
    for (int i = 1; i <= days; i++) {
      final status = statusMap[i];
      Color bgColor = Colors.transparent;
      Color textColor = AppColors.textPrimary;

      if (status == 'Present') bgColor = Colors.green;
      else if (status == 'Absent') bgColor = Colors.red;
      else if (status == 'Late') bgColor = Colors.orange;

      if (bgColor != Colors.transparent) textColor = Colors.white;

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: bgColor == Colors.transparent ? Border.all(color: Colors.grey.shade100) : null,
          ),
          child: Center(
            child: Text(
              i.toString(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Present', Colors.green),
        const SizedBox(width: 12),
        _legendItem('Absent', Colors.red),
        const SizedBox(width: 12),
        _legendItem('Late', Colors.orange),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
