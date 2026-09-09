import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/school_details.dart';
import 'package:jayasha_childrens_academy/features/settings/data/repositories/school_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _affiliationController;
  late TextEditingController _signatureLabelController;

  bool _isSaving = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final school = Provider.of<SchoolRepository>(context, listen: false).schoolDetails;
    _nameController = TextEditingController(text: school?.schoolName ?? '');
    _addressController = TextEditingController(text: school?.address ?? '');
    _phoneController = TextEditingController(text: school?.phone ?? '');
    _emailController = TextEditingController(text: school?.email ?? '');
    _affiliationController = TextEditingController(text: school?.affiliationLine ?? '');
    _signatureLabelController = TextEditingController(text: school?.principalSignatureLabel ?? 'Principal Signature');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _affiliationController.dispose();
    _signatureLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploadingLogo = true);

    try {
      final repo = Provider.of<SchoolRepository>(context, listen: false);
      final logoUrl = await repo.updateLogo(File(image.path));

      if (logoUrl != null && mounted) {
        final currentDetails = repo.schoolDetails ?? SchoolDetails(
          id: '', schoolName: '', address: '', phone: '', email: '',
          affiliationLine: '', logoUrl: '', principalSignatureLabel: ''
        );
        await repo.updateSchoolDetails(currentDetails.copyWith(logoUrl: logoUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload logo'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = Provider.of<SchoolRepository>(context, listen: false);
      final currentDetails = repo.schoolDetails;

      final newDetails = SchoolDetails(
        id: currentDetails?.id ?? '',
        schoolName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        affiliationLine: _affiliationController.text,
        logoUrl: currentDetails?.logoUrl ?? '',
        principalSignatureLabel: _signatureLabelController.text,
      );

      final result = await repo.updateSchoolDetails(newDetails);

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to save settings'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolDetailsSection() {
    final school = Provider.of<SchoolRepository>(context).schoolDetails;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Section
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _isUploadingLogo
                          ? const Center(child: CircularProgressIndicator())
                          : (school?.logoUrl != null && school!.logoUrl.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(school.logoUrl, fit: BoxFit.contain),
                              )
                            : const Icon(Icons.school, size: 60, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                        icon: const Icon(Icons.image),
                        label: const Text('Change Logo'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  // Form Fields
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField('School Name', _nameController),
                        const SizedBox(height: 16),
                        _buildTextField('Address', _addressController, maxLines: 2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Phone', _phoneController)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Email', _emailController)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Affiliation Line', _affiliationController),
                        const SizedBox(height: 16),
                        _buildTextField('Principal Signature Label', _signatureLabelController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save School Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label != 'Affiliation Line') return '$label is required';
        }
        return null;
      },
    );
  }
}
