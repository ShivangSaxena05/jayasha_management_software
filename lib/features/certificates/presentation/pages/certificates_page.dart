import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';
import 'certificate_editor_page.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  List<dynamic> _recentCertificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentCertificates();
  }

  Future<void> _loadRecentCertificates() async {
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditor({Map<String, dynamic>? cert}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateEditorPage(certificateData: cert),
      ),
    );

    if (result == true) {
      _loadRecentCertificates();
    }
  }

  void _downloadCertificate(Map<String, dynamic> cert) {
    if (cert['student'] == null) return;

    final student = StudentAdmission.fromJson(cert['student']);
    PdfGenerator.downloadCertificate(
      student: student,
      type: cert['type'] ?? 'Certificate',
      details: Map<String, dynamic>.from(cert['details'] ?? {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificates',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage and issue official student documents',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Issue New Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recently Generated',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recentCertificates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _recentCertificates.length,
                        itemBuilder: (context, index) {
                          final cert = _recentCertificates[index];
                          return _buildCertificateCard(cert);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No certificates issued yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final studentName = cert['student']?['name'] ?? 'Unknown Student';
    final type = cert['type'] ?? 'Certificate';
    final issueDate = cert['issueDate'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(cert['issueDate']))
        : 'Unknown Date';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.school, color: AppColors.primary),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
            Text('Issued: $issueDate', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _navigateToEditor(cert: cert),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.blue),
              onPressed: () => _downloadCertificate(cert),
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }
}
