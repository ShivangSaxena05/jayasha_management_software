import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/widgets/app_sidebar.dart';
import 'package:jayasha_childrens_academy/features/admission/presentation/pages/admission_page.dart';
import 'package:jayasha_childrens_academy/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/presentation/pages/fees_page.dart';
import 'package:jayasha_childrens_academy/features/staff/presentation/pages/staff_page.dart';
import 'package:jayasha_childrens_academy/features/classes/presentation/pages/classes_page.dart';
import 'package:jayasha_childrens_academy/features/students/presentation/pages/students_page.dart';
import 'package:jayasha_childrens_academy/features/certificates/presentation/pages/certificates_page.dart';
import 'package:jayasha_childrens_academy/features/fees/data/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/students/presentation/pages/student_detail_page.dart';
import 'package:jayasha_childrens_academy/features/exams/presentation/pages/exams_page.dart';
import 'package:jayasha_childrens_academy/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';

import 'package:jayasha_childrens_academy/core/utils/app_snackbar.dart';
import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Principal? _principal;
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  List<String> _selectedClasses = [];
  final List<String> _allClasses = ['Nursery', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];

  final List<String> _titles = ['Dashboard', 'Admission', 'Students', 'Examination', 'Fee', 'Staff', 'Classes', 'Certificates', 'Settings'];

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    final repo = Provider.of<OnboardingRepository>(context, listen: false);
    final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Try local data first
      Principal? principal = await repo.getPrincipalDetails();

      // 2. If local data is missing, fetch from server
      if (principal == null) {
        principal = await repo.getPrincipalProfileFromServer();
      }

      final teachers = await repo.getTeachersDetails();
      await dashboardRepo.getDashboardStats();

      if (mounted) {
        setState(() {
          _principal = principal;
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      if (mounted) {
        if (e is UnauthorisedException) {
          _handleLogout();
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      AppSnackbar.showError(context, 'Session expired. Please log in again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (_principal != null)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: _principal!.photoPath != null
                    ? (_principal!.photoPath!.startsWith('http')
                        ? NetworkImage(_principal!.photoPath!)
                        : FileImage(File(_principal!.photoPath!)) as ImageProvider)
                    : null,
                child: _principal!.photoPath == null ? const Icon(Icons.person, color: AppColors.primary) : null,
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          // Content Area
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadOnboardingData,
      );
    }
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const AdmissionPage();
      case 2:
        return StudentsPage(
          onRegisterNewStudent: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
        );
      case 3:
        return const ExamsPage();
      case 4:
        return const FeesPage();
      case 5:
        return const StaffPage();
      case 6:
        return const ClassesPage();
      case 7:
        return const CertificatesPage();
      case 8:
        return const SettingsPage();
      default:
        return _buildUnderDevelopment();
    }
  }

  Widget _buildUnderDevelopment() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForIndex(_selectedIndex),
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jayasha Children\'s Academy Management System',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This module is under development.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview() {
    final dashboardRepo = Provider.of<DashboardRepository>(context);
    final stats = dashboardRepo.stats;
    final counts = stats['counts'] ?? {};
    final totalStudents = counts['students'] ?? 0;
    final totalStaff = counts['teachers'] ?? 0;
    final pendingFeesCount = counts['pendingFeesCount'] ?? 0;
    final totalCollection = (counts['totalCollection'] ?? 0).toDouble();
    final expectedCollection = (counts['expectedCollection'] ?? 0).toDouble();

    final recentAdmissions = stats['recentStudents'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadOnboardingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${_principal?.name ?? "Administrator"}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here\'s what\'s happening in the academy today.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          // Search Bar Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondary),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Quick Search: Student Name or Roll No...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _performSearch(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              StatCard(
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.school_rounded,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Expected Collection',
                value: '₹ ${expectedCollection.toStringAsFixed(0)}',
                icon: Icons.analytics_rounded,
                color: Colors.purple,
              ),
              StatCard(
                title: 'Total Collection',
                value: '₹ ${totalCollection.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
              ),
              StatCard(
                title: 'Pending Fees',
                value: pendingFeesCount.toString(),
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              StatCard(
                title: 'Salary Expense (Month)',
                value: '₹ ${stats['counts']?['monthlySalaryExpense'] ?? 0}',
                icon: Icons.payments_rounded,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Admissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (recentAdmissions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No recent admissions found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...recentAdmissions.map((student) {
                          return Column(
                            children: [
                              _buildRecentAdmissionRow(
                                student['name'] ?? 'Unknown',
                                student['currentClass']?['name'] ?? student['section'] ?? 'N/A',
                                student['admissionDate'] != null
                                  ? DateTime.parse(student['admissionDate']).toString().split(' ')[0]
                                  : 'N/A',
                              ),
                              const Divider(),
                            ],
                          );
                        }),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(() => _selectedIndex = 2),
                        child: const Text('View All Students'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildNoticeBox(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Broadcast Notice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                onPressed: _showClassFilterDialog,
                tooltip: 'Select Classes',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedClasses.isEmpty
              ? 'Target: Whole School'
              : 'Target: ${_selectedClasses.join(", ")}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noticeController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type school-wide announcement here...',
              fillColor: AppColors.background,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('SMS Feature Coming Soon'),
                    content: const Text(
                      'Direct SMS broadcasting is currently under development. \n\n'
                      'We are working on integrating a secure SMS gateway to allow you to send notices directly to parents\' mobile numbers.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Post Notice (SMS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClassFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Classes for Notice'),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                children: _allClasses.map((className) {
                  final isSelected = _selectedClasses.contains(className);
                  return FilterChip(
                    label: Text(className),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          _selectedClasses.add(className);
                        } else {
                          _selectedClasses.remove(className);
                        }
                      });
                      setState(() {});
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedClasses = [];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentAdmissionRow(String name, String grade, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(grade, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.person_add_rounded;
      case 2:
        return Icons.school_rounded;
      case 3:
        return Icons.assignment_rounded;
      case 4:
        return Icons.payments_rounded;
      case 5:
        return Icons.people_rounded;
      case 6:
        return Icons.class_rounded;
      case 7:
        return Icons.verified_rounded;
      case 8:
        return Icons.settings_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final results = await studentRepo.getStudents();

      final filteredResults = results.where((s) =>
        s.name.toLowerCase().contains(query.toLowerCase()) ||
        s.admissionNumber.contains(query)
      ).toList();

      if (filteredResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No student found matching "$query"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (filteredResults.length == 1) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailPage(student: filteredResults.first),
            ),
          );
        }
      } else {
        setState(() {
          _selectedIndex = 2; // Navigate to Students Directory
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getHumanReadableError(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getHumanReadableError(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return 'The connection timed out. Please try again later.';
    }
    if (e is AppException) return e.toString();
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noticeController.dispose();
    super.dispose();
  }
}
