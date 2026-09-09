import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/school_settings.dart';
import 'package:jayasha_childrens_academy/core/repositories/school_repository.dart';

class SchoolSettingsPage extends StatefulWidget {
  const SchoolSettingsPage({super.key});

  @override
  State<SchoolSettingsPage> createState() => _SchoolSettingsPageState();
}

class _SchoolSettingsPageState extends State<SchoolSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late Future<SchoolSettings> _settingsFuture;
  SchoolSettings? _settings;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _affiliationController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final repo = Provider.of<SchoolRepository>(context, listen: false);
    _settingsFuture = repo.getSettings().then((settings) {
      setState(() {
        _settings = settings;
        _nameController.text = settings.schoolName;
        _addressController.text = settings.address;
        _phoneController.text = settings.phone;
        _emailController.text = settings.email;
        _websiteController.text = settings.website;
        _affiliationController.text = settings.affiliationNumber;
        _codeController.text = settings.schoolCode;
      });
      return settings;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = Provider.of<SchoolRepository>(context, listen: false);
      final updatedSettings = _settings!.copyWith(
        schoolName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        affiliationNumber: _affiliationController.text,
        schoolCode: _codeController.text,
      );

      await repo.updateSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully'), backgroundColor: Colors.green),
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
      body: FutureBuilder<SchoolSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'School Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update your school branding and contact information.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  _buildSection(
                    'Basic Information',
                    [
                      _buildTextField('School Name', _nameController, isRequired: true),
                      _buildTextField('Full Address', _addressController, isRequired: true, maxLines: 2),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSection(
                    'Contact Details',
                    [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Phone Number', _phoneController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Email Address', _emailController)),
                        ],
                      ),
                      _buildTextField('Website URL', _websiteController),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSection(
                    'Legal & Affiliation',
                    [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Affiliation Number', _affiliationController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('School Code', _codeController)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: isRequired ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _affiliationController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
