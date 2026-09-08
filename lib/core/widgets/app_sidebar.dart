import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/login_page.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: _isExpanded ? 220 : 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Logo/Header area
            InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => widget.onItemSelected(0),
              child: Container(
                height: 70,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Center(
                        child: Image.asset(
                          'assets/images/JCB_Logo.png',
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: AppColors.primary, size: 35),
                        ),
                      ),
                    ),
                    if (_isExpanded)
                      const Expanded(
                        child: Text(
                          "Jayasha Children's Academy",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(indent: 10, endIndent: 10),
            const SizedBox(height: 10),
            _buildSidebarItem(Icons.dashboard_rounded, 'Dashboard', 0),
            _buildSidebarItem(Icons.person_add_rounded, 'Admission', 1),
            _buildSidebarItem(Icons.school_rounded, 'Students', 2),
            _buildSidebarItem(Icons.event_available_rounded, 'Attendance', 3),
            _buildSidebarItem(Icons.assignment_rounded, 'Examination', 4),
            _buildSidebarItem(Icons.payments_rounded, 'Fee', 5),
            _buildSidebarItem(Icons.people_rounded, 'Staff', 6),
            _buildSidebarItem(Icons.class_rounded, 'Classes', 7),
            _buildSidebarItem(Icons.verified_rounded, 'Certificates', 8),
            const Spacer(),
            const Divider(indent: 10, endIndent: 10),
            _buildSidebarItem(Icons.logout_rounded, 'Logout', -1, isLogout: true),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index, {bool isLogout = false}) {
    final bool isSelected = widget.selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () async {
          if (isLogout) {
            final repo = Provider.of<OnboardingRepository>(context, listen: false);
            await repo.clearOnboardingData();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          } else {
            widget.onItemSelected(index);
          }
        },
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        size: 26,
                        color: isLogout
                            ? AppColors.error
                            : (isSelected ? AppColors.primary : AppColors.textSecondary),
                      ),
                    ),
                    if (isSelected && !_isExpanded)
                      Positioned(
                        right: 0,
                        top: 15,
                        bottom: 15,
                        child: Container(
                          width: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isExpanded)
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isLogout
                            ? AppColors.error
                            : (isSelected ? AppColors.primary : AppColors.textPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
