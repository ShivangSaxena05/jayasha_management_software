import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/school_details.dart';
import 'package:jayasha_childrens_academy/features/settings/data/repositories/school_repository.dart';

class SchoolDetailsPage extends StatefulWidget {
  const SchoolDetailsPage({super.key});

  @override
  State<SchoolDetailsPage> createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _affiliationController;
  late TextEditingController _logoUrlController;
  late TextEditingController _signatureLabelController;

  @override
  void initState() {
    super.initState();
    final school = Provider.of<SchoolRepository>(context, listen: false).schoolDetails;
    _nameController = TextEditingController(text: school?.schoolName ?? '');
    _addressController = TextEditingController(text: school?.address ?? '');
    _phoneController = TextEditingController(text: school?.phone ?? '');
    _emailController = TextEditingController(text: school?.email ?? '');
    _affiliationController = TextEditingController(text: school?.affiliationLine ?? '');
    _logoUrlController = TextEditingController(text: school?.logoUrl ?? '');
    _signatureLabelController = TextEditingController(text: school?.principalSignatureLabel ?? 'Principal Signature');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _affiliationController.dispose();
    _logoUrlController.dispose();
    _signatureLabelController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final schoolRepo = Provider.of<SchoolRepository>(context, listen: false);
    final currentId = schoolRepo.schoolDetails?.id ?? '';

    final details = SchoolDetails(
      id: currentId,
      schoolName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      affiliationLine: _affiliationController.text.trim(),
      logoUrl: _logoUrlController.text.trim(),
      principalSignatureLabel: _signatureLabelController.text.trim(),
    );

    final result = await schoolRepo.updateSchoolDetails(details);

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School details updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update details'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Institution Identity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These details will appear on certificates, ID cards, and reports.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField('School Name', _nameController, Icons.school),
                  const SizedBox(height: 16),
                  _buildTextField('Affiliation Line', _affiliationController, Icons.verified, hint: 'e.g. Affiliated to CBSE, New Delhi'),
                  const SizedBox(height: 16),
                  _buildTextField('Address', _addressController, Icons.location_on, maxLines: 2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Phone', _phoneController, Icons.phone)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Email', _emailController, Icons.email)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Logo URL', _logoUrlController, Icons.image, hint: 'Cloudinary URL'),
                  const SizedBox(height: 16),
                  _buildTextField('Principal Signature Label', _signatureLabelController, Icons.gesture),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
