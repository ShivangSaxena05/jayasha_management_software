import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/onboarding/academic_onboarding_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/widgets/onboarding_progress_header.dart';

class PrincipalOnboardingPage extends StatefulWidget {
  final Principal? existingPrincipal;
  final VoidCallback? onSave;

  const PrincipalOnboardingPage({
    super.key,
    this.existingPrincipal,
    this.onSave,
  });

  @override
  State<PrincipalOnboardingPage> createState() => _PrincipalOnboardingPageState();
}

class _PrincipalOnboardingPageState extends State<PrincipalOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Form Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  String _maritalStatus = 'Married';

  File? _imageFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  String? _existingPhotoUrl;
  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  final ImagePicker _picker = ImagePicker();

  // Form Keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  final _repository = OnboardingRepositoryImpl();

  @override
  void initState() {
    super.initState();
    if (widget.existingPrincipal != null) {
      _loadPrincipalData(widget.existingPrincipal!);
    }
  }

  void _loadPrincipalData(Principal principal) {
    _nameController.text = principal.name;
    _dobController.text = principal.dob;
    _selectedGender = principal.gender;
    _emailController.text = principal.email;
    _phoneController.text = principal.phone;
    _qualificationController.text = principal.qualification;
    _experienceController.text = principal.experience;
    _addressController.text = principal.address;
    _maritalStatus = principal.maritalStatus;
    _existingPhotoUrl = principal.photoPath;
    _existingAadhaarFrontUrl = principal.aadhaarFrontPath;
    _existingAadhaarBackUrl = principal.aadhaarBackPath;
  }

  Future<void> _nextPage() async {
    bool isValid = false;
    if (_currentPage == 0) {
      isValid = _formKey1.currentState!.validate();
    } else if (_currentPage == 1) {
      isValid = _formKey2.currentState!.validate();
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
        setState(() => _isLoading = true);
        try {
          // Upload files to Cloudinary
          String? photoUrl = _existingPhotoUrl;
          String? aadhaarFrontUrl = _existingAadhaarFrontUrl;
          String? aadhaarBackUrl = _existingAadhaarBackUrl;

          if (_imageFile != null) {
            photoUrl = await _repository.uploadFile(_imageFile!.path, 'principal_photo');
          }
          if (_aadhaarFrontFile != null) {
            aadhaarFrontUrl = await _repository.uploadFile(_aadhaarFrontFile!.path, 'principal_aadhaar_front');
          }
          if (_aadhaarBackFile != null) {
            aadhaarBackUrl = await _repository.uploadFile(_aadhaarBackFile!.path, 'principal_aadhaar_back');
          }

          // Save Principal Data with URLs
          final principal = Principal(
            name: _nameController.text,
            dob: _dobController.text,
            gender: _selectedGender ?? '',
            email: _emailController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            qualification: _qualificationController.text,
            experience: _experienceController.text,
            maritalStatus: _maritalStatus,
            photoPath: photoUrl,
            aadhaarFrontPath: aadhaarFrontUrl,
            aadhaarBackPath: aadhaarBackUrl,
          );

          if (widget.existingPrincipal == null) {
            await _repository.savePrincipalDetails(principal);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AcademicOnboardingPage()),
              );
            }
          } else {
            final success = await _repository.updatePrincipalProfile(principal);
            if (mounted) {
              if (success) {
                if (widget.onSave != null) widget.onSave!();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated successfully")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update profile")),
                );
              }
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error saving details: $e")),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  bool _isLoading = false;

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    await _selectDate(context, _dobController);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side - Info/Illustration
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome Principal",
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
                      "Please complete your profile to set up Jayasha Children's Academy management system.",
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
          // Right Side - Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 40, 60, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(currentStep: 0),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCurrentStepTitle(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AcademicOnboardingPage()),
                          );
                        },
                        child: const Text("Skip for now"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Step ${_currentPage + 1} of $_totalPages",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        Form(key: _formKey1, child: _buildBasicInfo()),
                        Form(key: _formKey2, child: _buildContactInfo()),
                        Form(key: _formKey3, child: _buildProfessionalInfo()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Back"),
                        )
                      else
                        const SizedBox(width: 120), // Placeholder
                      ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_currentPage == _totalPages - 1 ? "Finish Principal Profile" : "Next Step"),
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

  String _getCurrentStepTitle() {
    switch (_currentPage) {
      case 0: return "Personal Details";
      case 1: return "Contact Information";
      case 2: return "Professional Details";
      default: return "";
    }
  }

  Widget _buildBasicInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's start with your basic information", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) as ImageProvider : null),
                  child: (_imageFile == null && _existingPhotoUrl == null)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField("Full Name", _nameController, Icons.person_outline),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Date of Birth", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDOB(context),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gender", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_search_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: ["Male", "Female", "Other"]
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Marital Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _maritalStatus,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.favorite_outline, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: ["Single", "Married", "Widowed", "Divorced"]
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _maritalStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          const Text("Aadhaar Card Photos", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAadhaarPicker("Front Side", _aadhaarFrontFile, _existingAadhaarFrontUrl, () => _pickImage(false, isFront: true)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildAadhaarPicker("Back Side", _aadhaarBackFile, _existingAadhaarBackUrl, () => _pickImage(false, isFront: false)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAadhaarPicker(String label, File? file, String? existingUrl, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
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
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      Text("Upload Photo", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How can we reach you?", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTextField("Email Address", _emailController, Icons.email_outlined),
          const SizedBox(height: 20),
          _buildTextField("Phone Number", _phoneController, Icons.phone_outlined),
          const SizedBox(height: 20),
          _buildTextField("Residential Address", _addressController, Icons.home_outlined, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your academic and professional background", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTextField("Highest Qualification", _qualificationController, Icons.history_edu_outlined),
          const SizedBox(height: 20),
          _buildTextField("Years of Experience", _experienceController, Icons.work_outline),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
