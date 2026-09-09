import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:jayasha_childrens_academy/core/repositories/school_repository.dart';
import 'package:jayasha_childrens_academy/core/models/school_settings.dart';

class IdCardEditorPage extends StatefulWidget {
  final StudentAdmission student;
  final Map<String, dynamic>? certificateData;

  const IdCardEditorPage({super.key, required this.student, this.certificateData});

  @override
  State<IdCardEditorPage> createState() => _IdCardEditorPageState();
}

class _IdCardEditorPageState extends State<IdCardEditorPage> {
  String _schoolName = 'JAYASHA CHILDREN\'S ACADEMY';
  String _schoolAddress = 'Shivpuri, Madhya Pradesh';

  Map<String, dynamic> _schoolNameStyle = {
    'bold': true, 'italic': false, 'underline': false, 'color': 0xFF0D47A1, 'fontSize': 16.0, 'align': 'center',
  };
  Map<String, dynamic> _addressStyle = {
    'bold': false, 'italic': false, 'underline': false, 'color': 0xFF666666, 'fontSize': 10.0, 'enabled': true, 'align': 'center',
  };

  static const List<double> _fontSizeOptions = [8, 9, 10, 11, 12, 14, 16, 18, 20, 24];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. First load from certificate if editing
    if (widget.certificateData != null) {
      _loadCertificateData();
    } else {
      // 2. Otherwise load default from school settings
      try {
        final schoolRepo = Provider.of<SchoolRepository>(context, listen: false);
        final settings = await schoolRepo.getSettings();
        setState(() {
          _schoolName = settings.schoolName;
          _schoolAddress = settings.address;
        });
      } catch (e) {
        debugPrint('Error loading school settings: $e');
      }
    }
  }

  void _loadCertificateData() {
    final details = widget.certificateData!['details'] ?? {};
    _schoolName = details['schoolName'] ?? 'JAYASHA CHILDREN\'S ACADEMY';
    _schoolAddress = details['schoolAddress'] ?? '';
    _schoolNameStyle = _mergeStyle(_schoolNameStyle, details['schoolNameStyle']);
    _addressStyle = _mergeStyle(_addressStyle, details['addressStyle']);
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

  void _printCard() {
    PdfGenerator.printIdCard(
      student: widget.student,
      details: _buildDetailsPayload(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.certificateData == null ? 'Generate ID Card' : 'Edit ID Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printCard,
            tooltip: 'Print ID Card',
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
                    _buildSectionHeader('Student Details (Read-only)'),
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
                  child: Container(
                    width: 340,
                    height: 214,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildLivePreview() {
    final bool showAddress = (_addressStyle['enabled'] ?? true) as bool;
    final Color headerColor = Color(_schoolNameStyle['color'] ?? 0xFF0D47A1).withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: headerColor,
          child: Column(
            children: [
              Text(_schoolName, style: _getPreviewStyle(_schoolNameStyle), textAlign: _getAlign(_schoolNameStyle['align'])),
              if (showAddress)
                Text(_schoolAddress, style: _getPreviewStyle(_addressStyle), textAlign: _getAlign(_addressStyle['align'])),
            ],
          ),
        ),
        const Divider(thickness: 1, height: 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Photo
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: widget.student.photoPath != null
                      ? Image.network(
                          widget.student.photoPath!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _cardDataRow('Name', widget.student.name, isBold: true),
                      const SizedBox(height: 4),
                      _cardDataRow('Class', '${widget.student.className ?? 'N/A'} - ${widget.student.section ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      _cardDataRow('Roll No', widget.student.rollNumber ?? 'Not Assigned'),
                      const SizedBox(height: 4),
                      _cardDataRow('Adm No', widget.student.admissionNumber),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardDataRow(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: AppColors.textPrimary)),
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
