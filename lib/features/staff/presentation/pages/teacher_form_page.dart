import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/features/auth/data/repositories/onboarding_repository_impl.dart';

class TeacherFormPage extends StatefulWidget {
  final Teacher? teacher;
  final VoidCallback onSave;

  const TeacherFormPage({
    super.key,
    this.teacher,
    required this.onSave,
  });

  @override
  State<TeacherFormPage> createState() => _TeacherFormPageState();
}

class _TeacherFormPageState extends State<TeacherFormPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  bool _isLoading = false;
  final _uploadRepo = OnboardingRepositoryImpl();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  final _formKey5 = GlobalKey<FormState>();

  // Page 1: Basic Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String _maritalStatus = 'Single';
  String _gender = 'Female';
  final _addressController = TextEditingController();

  // Page 2: Professional Info
  final _dojController = TextEditingController();
  final _departmentController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  String _status = 'Active';

  // Page 4: Salary & Emergency (New Page)
  final _baseSalaryController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Page 3: Teaching Info
  final List<String> _availableSubjects = ['Maths', 'Science', 'English', 'Hindi', 'Social Studies', 'Computer', 'Art', 'Sanskrit', 'Physical Education', 'Other'];
  final List<String> _selectedSubjects = [];
  final _otherSubjectController = TextEditingController();

  final List<String> _availableClasses = ['Nursery', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _selectedClasses = [];
  final Map<String, TextEditingController> _classSectionsControllers = {};

  bool _isClassTeacher = false;
  String? _classTeacherClass;
  final _classTeacherSectionController = TextEditingController();

  File? _imageFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  String? _existingPhotoUrl;
  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _loadTeacherData(widget.teacher!);
    }
  }

  void _loadTeacherData(Teacher teacher) {
    _nameController.text = teacher.name;
    _emailController.text = teacher.email;
    _phoneController.text = teacher.phone;
    _dobController.text = teacher.dob;
    _maritalStatus = teacher.maritalStatus;
    _gender = teacher.gender;
    _addressController.text = teacher.address;
    _dojController.text = teacher.dateOfJoining;
    _departmentController.text = teacher.department;
    _qualificationController.text = teacher.qualification;
    _experienceController.text = teacher.experience;
    _status = teacher.status[0].toUpperCase() + teacher.status.substring(1);

    _baseSalaryController.text = teacher.baseSalary.toString();
    _bankNameController.text = teacher.bankDetails?.bankName ?? '';
    _accountNumberController.text = teacher.bankDetails?.accountNumber ?? '';
    _ifscCodeController.text = teacher.bankDetails?.ifscCode ?? '';
    _branchNameController.text = teacher.bankDetails?.branchName ?? '';
    _emergencyNameController.text = teacher.emergencyContact?.name ?? '';
    _emergencyPhoneController.text = teacher.emergencyContact?.phone ?? '';
    _emergencyRelationController.text = teacher.emergencyContact?.relation ?? '';

    _selectedSubjects.addAll(teacher.subjects.where((s) => _availableSubjects.contains(s)));
    final otherSubjects = teacher.subjects.where((s) => !_availableSubjects.contains(s)).toList();
    if (otherSubjects.isNotEmpty) {
      _selectedSubjects.add('Other');
      _otherSubjectController.text = otherSubjects.join(', ');
    }

    for (var cls in teacher.classesTeaching) {
      _selectedClasses.add(cls);
      _classSectionsControllers[cls] = TextEditingController();
      final sections = teacher.sections
          .where((s) => s.startsWith('$cls-'))
          .map((s) => s.replaceFirst('$cls-', ''))
          .join(', ');
      _classSectionsControllers[cls]!.text = sections;
    }

    _isClassTeacher = teacher.isClassTeacher;
    _classTeacherClass = teacher.classTeacherOfClass;
    _classTeacherSectionController.text = teacher.classTeacherOfSection ?? '';

    _existingPhotoUrl = teacher.photoPath;
    _existingAadhaarFrontUrl = teacher.aadhaarFrontPath;
    _existingAadhaarBackUrl = teacher.aadhaarBackPath;
  }

  Future<void> _pickImage(bool isProfile, {bool isFront = true}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _imageFile = File(pickedFile.path);
          } else if (isFront) {
            _aadhaarFrontFile = File(pickedFile.path);
          } else {
            _aadhaarBackFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _dojController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _otherSubjectController.dispose();
    _baseSalaryController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _branchNameController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _classTeacherSectionController.dispose();
    for (var controller in _classSectionsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isDOB = false}) async {
    DateTime initialDate;
    final existingDate = _parseDate(controller.text);
    if (existingDate != null) {
      initialDate = existingDate;
    } else {
      initialDate = isDOB
          ? DateTime.now().subtract(const Duration(days: 365 * 25))
          : DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        if (!isDOB) {
          _calculateExperience(picked);
        }
      });
    }
  }

  void _calculateExperience(DateTime joiningDate) {
    final now = DateTime.now();
    int years = now.year - joiningDate.year;
    int months = now.month - joiningDate.month;

    if (months < 0 || (months == 0 && now.day < joiningDate.day)) {
      years--;
      months += 12;
    }

    if (years < 0) {
      _experienceController.text = "0 months";
      return;
    }

    if (years == 0) {
      _experienceController.text = "$months months";
    } else {
      _experienceController.text = "$years years, $months months";
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return null;
    }
  }

  Future<void> _nextPage() async {
    bool isValid = false;
    if (_currentPage == 0) {
      isValid = _formKey1.currentState!.validate();
      if (isValid && _dobController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
        isValid = false;
      }
    } else if (_currentPage == 1) {
      isValid = _formKey2.currentState!.validate();
      if (isValid) {
        if (_dojController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Joining')));
          isValid = false;
        } else {
          final dob = _parseDate(_dobController.text);
          final doj = _parseDate(_dojController.text);
          if (dob != null && doj != null) {
            final ageAtJoining = doj.year - dob.year - ((doj.month < dob.month || (doj.month == dob.month && doj.day < dob.day)) ? 1 : 0);
            if (ageAtJoining < 18) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Difference between DOB and Date of Joining must be at least 18 years.'),
                  backgroundColor: AppColors.error,
                ),
              );
              isValid = false;
            }
          }
        }
      }
    } else if (_currentPage == 2) {
      isValid = _formKey3.currentState!.validate();
      if (isValid && _selectedSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one subject')));
        isValid = false;
      }
    } else if (_currentPage == 3) {
      isValid = _formKey4.currentState!.validate();
    }

    if (isValid) {
      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        await _submitForm();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.teacher == null ? "Add New Teacher" : "Edit Teacher"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getStepTitle(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(
                              "Step ${_currentPage + 1} of $_totalPages",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const Divider(height: 40),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        children: [
                          Form(key: _formKey1, child: _buildPersonalStep()),
                          Form(key: _formKey2, child: _buildProfessionalStep()),
                          Form(key: _formKey3, child: _buildTeachingStep()),
                          Form(key: _formKey4, child: _buildSalaryEmergencyStep()),
                          _buildScheduleViewStep(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Back"),
                          )
                        else
                          const SizedBox.shrink(),
                        ElevatedButton(
                          onPressed: () => _nextPage(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_currentPage == _totalPages - 1
                              ? (widget.teacher == null ? "Save Teacher" : "Update Teacher")
                              : "Next Step"),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0: return "Personal Information";
      case 1: return "Professional Details";
      case 2: return "Teaching Assignment";
      case 3: return "Salary & Emergency Contact";
      case 4: return "Current Schedule (Read-only)";
      default: return "";
    }
  }

  Widget _buildPersonalStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) as ImageProvider : null),
                  child: (_imageFile == null && _existingPhotoUrl == null)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                "Full Name",
                _nameController,
                Icons.person_outline,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                "Email Address",
                _emailController,
                Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) return 'Invalid email';
                  return null;
                },
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                "Phone Number",
                _phoneController,
                Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Invalid phone (10 digits)';
                  return null;
                },
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker("Date of Birth", _dobController, isDOB: true)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown("Gender", ["Male", "Female", "Other"], _gender, (v) => setState(() => _gender = v!))),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown("Marital Status", ["Single", "Married", "Widowed", "Divorced"], _maritalStatus, (v) => setState(() => _maritalStatus = v!))),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Aadhaar Card Photos", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAadhaarPicker("Front Side", _aadhaarFrontFile, _existingAadhaarFrontUrl, () => _pickImage(false, isFront: true)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAadhaarPicker("Back Side", _aadhaarBackFile, _existingAadhaarBackUrl, () => _pickImage(false, isFront: false)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Residential Address", _addressController, Icons.home_outlined, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildProfessionalStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDatePicker("Date of Joining", _dojController, isDOB: false)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Department", _departmentController, Icons.business_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Highest Qualification", _qualificationController, Icons.school_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Years of Experience (Auto-calculated)", _experienceController, Icons.work_history_outlined, readOnly: true)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown("Status", ["Active", "Inactive"], _status, (v) => setState(() => _status = v!)),
        ],
      ),
    );
  }

  Widget _buildTeachingStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Subjects", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableSubjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) _selectedSubjects.add(subject);
                    else _selectedSubjects.remove(subject);
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          if (_selectedSubjects.contains('Other')) ...[
            const SizedBox(height: 16),
            _buildTextField(
              "Specify Other Subject(s)",
              _otherSubjectController,
              Icons.edit_note,
              hint: "Enter subjects separated by comma",
            ),
          ],
          const SizedBox(height: 24),
          const Text("Select Classes & Specify Sections", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text("Tap a class to select it, then optionally add sections (e.g. A, B).", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableClasses.map((cls) {
              final isSelected = _selectedClasses.contains(cls);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: Text(cls),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedClasses.add(cls);
                          _classSectionsControllers[cls] = TextEditingController();
                        } else {
                          _selectedClasses.remove(cls);
                          _classSectionsControllers.remove(cls)?.dispose();
                        }
                      });
                    },
                    selectedColor: AppColors.accent.withOpacity(0.2),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_selectedClasses.isNotEmpty) ...[
            const Text("Sections for Selected Classes:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ..._selectedClasses.map((cls) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Class $cls", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _classSectionsControllers[cls],
                      decoration: InputDecoration(
                        hintText: "Sections (e.g. A, B) - Optional",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Is this teacher a Class Teacher?", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isClassTeacher,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _isClassTeacher = value),
                ),
                if (_isClassTeacher) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown("Class Teacher Of (Class)", _availableClasses, _classTeacherClass ?? _availableClasses.first, (v) => setState(() => _classTeacherClass = v))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField("Class Teacher Of (Section)", _classTeacherSectionController, Icons.label_important_outline)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSalaryEmergencyStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Financial Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 16),
            _buildTextField("Base Salary (Monthly)", _baseSalaryController, Icons.currency_rupee, hint: "Enter monthly base salary"),
            const SizedBox(height: 24),
            const Text("Bank Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildTextField("Bank Name", _bankNameController, Icons.account_balance_outlined, validator: (v) => null),
            const SizedBox(height: 16),
            _buildTextField("Account Number", _accountNumberController, Icons.numbers, validator: (v) => null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                  "IFSC Code",
                  _ifscCodeController,
                  Icons.code,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v)) return 'Invalid IFSC';
                    return null;
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Branch Name", _branchNameController, Icons.location_city, validator: (v) => null)),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Emergency Contact", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 16),
            _buildTextField("Contact Person Name", _emergencyNameController, Icons.person_add_alt, validator: (v) => null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                  "Emergency Phone",
                  _emergencyPhoneController,
                  Icons.phone_android,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Invalid phone (10 digits)';
                    return null;
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Relation", _emergencyRelationController, Icons.family_restroom, validator: (v) => null)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildScheduleViewStep() {
    final schedule = widget.teacher?.schedule ?? [];
    if (schedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No classes scheduled yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            Text('Schedule is managed via Classes Timetable', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final Map<int, List<TeacherScheduleEntry>> groupedSchedule = {};
    for (var entry in schedule) {
      groupedSchedule.putIfAbsent(entry.day, () => []).add(entry);
    }
    for (var dayEntries in groupedSchedule.values) {
      dayEntries.sort((a, b) => a.period.compareTo(b.period));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Assigned Weekly Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text("This schedule is synchronized from the class timetables and is read-only here.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),
          ...days.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final dayName = entry.value;
            final dayEntries = groupedSchedule[dayIndex] ?? [];

            if (dayEntries.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: dayEntries.map((e) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Period ${e.period + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(e.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(e.subject, style: const TextStyle(fontSize: 13, color: AppColors.primary)),
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

  Future<void> _submitForm() async {
    final List<String> finalSubjects = List.from(_selectedSubjects);
    if (finalSubjects.contains('Other')) {
      finalSubjects.remove('Other');
      final otherText = _otherSubjectController.text.trim();
      if (otherText.isNotEmpty) {
        finalSubjects.addAll(otherText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }

    final List<String> allSections = [];
    for (var cls in _selectedClasses) {
      final sectionText = _classSectionsControllers[cls]?.text ?? '';
      if (sectionText.isNotEmpty) {
        final sections = sectionText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (var s in sections) {
          allSections.add("$cls-$s");
        }
      } else {
        allSections.add(cls); // Just the class if no section specified
      }
    }

    setState(() => _isLoading = true);
    String? photoUrl = _existingPhotoUrl;
    String? aadhaarFrontUrl = _existingAadhaarFrontUrl;
    String? aadhaarBackUrl = _existingAadhaarBackUrl;

    try {
      final uploadTasks = <Future<String?>>[];

      if (_imageFile != null) {
        uploadTasks.add(_uploadRepo.uploadFile(_imageFile!.path, 'teacher_photo'));
      } else {
        uploadTasks.add(Future.value(_existingPhotoUrl));
      }

      if (_aadhaarFrontFile != null) {
        uploadTasks.add(_uploadRepo.uploadFile(_aadhaarFrontFile!.path, 'teacher_aadhaar_front'));
      } else {
        uploadTasks.add(Future.value(_existingAadhaarFrontUrl));
      }

      if (_aadhaarBackFile != null) {
        uploadTasks.add(_uploadRepo.uploadFile(_aadhaarBackFile!.path, 'teacher_aadhaar_back'));
      } else {
        uploadTasks.add(Future.value(_existingAadhaarBackUrl));
      }

      final urls = await Future.wait(uploadTasks);
      photoUrl = urls[0];
      aadhaarFrontUrl = urls[1];
      aadhaarBackUrl = urls[2];
    } catch (e) {
      debugPrint("Error uploading teacher files: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File upload failed. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final staffRepo = Provider.of<StaffRepository>(context, listen: false);

    // Conflict check for Class Teacher
    if (_isClassTeacher) {
      final existingTeachers = staffRepo.teachers;
      final duplicate = existingTeachers.firstWhere(
        (t) =>
            t.id != widget.teacher?.id &&
            t.isClassTeacher &&
            t.classTeacherOfClass == _classTeacherClass &&
            t.classTeacherOfSection?.trim().toLowerCase() == _classTeacherSectionController.text.trim().toLowerCase(),
        orElse: () => Teacher(
          name: '',
          gender: '',
          email: '',
          phone: '',
          subjects: [],
          dob: '',
          maritalStatus: '',
          address: '',
          dateOfJoining: '',
          department: '',
          qualification: '',
          experience: '',
          status: '',
          classesTeaching: [],
          sections: [],
          isClassTeacher: false,
        ),
      );

      if (duplicate.name.isNotEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${duplicate.name} is already the class teacher for $_classTeacherClass-${_classTeacherSectionController.text}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    // Duplicate check for Email/Phone
    final existingTeachers = staffRepo.teachers;
    final isDuplicate = existingTeachers.any((t) =>
        t.id != widget.teacher?.id &&
        (t.email.toLowerCase() == _emailController.text.trim().toLowerCase() || t.phone == _phoneController.text.trim()));

    if (isDuplicate) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: A teacher with this email or phone number already exists.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final teacher = Teacher(
      id: widget.teacher?.id,
      name: _nameController.text.trim(),
      gender: _gender,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      subjects: finalSubjects,
      dob: _dobController.text,
      photoPath: photoUrl,
      aadhaarFrontPath: aadhaarFrontUrl,
      aadhaarBackPath: aadhaarBackUrl,
      maritalStatus: _maritalStatus,
      address: _addressController.text.trim(),
      dateOfJoining: _dojController.text,
      department: _departmentController.text.trim(),
      qualification: _qualificationController.text.trim(),
      experience: _experienceController.text.trim(),
      status: _status.toLowerCase(),
      classesTeaching: _selectedClasses,
      sections: allSections,
      isClassTeacher: _isClassTeacher,
      classTeacherOfClass: _isClassTeacher ? (_classTeacherClass ?? _availableClasses.first) : null,
      classTeacherOfSection: _isClassTeacher ? _classTeacherSectionController.text.trim() : null,
      baseSalary: double.tryParse(_baseSalaryController.text) ?? 0.0,
      bankDetails: BankDetails(
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
        branchName: _branchNameController.text.trim(),
      ),
      emergencyContact: EmergencyContact(
        name: _emergencyNameController.text.trim(),
        phone: _emergencyPhoneController.text.trim(),
        relation: _emergencyRelationController.text.trim(),
      ),
      schedule: widget.teacher?.schedule ?? [],
    );

    bool success;
    if (widget.teacher == null) {
      success = await staffRepo.addTeacher(teacher);
    } else {
      success = await staffRepo.updateTeacher(widget.teacher!.id!, teacher);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.teacher == null ? 'Teacher added successfully' : 'Teacher updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving teacher details'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildAadhaarPicker(String label, File? file, String? existingUrl, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: (file != null || existingUrl != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : Image.network(existingUrl!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 24),
                      const SizedBox(height: 4),
                      const Text("Upload", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, String? hint, Function(String)? onChanged, String? Function(String?)? validator, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          validator: validator ?? (value) => value == null || value.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller, {bool isDOB = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context, controller, isDOB: isDOB),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: "DD/MM/YYYY",
            prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}
