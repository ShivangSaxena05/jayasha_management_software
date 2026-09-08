import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:jayasha_childrens_academy/features/attendance/data/repositories/attendance_repository.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:intl/intl.dart';

class StudentDetailPage extends StatefulWidget {
  final StudentAdmission student;

  const StudentDetailPage({super.key, required this.student});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FeePayment> _payments = [];
  bool _isLoadingFees = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoadingAttendance = false;
  Map<String, dynamic>? _attendanceData;
  fee_domain.FeeRepository? _feeRepo;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _rollNumberController;
  late TextEditingController _sectionController;
  late TextEditingController _dobController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
      _feeRepo?.addListener(_fetchFeeHistory);
      _fetchFeeHistory();
      _fetchAttendanceReport();
    });
  }

  Future<void> _fetchAttendanceReport() async {
    if (!mounted) return;
    setState(() => _isLoadingAttendance = true);
    try {
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);
      // Fetch for last 30 days by default
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      final endDate = DateFormat('yyyy-MM-dd').format(now);

      final result = await attRepo.getStudentAttendanceReport(
        studentId: widget.student.id!,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _attendanceData = result['data'];
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  @override
  void dispose() {
    _feeRepo?.removeListener(_fetchFeeHistory);
    _tabController.dispose();
    _nameController.dispose();
    _rollNumberController.dispose();
    _sectionController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.student.name);
    _rollNumberController = TextEditingController(text: widget.student.rollNumber ?? '');
    _sectionController = TextEditingController(text: widget.student.section ?? '');
    _dobController = TextEditingController(text: widget.student.dob);
    _fatherNameController = TextEditingController(text: widget.student.fatherName);
    _motherNameController = TextEditingController(text: widget.student.motherName);
    _contactController = TextEditingController(text: widget.student.guardianPhone);
    _addressController = TextEditingController(text: widget.student.address);
    _selectedGender = widget.student.gender;
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);

      final updatedAdmission = StudentAdmission(
        id: widget.student.id,
        admissionNumber: widget.student.admissionNumber, // Usually not editable
        rollNumber: _rollNumberController.text.isEmpty ? null : _rollNumberController.text,
        name: _nameController.text,
        dob: _dobController.text,
        gender: _selectedGender ?? widget.student.gender,
        currentClassId: widget.student.currentClassId,
        section: _sectionController.text.isEmpty ? null : _sectionController.text,
        fatherName: _fatherNameController.text,
        motherName: _motherNameController.text,
        guardianPhone: _contactController.text,
        address: _addressController.text,
        admissionDate: widget.student.admissionDate,
        academicSessionId: widget.student.academicSessionId,
      );

      final result = await studentRepo.updateStudent(widget.student.id!, updatedAdmission);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchFeeHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingFees = true);
    try {
      final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
      final payments = await feeRepo.getStudentPayments(widget.student.id!);
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoadingFees = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching fee history: $e');
      if (mounted) setState(() => _isLoadingFees = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_isEditing ? 'Editing ' : ''}${widget.student.name}\'s Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) ...[
            if (_isSaving)
              const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProfile,
                tooltip: 'Save Changes',
              ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initControllers(); // Reset to original values
                });
              },
              tooltip: 'Cancel',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.person_outline)),
            Tab(text: 'Fees', icon: Icon(Icons.payments_outlined)),
            Tab(text: 'Attendance', icon: Icon(Icons.calendar_month_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildFeesTab(),
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildSectionCard(
                'Personal Information',
                [
                  _buildDetailRow('Full Name', widget.student.name, controller: _nameController),
                  _buildDetailRow('Admission No', widget.student.admissionNumber, readOnly: true),
                  _buildDetailRow('Roll Number', widget.student.rollNumber ?? 'Not Assigned', controller: _rollNumberController),
                  _buildDetailRow('Section', widget.student.section ?? 'N/A', controller: _sectionController),
                  _buildDetailRow('Date of Birth', widget.student.dob, controller: _dobController, isDate: true),
                  _buildDetailRow('Gender', widget.student.gender, isGender: true),
                ],
                action: !_isEditing ? IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Profile',
                ) : null,
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                'Parent Details',
                [
                  _buildDetailRow('Father\'s Name', widget.student.fatherName, controller: _fatherNameController),
                  _buildDetailRow('Mother\'s Name', widget.student.motherName, controller: _motherNameController),
                  _buildDetailRow('Contact Number', widget.student.guardianPhone, controller: _contactController),
                  _buildDetailRow('Address', widget.student.address, controller: _addressController, maxLines: 3),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                'Academic Record',
                [
                  _buildDetailRow('Admission Date', widget.student.admissionDate, readOnly: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeesTab() {
    if (_isLoadingFees) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFeeDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No payment history found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return _buildFeeRow(
                      context,
                      payment.category.name.toUpperCase(),
                      '₹ ${payment.amount}',
                      'PAID',
                      DateFormat('dd MMM yyyy, hh:mm a').format(payment.date),
                      payment: payment,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddFeeDialog(BuildContext context) async {
    final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
    final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
    final examRepo = Provider.of<ExamRepository>(context, listen: false);

    AcademicSession? currentSession;
    List<dynamic> feeStructures = [];
    List<dynamic> exams = [];

    try {
      currentSession = await dashboardRepo.getCurrentSession();
      if (currentSession != null) {
        feeStructures = await feeRepo.getFeeStructures();
        final examResponse = await examRepo.getExams(currentSession.id!);
        if (examResponse['success'] == true) {
          exams = examResponse['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Error preparing payment dialog: $e');
    }

    if (currentSession == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active academic session found'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final TextEditingController amountController = TextEditingController();
    PaymentMode selectedMode = PaymentMode.cash;
    FeeCategory selectedCategory = FeeCategory.monthly;
    bool isFullPayment = true;
    String? selectedMonth;
    String? selectedExamId;

    final List<String> months = [
      'April', 'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December', 'January', 'February', 'March'
    ];

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper to get base amount from structure
            double getBaseAmount(FeeCategory category) {
              final classStructure = feeStructures.firstWhere(
                (s) => s['class'] != null && (s['class']['_id'] == widget.student.currentClassId || s['class'] == widget.student.currentClassId),
                orElse: () => null,
              );

              if (classStructure != null && classStructure['components'] != null) {
                final components = classStructure['components'] as List;
                dynamic component;

                switch (category) {
                  case FeeCategory.monthly:
                    component = components.firstWhere((c) =>
                      c['name'].toString().toLowerCase().contains('monthly') ||
                      c['name'].toString().toLowerCase().contains('tuition'),
                      orElse: () => null);
                    break;
                  case FeeCategory.admission:
                    component = components.firstWhere((c) =>
                      c['name'].toString().toLowerCase().contains('admission'),
                      orElse: () => null);
                    break;
                  case FeeCategory.exam:
                    component = components.firstWhere((c) =>
                      c['name'].toString().toLowerCase().contains('exam'),
                      orElse: () => null);
                    break;
                  default:
                    break;
                }

                if (component != null) {
                  return double.tryParse(component['amount'].toString()) ?? 0.0;
                }
              }
              return 0.0;
            }

            void updateAmount() {
              if (isFullPayment) {
                amountController.text = getBaseAmount(selectedCategory).toString();
              }
            }

            // Initial auto-fill
            if (amountController.text.isEmpty && isFullPayment) {
              updateAmount();
            }

            final totalFee = getBaseAmount(selectedCategory);
            final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
            final dueAmount = totalFee - enteredAmount;

            return AlertDialog(
              title: const Text('Record Fee Payment'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _buildDialogInfoRow('Student', widget.student.name, isBold: true),
                            _buildDialogInfoRow('Adm No', widget.student.admissionNumber),
                            _buildDialogInfoRow('Class', '${widget.student.className ?? 'N/A'} ${widget.student.section ?? ''}'),
                            _buildDialogInfoRow('Roll No', widget.student.rollNumber ?? 'N/A'),
                            _buildDialogInfoRow('Father', widget.student.fatherName),
                            _buildDialogInfoRow('Mother', widget.student.motherName),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment Category
                      DropdownButtonFormField<FeeCategory>(
                        value: selectedCategory,
                        items: FeeCategory.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                              updateAmount();
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Fee Category', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),

                      // Dynamic dropdowns based on category
                      if (selectedCategory == FeeCategory.monthly) ...[
                        DropdownButtonFormField<String>(
                          value: selectedMonth,
                          hint: const Text('Select Month'),
                          items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setDialogState(() => selectedMonth = val),
                          decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (selectedCategory == FeeCategory.exam) ...[
                        DropdownButtonFormField<String>(
                          value: selectedExamId,
                          hint: const Text('Select Exam'),
                          items: exams.map((e) => DropdownMenuItem(value: e['_id'].toString(), child: Text(e['name']))).toList(),
                          onChanged: (val) => setDialogState(() => selectedExamId = val),
                          decoration: const InputDecoration(labelText: 'Exam', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Payment Type Toggle
                      const Text('Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Full'),
                              value: true,
                              groupValue: isFullPayment,
                              onChanged: (val) => setDialogState(() {
                                isFullPayment = val!;
                                updateAmount();
                              }),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Partial'),
                              value: false,
                              groupValue: isFullPayment,
                              onChanged: (val) => setDialogState(() => isFullPayment = val!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      // Amount Entry
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        readOnly: isFullPayment,
                        decoration: InputDecoration(
                          labelText: isFullPayment ? 'Amount (Fixed)' : 'Enter Amount to Pay',
                          border: const OutlineInputBorder(),
                          filled: isFullPayment,
                          fillColor: isFullPayment ? Colors.grey.shade100 : null,
                          suffixIcon: isFullPayment ? const Icon(Icons.lock_outline, size: 20) : null,
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      if (!isFullPayment) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Fee: ₹$totalFee', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Due: ₹${dueAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dueAmount > 0 ? Colors.orange : Colors.green
                              )
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Payment Mode
                      DropdownButtonFormField<PaymentMode>(
                        value: selectedMode,
                        items: PaymentMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                        onChanged: (val) => setDialogState(() => selectedMode = val!),
                        decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                      return;
                    }
                    if (selectedCategory == FeeCategory.monthly && selectedMonth == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a month')));
                      return;
                    }
                    if (selectedCategory == FeeCategory.exam && selectedExamId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an exam')));
                      return;
                    }

                    String remarks = isFullPayment ? 'Full Payment' : 'Partial Payment';
                    if (selectedCategory == FeeCategory.monthly) remarks += ' - Fee for $selectedMonth';
                    if (selectedCategory == FeeCategory.exam) {
                      final exam = exams.firstWhere((e) => e['_id'].toString() == selectedExamId);
                      remarks += ' - Exam: ${exam['name']}';
                    }

                    final payment = FeePayment(
                      studentId: widget.student.id!,
                      academicSessionId: currentSession!.id!,
                      amount: amount,
                      date: DateTime.now(),
                      mode: selectedMode,
                      category: selectedCategory,
                      remarks: remarks,
                    );

                    final success = await feeRepo.recordPayment(payment);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      _fetchFeeHistory();

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Success'),
                          content: Text('₹$amount received for ${widget.student.name}.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await PdfGenerator.downloadFeeReceipt(
                                  student: widget.student,
                                  payment: payment,
                                  sessionName: currentSession!.sessionName,
                                );
                              },
                              child: const Text('Download Receipt'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm Payment'),
                )
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildDialogInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          )),
        ],
      ),
    );
  }

  Widget _buildFeeRow(BuildContext context, String title, String amount, String status, String date, {required FeePayment payment}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('PAID', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.primary),
            onPressed: () async {
              final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
              final session = await dashboardRepo.getCurrentSession();
              if (context.mounted) {
                await PdfGenerator.downloadFeeReceipt(
                  student: widget.student,
                  payment: payment,
                  sessionName: session?.sessionName ?? 'Current Session',
                );
              }
            },
            tooltip: 'Download Receipt',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceItem(String date, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Text(date, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, {Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {
    TextEditingController? controller,
    bool readOnly = false,
    bool isDate = false,
    bool isGender = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditing && !readOnly
                ? _buildEditableField(label, controller, isDate, isGender, maxLines)
                : Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController? controller, bool isDate, bool isGender, int maxLines) {
    if (isGender) {
      return DropdownButtonFormField<String>(
        value: _selectedGender,
        items: ['Male', 'Female', 'Other']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (val) => setState(() => _selectedGender = val),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(),
        ),
      );
    }

    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: isDate,
      onTap: isDate ? () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null && controller != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      } : null,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _attendanceData?['stats'];
    final records = _attendanceData?['records'] as List? ?? [];

    final presentCount = stats?['Present'] ?? 0;
    final absentCount = stats?['Absent'] ?? 0;
    final lateCount = stats?['Late'] ?? 0;
    final total = stats?['total'] ?? 0;

    final attendancePercentage = total > 0 ? ((presentCount / total) * 100).toStringAsFixed(1) : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildSectionCard(
                'Attendance Overview (Last 30 Days)',
                [
                  Row(
                    children: [
                      _buildAttendanceStat('Present', '$attendancePercentage%', Colors.green),
                      const SizedBox(width: 16),
                      _buildAttendanceStat('Absent', '$absentCount', Colors.red),
                      const SizedBox(width: 16),
                      _buildAttendanceStat('Late', '$lateCount', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Records', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (records.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No attendance records found for this period', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...records.reversed.take(10).map((record) {
                      final date = DateTime.parse(record['date']);
                      final status = record['status'];
                      final color = status == 'Present' ? Colors.green : (status == 'Absent' ? Colors.red : Colors.orange);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: color),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
