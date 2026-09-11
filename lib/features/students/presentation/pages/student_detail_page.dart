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
import 'package:jayasha_childrens_academy/features/certificates/presentation/pages/id_card_editor_page.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/widgets/add_payment_dialog.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

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

  String _getHumanReadableError(dynamic e) {
    final error = e.toString().toLowerCase();
    if (error.contains('socketexception') ||
        error.contains('connection failed') ||
        error.contains('os error 7')) {
      return "No internet connection. Please connect to the internet and try again.";
    }
    if (error.contains('timeout')) {
      return "Connection timed out. Please try again.";
    }
    return "An error occurred: $e";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
      _feeRepo?.addListener(_fetchFeeHistory);
      _fetchFeeHistory();
    });
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
        SnackBar(content: Text(_getHumanReadableError(e)), backgroundColor: Colors.red),
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
      if (mounted) {
        setState(() => _isLoadingFees = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getHumanReadableError(e))),
        );
      }
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
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IdCardEditorPage(student: widget.student),
                ),
              );
            },
            tooltip: 'Create ID Card',
          ),
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildFeesTab(),
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
                onPressed: () => showAddPaymentDialog(
                  context,
                  prefilledStudent: widget.student,
                  onSuccess: _fetchFeeHistory,
                ),
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
              try {
                final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
                final session = await dashboardRepo.getCurrentSession();
                if (context.mounted) {
                  await PdfGenerator.downloadFeeReceipt(
                    student: widget.student,
                    payment: payment,
                    sessionName: session?.sessionName ?? 'Current Session',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_getHumanReadableError(e)), backgroundColor: Colors.red),
                  );
                }
              }
            },
            tooltip: 'Download Receipt',
          ),
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
}
