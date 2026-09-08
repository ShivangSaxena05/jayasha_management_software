import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/widgets/add_payment_dialog.dart';
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';

class PendingFeesPage extends StatefulWidget {
  const PendingFeesPage({super.key});

  @override
  State<PendingFeesPage> createState() => _PendingFeesPageState();
}

class _PendingFeesPageState extends State<PendingFeesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingStudents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingFees();
  }

  Future<void> _fetchPendingFees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feeRepo = Provider.of<FeeRepository>(context, listen: false);
      final results = await feeRepo.getPendingFees();

      if (mounted) {
        setState(() {
          _pendingStudents = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load pending fees: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pending Fees'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingFees,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _fetchPendingFees,
      );
    }

    if (_pendingStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
            const SizedBox(height: 16),
            const Text(
              'No pending dues found!',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const Text(
              'All students have cleared their fees for this session.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingStudents.length,
            itemBuilder: (context, index) {
              final item = _pendingStudents[index];
              return _buildPendingCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final totalPending = _pendingStudents.fold<double>(0, (sum, item) => sum + (item['pendingAmount'] ?? 0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Outstanding', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                '₹ $totalPending',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_pendingStudents.length} Students',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> item) {
    final studentData = item['student'];
    final student = studentData != null ? StudentAdmission.fromJson(studentData) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      borderOnForeground: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    item['name']?[0] ?? 'S',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Adm No: ${item['admissionNumber']} • Class: ${item['className']} ${item['section'] ?? ''}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Father: ${item['fatherName']}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      if (item['pendingCategories'] != null && (item['pendingCategories'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (item['pendingCategories'] as List).map((cat) {
                            final catName = _capitalize(cat['category']?.toString() ?? '');
                            final pendingMonths = cat['pendingMonths'] as List?;
                            String display = catName;
                            if (cat['category'] == 'monthly' && pendingMonths != null && pendingMonths.isNotEmpty) {
                              display += ' (${pendingMonths.join(", ")})';
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                display,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Pending', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '₹ ${item['pendingAmount']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ₹ ${item['paidAmount']} / ₹ ${item['totalExpected']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                ElevatedButton.icon(
                  onPressed: student == null ? null : () {
                    String? initialCategory;
                    if (item['pendingCategories'] != null && (item['pendingCategories'] as List).isNotEmpty) {
                      initialCategory = item['pendingCategories'][0]['category'];
                    }

                    showAddPaymentDialog(
                      context,
                      prefilledStudent: student,
                      prefilledCategory: initialCategory,
                      onSuccess: _fetchPendingFees,
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
