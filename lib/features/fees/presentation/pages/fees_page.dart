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
import 'package:collection/collection.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/widgets/add_payment_dialog.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/pages/pending_fees_page.dart';
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
  List<Map<String, dynamic>> _payments = [];
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
        feeRepo.getAllPayments(),
        feeRepo.getFeeStats(),
      ]);

      if (mounted) {
        setState(() {
          _payments = results[0] as List<Map<String, dynamic>>;
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
          Expanded(child: _buildPaymentHistoryTable()),
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
              onPressed: () => showAddPaymentDialog(
                context,
                onSuccess: _fetchData,
              ),
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
        _buildMiniStat(
          'Pending Dues',
          '₹ ${_feeStats['totalPending'] ?? 0.0}',
          Colors.red,
          Icons.account_balance_wallet_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingFeesPage())),
        ),
        const SizedBox(width: 16),
        _buildMiniStat(
          'Students Pending',
          (_feeStats['pendingStudents'] ?? 0).toString(),
          Colors.orange,
          Icons.people_outline,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingFeesPage())),
        ),
        const SizedBox(width: 16),
        _buildMiniStat('Collection (Today)', '₹ ${_feeStats['todayCollection'] ?? 0.0}', Colors.green, Icons.analytics_outlined),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                hintText: 'Search by student name or adm no...',
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

  Widget _buildPaymentHistoryTable() {
    final query = _searchController.text.toLowerCase();
    final filteredPayments = _payments.where((p) {
      final name = (p['studentName'] ?? '').toString().toLowerCase();
      final admNo = (p['admissionNumber'] ?? '').toString().toLowerCase();
      return name.contains(query) || admNo.contains(query);
    }).toList();

    // Sort by most recent
    filteredPayments.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    if (!_isLoading && filteredPayments.isEmpty) {
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
            Icon(Icons.history_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No payment history found' : 'No matches for "${_searchController.text}"',
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
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Adm No', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredPayments.map((payment) {
                final date = payment['date'] as DateTime;
                return DataRow(cells: [
                  DataCell(Text(DateFormat('dd MMM yyyy').format(date))),
                  DataCell(Text(payment['studentName'] ?? 'Unknown')),
                  DataCell(Text(payment['admissionNumber'] ?? 'N/A')),
                  DataCell(Text(payment['category'].toString().split('.').last.toUpperCase())),
                  DataCell(Text('₹${payment['amount']}')),
                  DataCell(Text(payment['mode'].toString().split('.').last.toUpperCase())),
                  DataCell(Text(payment['remarks'] ?? '-')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                        tooltip: 'View Student',
                        onPressed: () async {
                          final studentId = payment['studentId'];
                          if (studentId != null) {
                            try {
                              final studentRepo = Provider.of<StudentRepository>(context, listen: false);
                              final student = await studentRepo.getStudentById(studentId);
                              if (student != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailPage(student: student),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error navigating to student detail: $e');
                            }
                          }
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
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
