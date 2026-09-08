import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/widgets/error_view.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/staff/presentation/pages/staff_detail_page.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/features/staff/presentation/pages/teacher_form_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = Provider.of<StaffRepository>(context, listen: false);
      final teachers = await repo.getTeachers();
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getHumanReadableError(e);
        });
      }
    }
  }

  String _getHumanReadableError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (e.toString().contains('TimeoutException')) {
      return 'The connection timed out. Please try again later.';
    }
    return 'An unexpected error occurred while loading staff data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadStaffData,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Staff Directory (Teachers)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTeacherForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Teacher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _teachers.isEmpty
                ? const Center(child: Text('No teachers found.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 450,
                      mainAxisExtent: 110,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      return _buildStaffCard(
                        context,
                        teacher.name,
                        teacher.isClassTeacher
                            ? 'Class Teacher (${teacher.classTeacherOfClass})'
                            : 'Teacher',
                        teacher.phone,
                        teacher,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTeacherForm(BuildContext context, {Teacher? teacher}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherFormPage(
          teacher: teacher,
          onSave: () => _loadStaffData(),
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    String name,
    String role,
    String phone,
    Teacher teacher,
  ) {
    final photoPath = teacher.photoPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showAvatar = constraints.maxWidth > 160;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffDetailPage(
                    person: teacher,
                  ),
                ),
              ).then((_) => _loadStaffData()); // Refresh after returning from detail (which might have edits)
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showAvatar) ...[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      backgroundImage: (photoPath != null && photoPath.isNotEmpty)
                          ? (photoPath.startsWith('http')
                              ? NetworkImage(photoPath)
                              : FileImage(File(photoPath)) as ImageProvider)
                          : null,
                      child: (photoPath == null || photoPath.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 28) : null,
                    ),
                    const SizedBox(width: 16),
                  ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+91 $phone',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
