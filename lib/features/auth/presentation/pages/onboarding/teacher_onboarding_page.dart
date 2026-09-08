import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/onboarding/academic_onboarding_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/onboarding/fee_structure_onboarding_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/widgets/onboarding_progress_header.dart';
import 'package:jayasha_childrens_academy/features/dashboard/presentation/pages/dashboard_page.dart';

class TeacherOnboardingPage extends StatefulWidget {
  const TeacherOnboardingPage({super.key});

  @override
  State<TeacherOnboardingPage> createState() => _TeacherOnboardingPageState();
}

class _TeacherOnboardingPageState extends State<TeacherOnboardingPage> {
  final List<Teacher> _teachers = [];
  final _repository = OnboardingRepositoryImpl();

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddTeacherDialog(),
    ).then((result) {
      if (result != null && result is Teacher) {
        setState(() {
          _teachers.add(result);
        });
      }
    });
  }

  void _removeTeacher(int index) {
    setState(() {
      _teachers.removeAt(index);
    });
  }

  Future<void> _finishOnboarding() async {
    if (_teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one teacher or skip')),
      );
      return;
    }

    await _repository.saveTeachersDetails(_teachers);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeeStructureOnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side - Info/Illustration
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.accent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    "Add Teachers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Build your team by adding teachers who will be using this system.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Side - List
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 40, 60, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(currentStep: 2),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Teacher Management",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FeeStructureOnboardingPage()),
                          );
                        },
                        child: const Text("Skip for now"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Staff List (${_teachers.length})",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTeacherDialog,
                        icon: const Icon(Icons.add),
                        label: const Text("Add New Teacher"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _teachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  "No teachers added yet.\nClick 'Add New Teacher' to begin.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _teachers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: const Icon(Icons.person, color: AppColors.primary),
                                  ),
                                  title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${teacher.department} • ${teacher.subjects.join(", ")}"),
                                      Text(teacher.email, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _removeTeacher(index),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Back", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _finishOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Finalize & Setup Fees", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddTeacherDialog extends StatefulWidget {
  const AddTeacherDialog({super.key});

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;
  bool _isLoading = false;
  final _repository = OnboardingRepositoryImpl();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

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

  // Page 3: Teaching Info
  final List<String> _availableSubjects = ['Maths', 'Science', 'English', 'Hindi', 'Social Studies', 'Computer', 'Art', 'Sanskrit', 'Physical Education', 'Other'];
  final List<String> _selectedSubjects = [];
  final _otherSubjectController = TextEditingController();

  List<String> _availableClasses = [];
  Map<String, List<String>> _classToSectionsMap = {};
  final List<String> _selectedClasses = [];
  final Map<String, List<String>> _selectedSectionsForClasses = {};

  bool _isClassTeacher = false;
  String? _classTeacherClass;
  String? _classTeacherSection;

  File? _imageFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    setState(() => _isLoading = true);
    try {
      final session = await _repository.getAcademicSession();
      if (session != null) {
        setState(() {
          _availableClasses = session.classes.map((c) => c.className).toList();
          _classToSectionsMap = {
            for (var c in session.classes) c.className: c.sections
          };
        });
      }
    } catch (e) {
      debugPrint("Error loading academic data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isDOB = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDOB
          ? DateTime.now().subtract(const Duration(days: 365 * 25))
          : DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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
      if (isValid) {
        if (_dobController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
          isValid = false;
        } else if (_addressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Residential Address')));
          isValid = false;
        }
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
            if (ageAtJoining < 20) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Difference between DOB and Date of Joining must be at least 20 years.'),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 850,
        height: 700,
        padding: const EdgeInsets.all(32),
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
                        const Text("Add New Teacher", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(
                          "Step ${_currentPage + 1} of $_totalPages: ${_getStepTitle()}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                      child: Text(_currentPage == _totalPages - 1 ? "Save Teacher" : "Next Step"),
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
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0: return "Personal Information";
      case 1: return "Professional Details";
      case 2: return "Teaching Assignment";
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
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
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
              Expanded(child: _buildTextField("Full Name", _nameController, Icons.person_outline)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Email Address", _emailController, Icons.email_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Phone Number", _phoneController, Icons.phone_outlined)),
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
                child: _buildAadhaarPicker("Front Side", _aadhaarFrontFile, () => _pickImage(false, isFront: true)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAadhaarPicker("Back Side", _aadhaarBackFile, () => _pickImage(false, isFront: false)),
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
          const Text("Select Classes & Sections", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text("Select classes and sections this teacher will teach.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          if (_availableClasses.isEmpty)
             const Text("No classes found. Please set up academic session first.", style: TextStyle(color: AppColors.error)),
          ..._availableClasses.map((cls) {
            final isClassSelected = _selectedClasses.contains(cls);
            final availableSections = _classToSectionsMap[cls] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterChip(
                  label: Text(cls),
                  selected: isClassSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedClasses.add(cls);
                        _selectedSectionsForClasses[cls] = [];
                      } else {
                        _selectedClasses.remove(cls);
                        _selectedSectionsForClasses.remove(cls);
                        // Reset class teacher if this class was selected
                        if (_classTeacherClass == cls) {
                          _classTeacherClass = null;
                          _classTeacherSection = null;
                        }
                      }
                    });
                  },
                  selectedColor: AppColors.accent.withOpacity(0.2),
                ),
                if (isClassSelected && availableSections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                    child: Wrap(
                      spacing: 8,
                      children: availableSections.map((section) {
                        final isSectionSelected = _selectedSectionsForClasses[cls]?.contains(section) ?? false;
                        return ChoiceChip(
                          label: Text("Section $section"),
                          selected: isSectionSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSectionsForClasses[cls]!.add(section);
                              } else {
                                _selectedSectionsForClasses[cls]!.remove(section);
                                if (_classTeacherClass == cls && _classTeacherSection == section) {
                                  _classTeacherSection = null;
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          }),
          const SizedBox(height: 24),
          if (_selectedClasses.isNotEmpty)
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
                    onChanged: (value) {
                      setState(() {
                        _isClassTeacher = value;
                        if (_isClassTeacher && _selectedClasses.isNotEmpty) {
                          _classTeacherClass ??= _selectedClasses.first;
                          final sections = _selectedSectionsForClasses[_classTeacherClass!];
                          if (sections != null && sections.isNotEmpty) {
                            _classTeacherSection ??= sections.first;
                          }
                        }
                      });
                    },
                  ),
                  if (_isClassTeacher) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            "Class Teacher Of (Class)",
                            _selectedClasses,
                            _classTeacherClass ?? (_selectedClasses.isNotEmpty ? _selectedClasses.first : null),
                            (v) {
                              setState(() {
                                _classTeacherClass = v;
                                final sections = _selectedSectionsForClasses[v!];
                                if (sections != null && sections.isNotEmpty) {
                                  _classTeacherSection = sections.first;
                                } else {
                                  _classTeacherSection = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_classTeacherClass != null && (_selectedSectionsForClasses[_classTeacherClass!]?.isNotEmpty ?? false))
                          Expanded(
                            child: _buildDropdown(
                              "Class Teacher Of (Section)",
                              _selectedSectionsForClasses[_classTeacherClass!]!,
                              _classTeacherSection ?? (_selectedSectionsForClasses[_classTeacherClass!]!.isNotEmpty ? _selectedSectionsForClasses[_classTeacherClass!]!.first : null),
                              (v) => setState(() => _classTeacherSection = v),
                            ),
                          )
                        else if (_classTeacherClass != null)
                          const Expanded(child: Padding(
                            padding: EdgeInsets.only(top: 24.0),
                            child: Text("No sections for this class", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          )),
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
      final sections = _selectedSectionsForClasses[cls] ?? [];
      for (var s in sections) {
        allSections.add("$cls-$s");
      }
    }

    setState(() => _isLoading = true);
    String? photoUrl;
    String? aadhaarFrontUrl;
    String? aadhaarBackUrl;

    try {
      if (_imageFile != null) {
        photoUrl = await _repository.uploadFile(_imageFile!.path, 'teacher_photo');
      }
      if (_aadhaarFrontFile != null) {
        aadhaarFrontUrl = await _repository.uploadFile(_aadhaarFrontFile!.path, 'teacher_aadhaar_front');
      }
      if (_aadhaarBackFile != null) {
        aadhaarBackUrl = await _repository.uploadFile(_aadhaarBackFile!.path, 'teacher_aadhaar_back');
      }
    } catch (e) {
      debugPrint("Error uploading teacher files: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    final teacher = Teacher(
      name: _nameController.text,
      gender: _gender,
      email: _emailController.text,
      phone: _phoneController.text,
      subjects: finalSubjects,
      dob: _dobController.text,
      photoPath: photoUrl,
      aadhaarFrontPath: aadhaarFrontUrl,
      aadhaarBackPath: aadhaarBackUrl,
      maritalStatus: _maritalStatus,
      address: _addressController.text,
      dateOfJoining: _dojController.text,
      department: _departmentController.text,
      qualification: _qualificationController.text,
      experience: _experienceController.text,
      status: _status.toLowerCase(),
      classesTeaching: _selectedClasses,
      sections: allSections,
      isClassTeacher: _isClassTeacher,
      classTeacherOfClass: _isClassTeacher ? (_classTeacherClass ?? (_selectedClasses.isNotEmpty ? _selectedClasses.first : '')) : null,
      classTeacherOfSection: _isClassTeacher ? _classTeacherSection : null,
    );
    Navigator.pop(context, teacher);
  }


  Widget _buildAadhaarPicker(String label, File? file, VoidCallback onTap) {
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
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file, fit: BoxFit.cover),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
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
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
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

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value != null && items.contains(value)) ? value : (items.isNotEmpty ? items.first : null),
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
