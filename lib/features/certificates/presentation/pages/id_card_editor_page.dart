import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/features/settings/data/repositories/school_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';

class IdCardEditorPage extends StatefulWidget {
  final StudentAdmission student;
  final Map<String, dynamic>? certificateData;

  const IdCardEditorPage({super.key, required this.student, this.certificateData});

  @override
  State<IdCardEditorPage> createState() => _IdCardEditorPageState();
}

class _IdCardEditorPageState extends State<IdCardEditorPage> {
  String _schoolName = '';
  String _schoolAddress = '';
  String _principalName = 'Principal';
  String _signatureLabel = 'Principal Signature';

  Map<String, dynamic> _schoolNameStyle = {
    'bold': true, 'italic': false, 'underline': false, 'color': 0xFF0D47A1, 'fontSize': 16.0, 'align': 'center',
  };
  Map<String, dynamic> _addressStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF666666, 'fontSize': 10.0, 'enabled': true, 'align': 'center',
  };

  static const List<double> _fontSizeOptions = [7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 24];
  bool _isSaving = false;

  // Card specific overrides & layout
  String? _cardPhotoOverride;
  double _photoBoxSize = 70.0;
  double _rowSpacing = 3.0;
  double _watermarkOpacity = 0.05;
  double _horizontalPadding = 16.0;
  double _verticalPadding = 8.0;

  Map<String, dynamic> _detailsBlockStyle = {
    'fontSize': 10.0,
    'labelFontSize': 7.0,
    'bold': false,
    'color': 0xFF000000,
  };
  Map<String, dynamic> _studentNameStyle = {
    'bold': true, 'italic': false, 'color': 0xFF000000, 'fontSize': 12.0,
  };
  Map<String, dynamic> _principalNameStyle = {
    'bold': true, 'italic': false, 'color': 0xFF000000, 'fontSize': 6.0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() async {
    final schoolRepo = Provider.of<SchoolRepository>(context, listen: false);
    final onboardingRepo = Provider.of<OnboardingRepository>(context, listen: false);

    // 1. Ensure school details are loaded
    if (schoolRepo.schoolDetails == null) {
      await schoolRepo.fetchSchoolDetails();
    }
    final school = schoolRepo.schoolDetails;

    // 2. Fetch principal name for new cards
    String? fetchedPrincipalName;
    if (widget.certificateData == null) {
      final principal = await onboardingRepo.getPrincipalProfileFromServer();
      if (principal != null) {
        fetchedPrincipalName = principal.name;
      }
    }

    if (!mounted) return;

    setState(() {
      if (widget.certificateData != null) {
        _loadCertificateData();
      }

      if (fetchedPrincipalName != null) {
        _principalName = fetchedPrincipalName;
      }

      // 3. Fallback/Update from school details if values are still empty or default
      if (school != null) {
        if (_schoolName.isEmpty || _schoolName == 'JAYASHA CHILDREN\'S ACADEMY') {
          _schoolName = school.schoolName;
        }
        if (_schoolAddress.isEmpty || _schoolAddress == 'Shivpuri, Madhya Pradesh') {
          _schoolAddress = school.address;
        }
        if (_signatureLabel == 'Principal Signature') {
          _signatureLabel = "Principal";
        }
      }
    });
  }

  void _loadCertificateData() {
    final details = widget.certificateData!['details'] ?? {};
    _schoolName = details['schoolName'] ?? 'JAYASHA CHILDREN\'S ACADEMY';
    _schoolAddress = details['schoolAddress'] ?? '';
    _schoolNameStyle = _mergeStyle(_schoolNameStyle, details['schoolNameStyle']);
    _addressStyle = _mergeStyle(_addressStyle, details['addressStyle']);

    _cardPhotoOverride = details['cardPhotoOverride'];
    _photoBoxSize = (details['photoBoxSize'] ?? 70.0).toDouble();
    _rowSpacing = (details['rowSpacing'] ?? 3.0).toDouble();
    _watermarkOpacity = (details['watermarkOpacity'] ?? 0.05).toDouble();
    _horizontalPadding = (details['horizontalPadding'] ?? 16.0).toDouble();
    _verticalPadding = (details['verticalPadding'] ?? 8.0).toDouble();
    _principalName = details['principalName'] ?? 'Principal';
    _signatureLabel = details['signatureLabel'] ?? 'Principal Signature';
    _detailsBlockStyle = _mergeStyle(_detailsBlockStyle, details['detailsBlockStyle']);
    _studentNameStyle = _mergeStyle(_studentNameStyle, details['studentNameStyle']);
    _principalNameStyle = _mergeStyle(_principalNameStyle, details['principalNameStyle']);
  }

  Map<String, dynamic> _mergeStyle(Map<String, dynamic> defaults, dynamic saved) {
    if (saved == null) return Map<String, dynamic>.from(defaults);
    final merged = Map<String, dynamic>.from(defaults);
    merged.addAll(Map<String, dynamic>.from(saved));
    return merged;
  }

  Map<String, dynamic> _buildDetailsPayload() {
    return {
      'schoolName': _schoolName,
      'schoolAddress': _schoolAddress,
      'schoolNameStyle': _schoolNameStyle,
      'addressStyle': _addressStyle,
      'studentName': widget.student.name,
      'className': widget.student.className ?? 'N/A',
      'section': widget.student.section ?? 'N/A',
      'rollNumber': widget.student.rollNumber ?? 'Not Assigned',
      'photoPath': widget.student.photoPath,
      'issueDate': widget.certificateData?['issueDate'] ?? DateTime.now().toIso8601String(),
      'cardPhotoOverride': _cardPhotoOverride,
      'photoBoxSize': _photoBoxSize,
      'rowSpacing': _rowSpacing,
      'watermarkOpacity': _watermarkOpacity,
      'horizontalPadding': _horizontalPadding,
      'verticalPadding': _verticalPadding,
      'principalName': _principalName,
      'signatureLabel': _signatureLabel,
      'detailsBlockStyle': _detailsBlockStyle,
      'studentNameStyle': _studentNameStyle,
      'principalNameStyle': _principalNameStyle,
    };
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final details = _buildDetailsPayload();

    try {
      final certRepo = Provider.of<CertificateRepository>(context, listen: false);
      Map<String, dynamic> response;

      if (widget.certificateData == null) {
        response = await certRepo.generateCertificate(
          studentId: widget.student.id!,
          type: 'Identity Card',
          details: details,
        );
      } else {
        response = await certRepo.updateCertificate(
          certificateId: widget.certificateData!['_id'],
          type: 'Identity Card',
          details: details,
        );
      }

      if (response['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Card saved successfully'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response['message']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Generates the ID card as a PDF and always prompts the user with a
  /// native "Save As" dialog so they choose the destination each time.
  Future<void> _printCard() async {
    final schoolRepo = Provider.of<SchoolRepository>(context, listen: false);

    try {
      final fileName = 'ID_Card_${widget.student.admissionNumber}.pdf';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ID Card As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // User cancelled the save dialog — do nothing, no error.
      if (outputFile == null) return;

      setState(() => _isSaving = true);

      await PdfGenerator.downloadIdCard(
        student: widget.student,
        details: _buildDetailsPayload(),
        schoolDetails: schoolRepo.schoolDetails,
        savePath: outputFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID Card saved to: $outputFile'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadCardPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload/photo'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('photo', image.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _cardPhotoOverride = data['url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card photo updated locally for this card'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.certificateData == null ? 'Generate ID Card' : 'Edit ID Card'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isSaving ? null : _printCard,
            tooltip: 'Save ID Card as PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Editor Form
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('School Information'),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'School Name', (val) => setState(() => _schoolName = val), _schoolName,
                      _schoolNameStyle, (s) => setState(() => _schoolNameStyle = s),
                      showAlign: true,
                    ),
                    const SizedBox(height: 24),
                    _buildStyleableInput(
                      'School Address', (val) => setState(() => _schoolAddress = val), _schoolAddress,
                      _addressStyle, (s) => setState(() => _addressStyle = s),
                      removable: true, showAlign: true,
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader('Layout & Photo'),
                    const SizedBox(height: 16),
                    _buildPhotoControls(),
                    const SizedBox(height: 24),
                    _buildLayoutControls(),
                    const Divider(height: 48),
                    _buildSectionHeader('Signature & Details'),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Principal Name', (val) => setState(() => _principalName = val), _principalName,
                      _principalNameStyle, (s) => setState(() => _principalNameStyle = s),
                    ),
                    const SizedBox(height: 16),
                    const Text('Signature Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: (val) => setState(() => _signatureLabel = val),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      controller: TextEditingController(text: _signatureLabel)
                        ..selection = TextSelection.fromPosition(TextPosition(offset: _signatureLabel.length)),
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader('Student Details Styling'),
                    const SizedBox(height: 16),
                    const Text('Name Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _buildStyleControls('Student Name', _studentNameStyle, (s) => setState(() => _studentNameStyle = s)),
                    const SizedBox(height: 24),
                    const Text('Other Details Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _buildStyleControls('Details', _detailsBlockStyle, (s) => setState(() => _detailsBlockStyle = s)),
                    const Divider(height: 48),
                    _buildSectionHeader('Student Info (Read-only)'),
                    const SizedBox(height: 16),
                    _buildReadOnlyField('Student Name', widget.student.name),
                    _buildReadOnlyField('Class & Section', '${widget.student.className ?? 'N/A'} - ${widget.student.section ?? 'N/A'}'),
                    _buildReadOnlyField('Roll Number', widget.student.rollNumber ?? 'Not Assigned'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.certificateData == null ? 'Save ID Card' : 'Update ID Card'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right Side: Live Preview
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade200,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AspectRatio(
                      aspectRatio: 85.6 / 53.98, // CR80 standard
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildLivePreview(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStyleableInput(
    String label,
    Function(String)? onTextChanged,
    String? initialValue,
    Map<String, dynamic> style,
    Function(Map<String, dynamic>) onStyleChanged, {
    bool removable = false,
    bool showAlign = false,
  }) {
    final bool isEnabled = (style['enabled'] ?? true) as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            if (removable)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnabled ? 'Shown' : 'Hidden',
                    style: TextStyle(fontSize: 12, color: isEnabled ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: isEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) => _updateStyle(style, 'enabled', val, onStyleChanged),
                  ),
                ],
              ),
          ],
        ),
        if (isEnabled) ...[
          const SizedBox(height: 4),
          TextField(
            onChanged: onTextChanged,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            controller: TextEditingController(text: initialValue)
              ..selection = TextSelection.fromPosition(TextPosition(offset: initialValue?.length ?? 0)),
          ),
          const SizedBox(height: 8),
          _buildStyleControls(label, style, onStyleChanged, showAlign: showAlign),
        ],
      ],
    );
  }

  Widget _buildStyleControls(String label, Map<String, dynamic> style, Function(Map<String, dynamic>) onStyleChanged, {bool showAlign = false}) {
    final double currentSize = _nearestFontSize((style['fontSize'] ?? 12.0).toDouble());

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ToggleButton(icon: Icons.format_bold, isSelected: style['bold'] ?? false, onTap: () => _toggleStyle(style, 'bold', onStyleChanged)),
        _ToggleButton(icon: Icons.format_italic, isSelected: style['italic'] ?? false, onTap: () => _toggleStyle(style, 'italic', onStyleChanged)),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _pickColor(label, style, (color) => _updateStyle(style, 'color', color, onStyleChanged)),
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: Color(style['color'] ?? 0xFF000000), border: Border.all(color: Colors.grey), shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<double>(
          value: currentSize,
          underline: const SizedBox(),
          isDense: true,
          items: _fontSizeOptions
              .map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()}px')))
              .toList(),
          onChanged: (val) {
            if (val != null) _updateStyle(style, 'fontSize', val, onStyleChanged);
          },
        ),
        if (showAlign) ...[
          const SizedBox(width: 4),
          _AlignButton(icon: Icons.format_align_left, isSelected: style['align'] == 'left', onTap: () => _updateStyle(style, 'align', 'left', onStyleChanged)),
          _AlignButton(icon: Icons.format_align_center, isSelected: style['align'] == 'center', onTap: () => _updateStyle(style, 'align', 'center', onStyleChanged)),
          _AlignButton(icon: Icons.format_align_right, isSelected: style['align'] == 'right', onTap: () => _updateStyle(style, 'align', 'right', onStyleChanged)),
        ]
      ],
    );
  }

  double _nearestFontSize(double value) {
    return _fontSizeOptions.reduce((a, b) => (a - value).abs() < (b - value).abs() ? a : b);
  }

  void _toggleStyle(Map<String, dynamic> style, String key, Function(Map<String, dynamic>) onChanged) {
    final newStyle = Map<String, dynamic>.from(style);
    newStyle[key] = !(newStyle[key] ?? false);
    onChanged(newStyle);
  }

  void _updateStyle(Map<String, dynamic> style, String key, dynamic value, Function(Map<String, dynamic>) onChanged) {
    final newStyle = Map<String, dynamic>.from(style);
    newStyle[key] = value;
    onChanged(newStyle);
  }

  void _pickColor(String label, Map<String, dynamic> style, Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick Color for $label'),
        content: Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            0xFF000000, 0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5,
            0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50, 0xFF8BC34A,
            0xFFCDDC39, 0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722, 0xFF795548,
          ].map((c) => GestureDetector(
            onTap: () {
              onSelected(c);
              Navigator.pop(context);
            },
            child: Container(width: 35, height: 35, color: Color(c)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildPhotoControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickAndUploadCardPhoto,
              icon: const Icon(Icons.photo_camera, size: 18),
              label: const Text('Replace for this Card'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
            if (_cardPhotoOverride != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _cardPhotoOverride = null),
                child: const Text('Reset to Profile', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Text('Photo Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        Slider(
          value: _photoBoxSize,
          min: 50,
          max: 100,
          onChanged: (val) => setState(() => _photoBoxSize = val),
        ),
      ],
    );
  }

  Widget _buildLayoutControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Watermark Opacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        Slider(
          value: _watermarkOpacity,
          min: 0,
          max: 0.3,
          divisions: 30,
          label: _watermarkOpacity.toStringAsFixed(2),
          onChanged: (val) => setState(() => _watermarkOpacity = val),
        ),
        const SizedBox(height: 16),
        const Text('Horizontal Padding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        Slider(
          value: _horizontalPadding,
          min: 0,
          max: 30,
          onChanged: (val) => setState(() => _horizontalPadding = val),
        ),
        const SizedBox(height: 16),
        const Text('Vertical Padding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        Slider(
          value: _verticalPadding,
          min: 0,
          max: 20,
          onChanged: (val) => setState(() => _verticalPadding = val),
        ),
        const SizedBox(height: 16),
        const Text('Row Spacing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        Slider(
          value: _rowSpacing,
          min: 0,
          max: 10,
          divisions: 10,
          label: _rowSpacing.toStringAsFixed(1),
          onChanged: (val) => setState(() => _rowSpacing = val),
        ),
        const SizedBox(height: 16),
        const Text('Label Font Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        DropdownButton<double>(
          value: _nearestFontSize((_detailsBlockStyle['labelFontSize'] ?? 7.0).toDouble()),
          isDense: true,
          items: _fontSizeOptions.map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()}px'))).toList(),
          onChanged: (val) {
            if (val != null) _updateStyle(_detailsBlockStyle, 'labelFontSize', val, (s) => setState(() => _detailsBlockStyle = s));
          },
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    final bool showAddress = (_addressStyle['enabled'] ?? true) as bool;
    final int schoolColorInt = _schoolNameStyle['color'] ?? 0xFF0D47A1;
    final Color schoolColor = Color(schoolColorInt);
    final Color headerColor = schoolColor.withOpacity(0.1);

    final schoolRepo = Provider.of<SchoolRepository>(context, listen: false);
    final school = schoolRepo.schoolDetails;
    final String? logoUrl = school?.logoUrl;

    return Stack(
      children: [
        // Watermark background
        Center(
          child: Opacity(
            opacity: _watermarkOpacity,
            child: (logoUrl != null && logoUrl.isNotEmpty)
                ? Image.network(logoUrl, width: 150)
                : Icon(Icons.school, size: 150, color: schoolColor),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(bottom: BorderSide(color: schoolColor, width: 2)),
              ),
              child: Row(
                children: [
                  (logoUrl != null && logoUrl.isNotEmpty)
                      ? Image.network(logoUrl, height: 28, width: 28)
                      : Icon(Icons.school, color: schoolColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          child: Text(_schoolName, style: _getPreviewStyle(_schoolNameStyle), textAlign: _getAlign(_schoolNameStyle['align'])),
                        ),
                        if (showAddress)
                          FittedBox(
                            child: Text(_schoolAddress, style: _getPreviewStyle(_addressStyle), textAlign: _getAlign(_addressStyle['align'])),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Middle section (Photo + Details) - vertically centered
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Photo
                    GestureDetector(
                      onTap: _pickAndUploadCardPhoto,
                      child: Container(
                        width: _photoBoxSize,
                        height: _photoBoxSize * 1.25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: schoolColor, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: (_cardPhotoOverride != null || (widget.student.photoPath != null && widget.student.photoPath!.isNotEmpty))
                                  ? Image.network(
                                      _cardPhotoOverride ?? widget.student.photoPath!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40, color: Colors.grey),
                                    )
                                  : const Icon(Icons.person, size: 40, color: Colors.grey),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: schoolColor, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Data
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _cardDataRow('Student Name', widget.student.name, isBold: true, customStyle: _studentNameStyle),
                          SizedBox(height: _rowSpacing * 2),
                          Row(
                            children: [
                              Expanded(child: _cardDataRow('Class', widget.student.className ?? 'N/A')),
                              Expanded(child: _cardDataRow('Section', widget.student.section ?? 'N/A')),
                            ],
                          ),
                          SizedBox(height: _rowSpacing * 2),
                          Row(
                            children: [
                              Expanded(child: _cardDataRow('Roll No', widget.student.rollNumber ?? 'N/A')),
                              Expanded(child: _cardDataRow('Adm No', widget.student.admissionNumber)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CARD ID: ID-${widget.student.admissionNumber}', style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black87)),
                  // Signature
                  Column(
                    children: [
                      Text(_principalName, style: _getPreviewStyle(_principalNameStyle)),
                      Container(width: 60, height: 0.5, color: Colors.black54),
                      const SizedBox(height: 2),
                      Text(_signatureLabel, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardDataRow(String label, String value, {bool isBold = false, Map<String, dynamic>? customStyle}) {
    final style = customStyle ?? _detailsBlockStyle;
    final double labelSize = (_detailsBlockStyle['labelFontSize'] ?? 7.0).toDouble();
    final double valueSize = (style['fontSize'] ?? 10.0).toDouble();
    final bool blockBold = style['bold'] == true;
    final Color textColor = Color(style['color'] ?? 0xFF000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: labelSize, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: (isBold || blockBold) ? FontWeight.bold : FontWeight.w500,
              fontStyle: style['italic'] == true ? FontStyle.italic : FontStyle.normal,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _getPreviewStyle(Map<String, dynamic> style) {
    return TextStyle(
      fontSize: (style['fontSize'] ?? 12.0).toDouble(),
      fontWeight: style['bold'] == true ? FontWeight.bold : FontWeight.normal,
      fontStyle: style['italic'] == true ? FontStyle.italic : FontStyle.normal,
      decoration: style['underline'] == true ? TextDecoration.underline : TextDecoration.none,
      color: Color(style['color'] ?? 0xFF000000),
    );
  }

  TextAlign _getAlign(String? align) {
    switch (align) {
      case 'left': return TextAlign.left;
      case 'right': return TextAlign.right;
      default: return TextAlign.center;
    }
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleButton({required this.icon, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _AlignButton({required this.icon, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}