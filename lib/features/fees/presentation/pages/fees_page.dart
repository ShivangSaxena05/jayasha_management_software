import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/pages/fee_structure_page.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/students/presentation/pages/student_detail_page.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:intl/intl.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showStructure = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<StudentAdmission> _students = [];
  Map<String, dynamic> _feeStats = {
    'totalPending': 0.0,
    'pendingStudents': 0,
    'todayCollection': 0.0,
  };
  fee_domain.FeeRepository? _feeRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
      _feeRepo?.addListener(_fetchData);
      _fetchData();
    });
  }

  @override
  void dispose() {
    _feeRepo?.removeListener(_fetchData);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);

      // Fetch in parallel for efficiency
      final results = await Future.wait([
        studentRepo.getStudents(),
        feeRepo.getFeeStats(),
      ]);

      if (mounted) {
        setState(() {
          _students = results[0] as List<StudentAdmission>;
          final stats = results[1] as Map<String, dynamic>;
          if (stats.isNotEmpty) {
            _feeStats = stats;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching fee data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getHumanReadableError(e);
        });
      }
    }
  }

  String _getHumanReadableError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (e.toString().contains('TimeoutException')) {
      return 'The connection timed out. Please try again later.';
    }
    return 'An unexpected error occurred while fetching fee data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_showStructure) {
      return FeeStructurePage(
        onBack: () => setState(() => _showStructure = false),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _fetchData,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildStudentTable()),
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
          children: const [
            Text(
              'Fee Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Overview of school finances and student dues',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _showStructure = true),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddFeeDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('New Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildMiniStat('Pending Dues', '₹ ${_feeStats['totalPending']}', Colors.red, Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _buildMiniStat('Students Pending', _feeStats['pendingStudents'].toString(), Colors.orange, Icons.people_outline),
        const SizedBox(width: 16),
        _buildMiniStat('Collection (Today)', '₹ ${_feeStats['todayCollection']}', Colors.green, Icons.analytics_outlined),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search student...',
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Add Class filter if needed
      ],
    );
  }

  Widget _buildStudentTable() {
    final filteredStudents = _students.where((s) =>
        s.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        s.admissionNumber.contains(_searchController.text)).toList();

    if (!_isLoading && filteredStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No students found' : 'No student matching "${_searchController.text}"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _searchController.clear()),
                child: const Text('Clear search'),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Adm No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredStudents.map((student) => DataRow(cells: [
              DataCell(Text(student.admissionNumber)),
              DataCell(Text(student.name)),
              DataCell(Text(student.section ?? 'N/A')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.payment, size: 18, color: AppColors.primary),
                    onPressed: () => _showAddFeeDialog(context, prefilledStudent: student),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
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
            ])).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddFeeDialog(BuildContext context, {StudentAdmission? prefilledStudent}) async {
    final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
    final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
    final examRepo = Provider.of<ExamRepository>(context, listen: false);
    final studentRepo = Provider.of<StudentRepository>(context, listen: false);

    AcademicSession? currentSession;
    List<dynamic> feeStructures = [];
    List<dynamic> exams = [];
    bool isFetchingData = false;

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

    final TextEditingController admNoController = TextEditingController(text: prefilledStudent?.admissionNumber);
    final TextEditingController amountController = TextEditingController();
    StudentAdmission? foundStudent = prefilledStudent;
    PaymentMode selectedMode = PaymentMode.cash;
    FeeCategory selectedCategory = FeeCategory.monthly;
    bool isFullPayment = true;
    String? selectedMonth;
    String? selectedExamId;

    final List<String> months = [
      'April', 'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December', 'January', 'February', 'March'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper to get base amount from structure
          double getBaseAmount(FeeCategory category) {
            if (foundStudent == null) return 0.0;
            final classStructure = feeStructures.firstWhere(
              (s) => s['class'] != null && (s['class']['_id'] == foundStudent!.currentClassId || s['class'] == foundStudent!.currentClassId),
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

          final totalFee = getBaseAmount(selectedCategory);
          final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
          final dueAmount = totalFee - enteredAmount;

          return AlertDialog(
            title: const Text('Add Fee Payment'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: admNoController,
                      decoration: InputDecoration(
                        labelText: 'Admission Number',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            try {
                              final results = await studentRepo.getStudents(admissionNumber: admNoController.text);
                              if (results.isNotEmpty) {
                                setDialogState(() {
                                  foundStudent = results.first;
                                  updateAmount();
                                });
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Student not found')),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error searching student: $e');
                            }
                          },
                        ),
                      ),
                      onSubmitted: (val) async {
                        try {
                          final results = await studentRepo.getStudents(admissionNumber: val);
                          if (results.isNotEmpty) {
                            setDialogState(() {
                              foundStudent = results.first;
                              updateAmount();
                            });
                          }
                        } catch (e) {
                          debugPrint('Error searching student on submit: $e');
                        }
                      },
                    ),
                    if (foundStudent != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _buildDialogInfoRow('Student', foundStudent!.name, isBold: true),
                            _buildDialogInfoRow('Class', '${foundStudent!.className ?? 'N/A'} ${foundStudent!.section ?? ''}'),
                            _buildDialogInfoRow('Father', foundStudent!.fatherName),
                            _buildDialogInfoRow('Mother', foundStudent!.motherName),
                            _buildDialogInfoRow('Roll No', foundStudent!.rollNumber ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
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
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Partial'),
                              value: false,
                              groupValue: isFullPayment,
                              onChanged: (val) => setDialogState(() => isFullPayment = val!),
                            ),
                          ),
                        ],
                      ),
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
                      DropdownButtonFormField<PaymentMode>(
                        value: selectedMode,
                        items: PaymentMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                        onChanged: (val) => setDialogState(() => selectedMode = val!),
                        decoration: const InputDecoration(labelText: 'Mode', border: OutlineInputBorder()),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              if (foundStudent != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
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
                        studentId: foundStudent!.id!,
                        academicSessionId: currentSession!.id!,
                        amount: amount,
                        date: DateTime.now(),
                        mode: selectedMode,
                        category: selectedCategory,
                        remarks: remarks,
                      );

                      final success = await feeRepo.recordPayment(payment);
                      if (success && context.mounted) {
                        // Refresh dashboard stats
                        Provider.of<DashboardRepository>(context, listen: false).getDashboardStats();
                        Navigator.pop(context);
                        _fetchData();

                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Payment Successful'),
                            content: Text('₹$amount recorded for ${foundStudent!.name}.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await PdfGenerator.downloadFeeReceipt(
                                    student: foundStudent!,
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
                    } catch (e) {
                      debugPrint('Error recording payment: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Submit'),
                )
            ],
          );
        },
      ),
    );
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
}
