import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/models/salary_record.dart';
import 'package:jayasha_childrens_academy/core/models/leave_record.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/features/staff/presentation/pages/teacher_form_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/onboarding/principal_onboarding_page.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';

class StaffDetailPage extends StatefulWidget {
  final dynamic person;

  const StaffDetailPage({
    super.key,
    required this.person,
  });

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  List<SalaryRecord> _salaryRecords = [];
  List<LeaveRecord> _leaveRecords = [];
  bool _isLoadingRecords = false;
  late dynamic _person;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    if (_person is Teacher) {
      _fetchRecords();
    }
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoadingRecords = true);
    try {
      final repo = Provider.of<StaffRepository>(context, listen: false);
      final teacherId = (_person as Teacher).id!;
      final salaries = await repo.getSalaryRecords(teacherId);
      final leaves = await repo.getLeaveRecords(teacherId);
      setState(() {
        _salaryRecords = salaries;
        _leaveRecords = leaves;
        _isLoadingRecords = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecords = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final String name = person.name;
    final String role = person is Principal
        ? 'Principal'
        : (person as Teacher).isClassTeacher
            ? 'Class Teacher (${(person as Teacher).classTeacherOfClass})'
            : 'Teacher';
    final String email = person.email;
    final String phone = person.phone;
    final String address = person.address;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, name, role, email, phone, address),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      if (person is Teacher) ...[
                        _buildScheduleSection(),
                        const SizedBox(height: 24),
                        _buildHolidaySection(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                if (person is Teacher)
                  Expanded(
                    child: _buildSalarySection(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String role,
    String email,
    String phone,
    String address,
  ) {
    final person = _person;
    String? photoPath;
    if (person is Principal) {
      photoPath = (person as Principal).photoPath;
    } else if (person is Teacher) {
      photoPath = (person as Teacher).photoPath;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            backgroundImage: photoPath != null
                ? (photoPath.startsWith('http')
                    ? NetworkImage(photoPath)
                    : FileImage(File(photoPath)) as ImageProvider)
                : null,
            child: photoPath == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  role,
                  style:
                      const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.email_outlined, email),
                    _buildInfoChip(Icons.phone_outlined, '+91 $phone'),
                    _buildInfoChip(Icons.location_on_outlined, address),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (person is Teacher) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherFormPage(
                      teacher: person as Teacher,
                      onSave: () {
                        // Ideally, we'd want to refresh the detail page if data changed
                      },
                    ),
                  ),
                );
              } else if (person is Principal) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrincipalOnboardingPage(
                      existingPrincipal: person as Principal,
                      onSave: () {
                        // Refresh logic could be added here
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildInfoSection() {
    final person = _person;
    if (person is Teacher) {
      final teacher = person as Teacher;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Department', teacher.department),
            _buildDetailRow('Qualification', teacher.qualification),
            _buildDetailRow('Experience', teacher.experience),
            _buildDetailRow('Date of Joining', teacher.dateOfJoining),
            const SizedBox(height: 20),
            const Text('Assigned Subjects',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: teacher.subjects
                  .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('Classes Taught',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: teacher.classesTeaching
                  .map((c) => Chip(
                        label: Text('Class $c'),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        labelStyle: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text('Identity Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (teacher.aadhaarFrontPath != null)
                  Expanded(
                    child: _buildDocumentPreview('Aadhaar Front', teacher.aadhaarFrontPath!),
                  ),
                const SizedBox(width: 16),
                if (teacher.aadhaarBackPath != null)
                  Expanded(
                    child: _buildDocumentPreview('Aadhaar Back', teacher.aadhaarBackPath!),
                  ),
                if (teacher.aadhaarFrontPath == null && teacher.aadhaarBackPath == null)
                  const Text('No documents uploaded', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      );
    } else {
      final principal = person as Principal;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Qualification', principal.qualification),
            _buildDetailRow('Experience', principal.experience),
            const SizedBox(height: 24),
            const Text('Identity Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (principal.aadhaarFrontPath != null)
                  Expanded(
                    child: _buildDocumentPreview('Aadhaar Front', principal.aadhaarFrontPath!),
                  ),
                const SizedBox(width: 16),
                if (principal.aadhaarBackPath != null)
                  Expanded(
                    child: _buildDocumentPreview('Aadhaar Back', principal.aadhaarBackPath!),
                  ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentPreview(String label, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: path.startsWith('http')
                ? Image.network(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final teacher = _person as Teacher;
    if (teacher.schedule.isEmpty) return const SizedBox.shrink();

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    // Group schedule by day
    final Map<int, List<TeacherScheduleEntry>> groupedSchedule = {};
    for (var entry in teacher.schedule) {
      groupedSchedule.putIfAbsent(entry.day, () => []).add(entry);
    }

    // Sort entries within each day by period
    for (var dayEntries in groupedSchedule.values) {
      dayEntries.sort((a, b) => a.period.compareTo(b.period));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                onPressed: () async {
                  final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
                  final session = await dashboardRepo.getCurrentSession();
                  if (mounted) {
                    PdfGenerator.downloadTeacherTimetable(
                      teacher: teacher,
                      sessionName: session?.sessionName,
                    );
                  }
                },
                tooltip: 'Download Schedule',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...days.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final dayName = entry.value;
            final dayEntries = groupedSchedule[dayIndex] ?? [];

            if (dayEntries.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dayEntries.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Period ${e.period + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${e.className} - ${e.subject}', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHolidaySection() {
    final teacher = _person as Teacher;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Holidays & Leaves',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(onPressed: _showApplyLeaveDialog, child: const Text('Apply Leave')),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingRecords)
            const Center(child: CircularProgressIndicator())
          else if (_leaveRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No leave records found', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaveRecords.length > 5 ? 5 : _leaveRecords.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final leave = _leaveRecords[index];
                return _buildLeaveRow(
                  leave.leaveType,
                  "${leave.startDate.day}/${leave.startDate.month}/${leave.startDate.year}",
                  leave.status,
                );
              },
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Remaining Leaves: ${(teacher.leaves?.totalAnnualLeaves ?? 12) - (teacher.leaves?.consumedLeaves ?? 0)} Days',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog() {
    final reasonController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    String leaveType = 'Casual Leave';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: leaveType,
                  items: ['Sick Leave', 'Casual Leave', 'Paid Leave', 'Unpaid Leave']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => leaveType = v!),
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text("${startDate.day}/${startDate.month}/${startDate.year}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text("${endDate.day}/${endDate.month}/${endDate.year}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final repo = Provider.of<StaffRepository>(context, listen: false);
                final success = await repo.applyLeave(
                  (_person as Teacher).id!,
                  LeaveRecord(
                    teacherId: (_person as Teacher).id!,
                    leaveType: leaveType,
                    startDate: startDate,
                    endDate: endDate,
                    totalDays: endDate.difference(startDate).inDays + 1,
                    reason: reasonController.text,
                    status: 'Pending',
                  ),
                );
                if (success) {
                  Navigator.pop(context);
                  _fetchRecords();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySection() {
    final teacher = _person as Teacher;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salary Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Base Salary',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹ ${teacher.baseSalary}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: _showEditBaseSalaryDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAddSalaryDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Record Payment'),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Payment History',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_isLoadingRecords)
            const Center(child: CircularProgressIndicator())
          else if (_salaryRecords.isEmpty)
            const Text('No payment history found',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
          else
            ..._salaryRecords.take(5).map((s) => _buildHistoryItem(
                  "${_getMonthName(s.month)} ${s.year}",
                  "₹ ${s.netSalary}",
                  s.paymentMethod,
                )),
        ],
      ),
    );
  }

  void _showEditBaseSalaryDialog() {
    final teacher = _person as Teacher;
    final controller =
        TextEditingController(text: teacher.baseSalary.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Base Salary'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Base Salary',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newSalary =
                  double.tryParse(controller.text) ?? teacher.baseSalary;
              final repo = Provider.of<StaffRepository>(context, listen: false);

              final updatedTeacher = Teacher(
                id: teacher.id,
                name: teacher.name,
                gender: teacher.gender,
                email: teacher.email,
                phone: teacher.phone,
                subjects: teacher.subjects,
                dob: teacher.dob,
                photoPath: teacher.photoPath,
                aadhaarFrontPath: teacher.aadhaarFrontPath,
                aadhaarBackPath: teacher.aadhaarBackPath,
                maritalStatus: teacher.maritalStatus,
                address: teacher.address,
                dateOfJoining: teacher.dateOfJoining,
                department: teacher.department,
                qualification: teacher.qualification,
                experience: teacher.experience,
                status: teacher.status,
                classesTeaching: teacher.classesTeaching,
                sections: teacher.sections,
                isClassTeacher: teacher.isClassTeacher,
                classTeacherOfClass: teacher.classTeacherOfClass,
                classTeacherOfSection: teacher.classTeacherOfSection,
                baseSalary: newSalary,
                bankDetails: teacher.bankDetails,
                leaves: teacher.leaves,
                emergencyContact: teacher.emergencyContact,
              );

              final success =
                  await repo.updateTeacher(teacher.id!, updatedTeacher);
              if (success) {
                if (mounted) {
                  // Refresh dashboard stats
                  Provider.of<DashboardRepository>(context, listen: false).getDashboardStats();
                  setState(() {
                    _person = updatedTeacher;
                  });
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSalaryDialog() {
    final teacher = _person as Teacher;
    final amountController =
        TextEditingController(text: teacher.baseSalary.toString());
    final remarksController = TextEditingController();
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    String paymentMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: month,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(
                                value: m, child: Text(_getMonthName(m))))
                            .toList(),
                        onChanged: (v) => setDialogState(() => month = v!),
                        decoration: const InputDecoration(labelText: 'Month'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: year,
                        items: [year - 1, year, year + 1]
                            .map((y) => DropdownMenuItem(
                                value: y, child: Text(y.toString())))
                            .toList(),
                        onChanged: (v) => setDialogState(() => year = v!),
                        decoration: const InputDecoration(labelText: 'Year'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                      labelText: 'Amount Paid', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Payment Method',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cash'),
                        value: 'Cash',
                        groupValue: paymentMethod,
                        onChanged: (v) =>
                            setDialogState(() => paymentMethod = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Online'),
                        value: 'Online',
                        groupValue: paymentMethod,
                        onChanged: (v) =>
                            setDialogState(() => paymentMethod = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: remarksController,
                  decoration:
                      const InputDecoration(labelText: 'Remarks (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final repo =
                    Provider.of<StaffRepository>(context, listen: false);
                final amount = double.tryParse(amountController.text) ?? 0;
                final success = await repo.addSalaryRecord(
                  teacher.id!,
                  SalaryRecord(
                    teacherId: teacher.id!,
                    month: month,
                    year: year,
                    baseSalary: teacher.baseSalary,
                    allowances: 0,
                    deductions: 0,
                    netSalary: amount,
                    paymentDate: DateTime.now(),
                    paymentMethod: paymentMethod,
                    status: 'Paid',
                    remarks: remarksController.text,
                  ),
                );
                if (success) {
                  if (mounted) {
                    // Refresh dashboard stats
                    Provider.of<DashboardRepository>(context, listen: false).getDashboardStats();
                    Navigator.pop(context);
                    _fetchRecords();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }


  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildSalaryStat(String label, String value,
      {bool isNegative = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 18 : 15,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: isNegative
                ? Colors.red
                : (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String month, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(month, style: const TextStyle(fontSize: 14)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLeaveRow(String type, String date, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Approved'
                  ? Colors.green.withOpacity(0.1)
                  : (status == 'Pending'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: status == 'Approved'
                    ? Colors.green
                    : (status == 'Pending' ? Colors.orange : Colors.red),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

