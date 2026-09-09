import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

class CertificateEditorPage extends StatefulWidget {
  final StudentAdmission? student;
  final Map<String, dynamic>? certificateData;

  const CertificateEditorPage({super.key, this.student, this.certificateData});

  @override
  State<CertificateEditorPage> createState() => _CertificateEditorPageState();
}

class _CertificateEditorPageState extends State<CertificateEditorPage> {
  final _admNoController = TextEditingController();
  StudentAdmission? _student;
  bool _isVerifying = false;

  final List<String> _types = [
    'Transfer Certificate (TC)',
    'Bonafide Certificate',
    'Character Certificate',
    'Custom Certificate'
  ];
  String _selectedType = 'Bonafide Certificate';
  final _customTitleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _schoolName = 'JAYASHA CHILDREN\'S ACADEMY';
  String _subtitle = 'Affiliated to UP Board';
  String _place = 'School Office';
  String _principalLabel = 'Principal Signature';

  // NEW: every style map now carries 'fontSize'. Fields that can be
  // completely removed from the certificate also carry 'enabled' (defaults
  // to true so old, previously-saved certificates still render exactly as
  // before). School Name / Title / Body are treated as mandatory elements
  // and are not removable.
  Map<String, dynamic> _schoolNameStyle = {
    'bold': true, 'italic': false, 'underline': false, 'color': 0xFF0D47A1, 'fontSize': 24.0,
  };
  Map<String, dynamic> _subtitleStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF000000, 'fontSize': 14.0, 'enabled': true,
  };
  Map<String, dynamic> _titleStyle = {
    'bold': true, 'italic': false, 'underline': true, 'color': 0xFF000000, 'fontSize': 20.0,
  };
  Map<String, dynamic> _bodyStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF000000, 'align': 'justify', 'fontSize': 16.0,
  };
  Map<String, dynamic> _dateStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF000000, 'fontSize': 12.0, 'enabled': true,
  };
  Map<String, dynamic> _placeStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF000000, 'fontSize': 12.0, 'enabled': true,
  };
  Map<String, dynamic> _principalLabelStyle = {
    'bold': true, 'italic': false, 'underline': false, 'color': 0xFF000000, 'fontSize': 14.0, 'enabled': true,
  };

  static const List<double> _fontSizeOptions = [10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 40];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.certificateData != null) {
      _loadCertificateData();
    } else if (widget.student != null) {
      _student = widget.student;
      _admNoController.text = _student!.admissionNumber;
      _updateDefaultBody();
    }
  }

  void _loadCertificateData() {
    final data = widget.certificateData!;
    final details = data['details'] ?? {};

    if (data['student'] != null) {
      _student = StudentAdmission.fromJson(data['student']);
      _admNoController.text = _student!.admissionNumber;
    }

    _selectedType = data['type'] ?? 'Bonafide Certificate';
    _customTitleController.text = details['title'] ?? '';
    _bodyController.text = details['body'] ?? '';

    _schoolName = details['schoolName'] ?? 'JAYASHA CHILDREN\'S ACADEMY';
    _subtitle = details['subtitle'] ?? 'Affiliated to CBSE, New Delhi';
    _place = details['place'] ?? 'School Office';
    _principalLabel = details['principalLabel'] ?? 'Principal Signature';

    // Merge saved style on top of the defaults above rather than replacing
    // wholesale, so a certificate saved BEFORE 'fontSize'/'enabled' existed
    // still gets sensible defaults for the new keys instead of nulls.
    _schoolNameStyle = _mergeStyle(_schoolNameStyle, details['schoolNameStyle']);
    _subtitleStyle = _mergeStyle(_subtitleStyle, details['subtitleStyle']);
    _titleStyle = _mergeStyle(_titleStyle, details['titleStyle']);
    _bodyStyle = _mergeStyle(_bodyStyle, details['bodyStyle']);
    _dateStyle = _mergeStyle(_dateStyle, details['dateStyle']);
    _placeStyle = _mergeStyle(_placeStyle, details['placeStyle']);
    _principalLabelStyle = _mergeStyle(_principalLabelStyle, details['principalLabelStyle']);
  }

  Map<String, dynamic> _mergeStyle(Map<String, dynamic> defaults, dynamic saved) {
    if (saved == null) return Map<String, dynamic>.from(defaults);
    final merged = Map<String, dynamic>.from(defaults);
    merged.addAll(Map<String, dynamic>.from(saved));
    return merged;
  }

  void _updateDefaultBody() {
    if (_student == null) return;
    if (widget.certificateData != null) return; // Don't overwrite saved body when editing

    String text = "";
    String name = _student!.name;
    String father = _student!.fatherName;
    String className = _student!.className ?? 'N/A';
    String section = _student!.section ?? 'N/A';
    String dob = DateFormat('dd-MM-yyyy').format(DateTime.parse(_student!.dob));

    if (_selectedType == 'Transfer Certificate (TC)') {
      text = "This is to certify that $name, son/daughter of Mr. $father, was a student of this school. He/She has passed/failed in class $className. All dues to the school have been paid by him/her. His/Her date of birth as per school record is $dob. He/She bears a good moral character.";
    } else if (_selectedType == 'Bonafide Certificate') {
      text = "This is to certify that Master/Miss $name, son/daughter of Mr. $father, is/was a bonafide student of this school studying in class $className section $section. His/Her date of birth according to the school records is $dob.";
    } else if (_selectedType == 'Character Certificate') {
      text = "This is to certify that $name, son/daughter of Mr. $father, has been a student of this school. During this period his/her conduct and character have been found to be Good. We wish him/her success in future life.";
    }

    setState(() {
      _bodyController.text = text;
    });
  }

  Future<void> _verifyStudent() async {
    setState(() => _isVerifying = true);
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final students = await studentRepo.getStudents(admissionNumber: _admNoController.text);
      if (students.isNotEmpty) {
        setState(() {
          _student = students.first;
          _updateDefaultBody();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Map<String, dynamic> _buildDetailsPayload() {
    return {
      'schoolName': _schoolName,
      'subtitle': _subtitle,
      'place': _place,
      'principalLabel': _principalLabel,
      'title': _selectedType == 'Custom Certificate' ? _customTitleController.text : _selectedType,
      'body': _bodyController.text,
      'schoolNameStyle': _schoolNameStyle,
      'subtitleStyle': _subtitleStyle,
      'titleStyle': _titleStyle,
      'bodyStyle': _bodyStyle,
      'dateStyle': _dateStyle,
      'placeStyle': _placeStyle,
      'principalLabelStyle': _principalLabelStyle,
      'issueDate': widget.certificateData?['issueDate'] ?? DateTime.now().toIso8601String(),
    };
  }

  Future<void> _save() async {
    if (_student == null) return;
    setState(() => _isSaving = true);

    final details = _buildDetailsPayload();

    try {
      final certRepo = Provider.of<CertificateRepository>(context, listen: false);
      Map<String, dynamic> response;

      if (widget.certificateData == null) {
        response = await certRepo.generateCertificate(
          studentId: _student!.id!,
          type: _selectedType,
          details: details,
        );
      } else {
        response = await certRepo.updateCertificate(
          certificateId: widget.certificateData!['_id'],
          type: _selectedType,
          details: details,
        );
      }

      if (response['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response['message']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _printCurrent() {
    if (_student == null) return;
    PdfGenerator.printCertificate(
      student: _student!,
      type: _selectedType,
      details: _buildDetailsPayload(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.certificateData == null ? 'Issue New Certificate' : 'Edit Certificate'),
        actions: [
          if (_student != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.print),
                onPressed: _printCurrent,
                tooltip: 'Print Certificate',
              ),
            ),
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
                    _buildSectionHeader('Student Verification'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _admNoController,
                            decoration: const InputDecoration(
                              labelText: 'Admission Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyStudent,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20)),
                          child: _isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify'),
                        ),
                      ],
                    ),
                    if (_student != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text('Student: ${_student!.name} (${_student!.className ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 40),
                    _buildSectionHeader('Certificate Details'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Certificate Type', border: OutlineInputBorder()),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedType = val!;
                          _updateDefaultBody();
                        });
                      },
                    ),
                    if (_selectedType == 'Custom Certificate') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customTitleController,
                        decoration: const InputDecoration(labelText: 'Custom Title', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Body Text', border: OutlineInputBorder()),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildStyleControls('Body Text', _bodyStyle, (newStyle) => setState(() => _bodyStyle = newStyle), showAlign: true),
                    const Divider(height: 40),
                    _buildSectionHeader('Header & Footer Styling'),
                    const SizedBox(height: 4),
                    Text(
                      'Toggle "Shown" off to remove an element from the certificate completely.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'School Name', (val) => setState(() => _schoolName = val), _schoolName,
                      _schoolNameStyle, (s) => setState(() => _schoolNameStyle = s),
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Subtitle', (val) => setState(() => _subtitle = val), _subtitle,
                      _subtitleStyle, (s) => setState(() => _subtitleStyle = s),
                      removable: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Title', null, null,
                      _titleStyle, (s) => setState(() => _titleStyle = s),
                      onlyStyle: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Date', null, null,
                      _dateStyle, (s) => setState(() => _dateStyle = s),
                      onlyStyle: true, removable: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Place', (val) => setState(() => _place = val), _place,
                      _placeStyle, (s) => setState(() => _placeStyle = s),
                      removable: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStyleableInput(
                      'Principal Label', (val) => setState(() => _principalLabel = val), _principalLabel,
                      _principalLabelStyle, (s) => setState(() => _principalLabelStyle = s),
                      removable: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_student == null || _isSaving) ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.certificateData == null ? 'Generate & Issue' : 'Update Certificate'),
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
              padding: const EdgeInsets.all(48),
              child: Center(
                child: SingleChildScrollView(
                  child: AspectRatio(
                    aspectRatio: 1 / 1.414,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
                      ),
                      padding: const EdgeInsets.all(40),
                      child: _buildLivePreview(),
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

  /// [removable] adds a "Shown / Hidden" switch next to the label. When
  /// toggled off, the field's input + style controls collapse and the
  /// element is fully excluded from the live preview (and, once
  /// PdfGenerator is updated to match, the printed PDF too).
  Widget _buildStyleableInput(
    String label,
    Function(String)? onTextChanged,
    String? initialValue,
    Map<String, dynamic> style,
    Function(Map<String, dynamic>) onStyleChanged, {
    bool onlyStyle = false,
    bool removable = false,
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
          if (!onlyStyle) ...[
            const SizedBox(height: 4),
            TextField(
              onChanged: onTextChanged,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              controller: TextEditingController(text: initialValue)
                ..selection = TextSelection.fromPosition(TextPosition(offset: initialValue?.length ?? 0)),
            ),
          ],
          const SizedBox(height: 8),
          _buildStyleControls(label, style, onStyleChanged),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'This element will not appear on the certificate.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildStyleControls(String label, Map<String, dynamic> style, Function(Map<String, dynamic>) onStyleChanged, {bool showAlign = false}) {
    final double currentSize = _nearestFontSize((style['fontSize'] ?? 16.0).toDouble());

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ToggleButton(icon: Icons.format_bold, isSelected: style['bold'] ?? false, onTap: () => _toggleStyle(style, 'bold', onStyleChanged)),
        _ToggleButton(icon: Icons.format_italic, isSelected: style['italic'] ?? false, onTap: () => _toggleStyle(style, 'italic', onStyleChanged)),
        _ToggleButton(icon: Icons.format_underlined, isSelected: style['underline'] ?? false, onTap: () => _toggleStyle(style, 'underline', onStyleChanged)),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _pickColor(label, style, (color) => _updateStyle(style, 'color', color, onStyleChanged)),
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: Color(style['color'] ?? 0xFF000000), border: Border.all(color: Colors.grey), shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        // NEW: font size control
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.format_size, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
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
            ],
          ),
        ),
        if (showAlign) ...[
          const SizedBox(width: 8),
          _AlignButton(icon: Icons.format_align_left, isSelected: style['align'] == 'left', onTap: () => _updateStyle(style, 'align', 'left', onStyleChanged)),
          _AlignButton(icon: Icons.format_align_center, isSelected: style['align'] == 'center', onTap: () => _updateStyle(style, 'align', 'center', onStyleChanged)),
          _AlignButton(icon: Icons.format_align_justify, isSelected: style['align'] == 'justify' || style['align'] == null, onTap: () => _updateStyle(style, 'align', 'justify', onStyleChanged)),
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

  Widget _buildLivePreview() {
    final bool showSubtitle = (_subtitleStyle['enabled'] ?? true) as bool;
    final bool showDate = (_dateStyle['enabled'] ?? true) as bool;
    final bool showPlace = (_placeStyle['enabled'] ?? true) as bool;
    final bool showPrincipalLabel = (_principalLabelStyle['enabled'] ?? true) as bool;

    return Column(
      children: [
        Text(_schoolName, style: _getPreviewStyle(_schoolNameStyle), textAlign: TextAlign.center),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(_subtitle, style: _getPreviewStyle(_subtitleStyle), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 10),
        const Divider(thickness: 1, color: Colors.black),
        const SizedBox(height: 30),
        Text(
          (_selectedType == 'Custom Certificate' ? _customTitleController.text : _selectedType).toUpperCase(),
          style: _getPreviewStyle(_titleStyle),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
        Expanded(
          child: Text(
            _bodyController.text,
            style: _getPreviewStyle(_bodyStyle).copyWith(height: 1.6),
            textAlign: _getAlign(_bodyStyle['align']),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate)
                  Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: _getPreviewStyle(_dateStyle)),
                if (showPlace)
                  Text('Place: $_place', style: _getPreviewStyle(_placeStyle)),
              ],
            ),
            Column(
              children: [
                const SizedBox(height: 40),
                if (showPrincipalLabel)
                  Text(_principalLabel, style: _getPreviewStyle(_principalLabelStyle)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // CHANGED: now reads fontSize from the style map itself instead of
  // taking a fixed value from the caller.
  TextStyle _getPreviewStyle(Map<String, dynamic> style) {
    return TextStyle(
      fontSize: (style['fontSize'] ?? 16.0).toDouble(),
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
      case 'justify': return TextAlign.justify;
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
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
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
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}