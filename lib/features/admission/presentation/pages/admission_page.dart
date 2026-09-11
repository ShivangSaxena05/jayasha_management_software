import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/core/utils/app_snackbar.dart';
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';

class AdmissionPage extends StatefulWidget {
  const AdmissionPage({super.key});

  @override
  State<AdmissionPage> createState() => _AdmissionPageState();
}

class _AdmissionPageState extends State<AdmissionPage> {
  int _currentStep = 0;
  // Separate keys for each step to allow independent validation
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  bool _isLoading = false;

  // Form Controllers
  final _admissionNumberController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedClassId;
  String? _selectedSection;
  List<String> _availableSections = [];

  List<SchoolClass> _availableClasses = [];
  String? _currentSessionId;
  double? _admissionFeeAmount;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

      final session = await dashboardRepo.getCurrentSession();
      _currentSessionId = session?.id;

      if (_currentSessionId != null) {
        await classRepo.fetchClasses(_currentSessionId!);
        setState(() {
          _availableClasses = classRepo.classes;
          if (_availableClasses.isNotEmpty) {
            _selectedClassId = _availableClasses[0].id;
            _updateSections(_availableClasses[0]);
            _loadAdmissionFee();
          }
        });
      } else {
        // Fallback: If no active session, try fetching all classes or show a warning
        debugPrint('Warning: No active academic session found.');
        await classRepo.fetchClasses(''); // Fetch classes without session filter if allowed
        setState(() {
          _availableClasses = classRepo.classes;
        });
      }
    } catch (e) {
      debugPrint('Error loading admission data: $e');
      setState(() {
        if (e.toString().contains('SocketException') || e.toString().contains('Connection failed')) {
          _errorMessage = 'No internet connection. Please check your network and try again.';
        } else if (e.toString().contains('TimeoutException')) {
          _errorMessage = 'The connection timed out. Please try again later.';
        } else {
          _errorMessage = 'An unexpected error occurred while loading admission data. Please try again.';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _errorMessage;

  Future<void> _loadAdmissionFee() async {
    if (_selectedClassId == null) return;

    try {
      final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
      final structures = await feeRepo.getFeeStructures();

      final classStructure = structures.firstWhere(
        (s) => s['class'] != null && (s['class']['_id'] == _selectedClassId || s['class'] == _selectedClassId),
        orElse: () => <String, dynamic>{},
      );

      if (classStructure.isNotEmpty && classStructure['components'] != null) {
        final admissionComponent = (classStructure['components'] as List).firstWhereOrNull(
          (c) => c['name'].toString().toLowerCase().contains('admission'),
        );

        setState(() {
          _admissionFeeAmount = admissionComponent != null
              ? double.tryParse(admissionComponent['amount'].toString())
              : 0.0;
        });
      } else {
        setState(() => _admissionFeeAmount = 0.0);
      }
    } catch (e) {
      debugPrint('Error loading admission fee: $e');
    }
  }

  void _updateSections(SchoolClass? selectedClass) {
    setState(() {
      if (selectedClass != null && selectedClass.sections.isNotEmpty) {
        _availableSections = selectedClass.sections;
        _selectedSection = _availableSections[0];
      } else {
        _availableSections = [];
        _selectedSection = null;
      }
    });
  }

  @override
  void dispose() {
    _admissionNumberController.dispose();
    _rollNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Student Date of Birth',
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    // Validate the last step (Review) though it mostly has summary
    if (!_formKeys[2].currentState!.validate()) return;

    if (_selectedClassId == null || _currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Class or Session data is missing. Please restart the app.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final studentRepo = Provider.of<StudentRepository>(context, listen: false);

    final admission = StudentAdmission(
      admissionNumber: _admissionNumberController.text,
      rollNumber: _rollNumberController.text.isEmpty ? null : _rollNumberController.text,
      name: '${_firstNameController.text} ${_lastNameController.text}'.trim(),
      dob: _dobController.text,
      gender: _selectedGender,
      currentClassId: _selectedClassId!,
      section: _selectedSection,
      fatherName: _fatherNameController.text,
      motherName: _motherNameController.text,
      guardianPhone: _contactController.text,
      address: _addressController.text,
      admissionDate: DateTime.now().toIso8601String(),
      academicSessionId: _currentSessionId!,
    );

    try {
      final result = await studentRepo.registerAdmission(admission);

      if (result['success']) {
        // Record admission fee payment automatically
        try {
          if (_admissionFeeAmount != null && _admissionFeeAmount! > 0) {
            final studentData = result['data']['data'];
            final studentId = studentData['_id'];

            final feeRepo = Provider.of<fee_domain.FeeRepository>(context, listen: false);
            if (mounted) {
               await feeRepo.recordPayment(FeePayment(
                studentId: studentId,
                academicSessionId: _currentSessionId!,
                amount: _admissionFeeAmount!,
                date: DateTime.now(),
                mode: PaymentMode.cash, // Defaulting to cash for admission
                category: FeeCategory.admission,
                remarks: 'Admission Fee for ${_firstNameController.text} ${_lastNameController.text}',
              ));
            }
          }
        } catch (e) {
          debugPrint('Error recording automatic admission fee: $e');
          // We don't fail the whole process if fee recording fails, but maybe alert the user
        }

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student Registered Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _resetForm();
      } else {
        String errorMsg = result['message'] ?? 'Failed to register student.';
        // Suggestions for common errors
        if (errorMsg.contains('admissionNumber')) {
          errorMsg = "Admission Number already exists. Please use a unique ID.";
        }

        if (mounted) AppSnackbar.showError(context, errorMsg);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _admissionNumberController.clear();
      _rollNumberController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _dobController.clear();
      _fatherNameController.clear();
      _motherNameController.clear();
      _contactController.clear();
      _addressController.clear();
      _selectedGender = 'Male';
      if (_availableClasses.isNotEmpty) {
        _selectedClassId = _availableClasses[0].id;
        _updateSections(_availableClasses[0]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadInitialData,
      );
    }

    if (_isLoading && _availableClasses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Student Registration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                // Validate only the current step's form
                if (_formKeys[_currentStep].currentState!.validate()) {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitForm();
                  }
                } else {
                  print('DEBUG: Validation failed at step $_currentStep. Errors shown in UI.');
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              steps: [
                Step(
                  title: const Text('Basic Information'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _formKeys[0],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Admission Number', Icons.numbers, _admissionNumberController, hint: 'e.g. 2024001')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildTextField('Roll Number (Optional)', Icons.tag, _rollNumberController, hint: 'e.g. 15')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('First Name', Icons.person_outline, _firstNameController, hint: 'Student First Name')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildTextField('Last Name (Optional)', Icons.person_outline, _lastNameController, hint: 'Student Last Name')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Date of Birth',
                                Icons.calendar_today,
                                _dobController,
                                hint: 'YYYY-MM-DD',
                                readOnly: true,
                                onTap: () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildDropdownField('Gender', ['Male', 'Female', 'Other'], (val) {
                                setState(() => _selectedGender = val!);
                              }, _selectedGender),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildClassDropdown(),
                            ),
                            if (_selectedClassId != null && _availableSections.isNotEmpty) ...[
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDropdownField(
                                  'Section',
                                  _availableSections,
                                  (val) {
                                    setState(() => _selectedSection = val);
                                  },
                                  _selectedSection,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Parent/Guardian Details'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _formKeys[1],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        _buildTextField('Father\'s Name', Icons.person, _fatherNameController, hint: 'Enter Full Name'),
                        const SizedBox(height: 20),
                        _buildTextField('Mother\'s Name', Icons.person, _motherNameController, hint: 'Enter Full Name'),
                        const SizedBox(height: 20),
                        _buildTextField('Guardian Contact Number', Icons.phone, _contactController,
                          keyboardType: TextInputType.phone,
                          hint: '10-digit Mobile Number'),
                        const SizedBox(height: 20),
                        _buildTextField('Residential Address', Icons.home_outlined, _addressController, maxLines: 3, hint: 'Current Living Address'),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Review & Finalize'),
                  isActive: _currentStep >= 2,
                  content: Form(
                    key: _formKeys[2],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admission Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Student Name', '${_firstNameController.text} ${_lastNameController.text}'.trim()),
                        _buildSummaryRow('Admission No', _admissionNumberController.text),
                        if (_rollNumberController.text.isNotEmpty)
                          _buildSummaryRow('Roll Number', _rollNumberController.text),
                        _buildSummaryRow('Class', _getClassNameById(_selectedClassId)),
                        if (_selectedSection != null)
                          _buildSummaryRow('Section', _selectedSection!),
                        _buildSummaryRow('Father\'s Name', _fatherNameController.text),
                        _buildSummaryRow('Contact', _contactController.text),
                        const Divider(height: 32),
                        _buildSummaryRow(
                          'Admission Fee to be Paid',
                          '₹${_admissionFeeAmount?.toStringAsFixed(2) ?? '0.00'}',
                          isBold: true,
                          valueColor: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading) const Center(child: CircularProgressIndicator()),
                        const Text('Note: Please verify all details before submitting. Admission numbers cannot be changed easily later.',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class',
          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _availableClasses.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
          validator: (val) => val == null ? 'Please select a class' : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: _availableClasses.map((cls) {
            return DropdownMenuItem<String>(
              value: cls.id,
              child: Text(cls.name),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedClassId = val;
              final selectedClass = _availableClasses.firstWhere((c) => c.id == val);
              _updateSections(selectedClass);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
                fontSize: isBold ? 16 : 14,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getClassNameById(String? id) {
    if (id == null) return 'N/A';
    try {
      return _availableClasses.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {String? hint, int maxLines = 1, bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: (value) {
            if (label.contains('Optional')) return null;
            if (value == null || value.isEmpty) {
              return 'Required: Please enter $label';
            }
            if (label.contains('Contact Number')) {
              if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Enter a valid 10-digit mobile number (e.g. 9876543210)';
              }
            }
            if (label.contains('Admission Number') && value.length < 2) {
              return 'Please enter a valid unique Admission Number';
            }
            if (label.contains('Date of Birth') && value.isEmpty) {
              return 'Tap to select the student\'s Date of Birth';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, void Function(String?) onChanged, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
