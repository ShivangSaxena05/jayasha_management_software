import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  final List<String> certificateTypes = ['Transfer Certificate (TC)', 'Bonafide Certificate', 'Character Certificate'];
  String? selectedType;
  final TextEditingController _admNoController = TextEditingController();
  StudentAdmission? _foundStudent;
  bool _hasSearched = false;
  bool _isSearching = false;
  List<dynamic> _recentCertificates = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentCertificates();
  }

  Future<void> _loadRecentCertificates() async {
    setState(() => _isLoadingRecent = true);
    try {
      final certRepo = Provider.of<CertificateRepository>(context, listen: false);
      final response = await certRepo.getRecentCertificates();
      if (response['success'] == true) {
        setState(() {
          _recentCertificates = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error loading recent certificates: $e');
    } finally {
      setState(() => _isLoadingRecent = false);
    }
  }

  Future<void> _generateCertificate(StudentAdmission student) async {
    try {
      final certRepo = Provider.of<CertificateRepository>(context, listen: false);
      final response = await certRepo.generateCertificate(
        studentId: student.id!,
        type: selectedType!,
        details: {
          'session': '2023-24',
          'fatherName': student.fatherName,
          'section': student.section ?? 'N/A',
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate Generated & Saved Successfully!'), backgroundColor: Colors.green),
          );
        }
        _loadRecentCertificates(); // Refresh list
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response['message']}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating certificate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificate Generation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate official documents for students directly.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Form
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Certificate Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      const Text('Select Certificate Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose type...',
                        ),
                        items: certificateTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (val) => setState(() => selectedType = val),
                      ),
                      const SizedBox(height: 20),
                      const Text('Student Admission Number', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _admNoController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'e.g. 2023001',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSearching ? null : () async {
                              setState(() {
                                _isSearching = true;
                                _hasSearched = false;
                              });
                              try {
                                final studentRepo = Provider.of<StudentRepository>(context, listen: false);
                                final students = await studentRepo.getStudents(admissionNumber: _admNoController.text);
                                setState(() {
                                  _foundStudent = students.isNotEmpty ? students.first : null;
                                  _hasSearched = true;
                                });
                              } catch (e) {
                                debugPrint('Error searching student: $e');
                              } finally {
                                setState(() {
                                  _isSearching = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                            child: _isSearching
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Verify'),
                          ),
                        ],
                      ),
                      if (_hasSearched) ...[
                        const SizedBox(height: 16),
                        if (_foundStudent != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Verified: ${_foundStudent!.name}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 12),
                                const Text(
                                  'Student not found!',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: (_foundStudent == null || selectedType == null)
                              ? null
                              : () => _showPreviewDialog(_foundStudent!),
                          icon: const Icon(Icons.description_rounded),
                          label: const Text('Generate & Preview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 30),
              // Instructions / Recent
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text('• Ensure student details are up to date in the Students module.'),
                          SizedBox(height: 8),
                          Text('• Generated certificates will be saved in the student\'s record.'),
                          SizedBox(height: 8),
                          Text('• Use the preview to verify details before printing.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recently Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          if (_isLoadingRecent)
                            const Center(child: CircularProgressIndicator())
                          else if (_recentCertificates.isEmpty)
                            const Text('No certificates generated yet.', style: TextStyle(color: AppColors.textSecondary))
                          else
                            ..._recentCertificates.map((cert) {
                              return Column(
                                children: [
                                  _buildRecentItem(
                                    cert['student']['name'],
                                    cert['type'],
                                    DateFormat('dd MMM, hh:mm a').format(DateTime.parse(cert['issueDate'])),
                                  ),
                                  const Divider(),
                                ],
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String name, String type, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showPreviewDialog(StudentAdmission student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview: $selectedType'),
        content: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              const Text(
                'JAYASHA CHILDREN\'S ACADEMY',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const Text('Affiliated to CBSE, New Delhi'),
              const SizedBox(height: 40),
              Text(
                selectedType!.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This is to certify that Master/Miss ${student.name}, son/daughter of Mr. ${student.fatherName}, is/was a bonafide student of this school studying in section ${student.section ?? 'N/A'} during the session 2023-24.',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                  const Text('Principal Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _generateCertificate(student);
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirm & Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await PdfGenerator.generateCertificate(
                student: student,
                type: selectedType!,
                details: {'session': '2023-24'},
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Now'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
