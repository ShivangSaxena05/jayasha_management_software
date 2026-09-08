import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/login_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/greeting_page.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/features/fees/data/repositories/fee_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/fees/data/repositories/fee_repository.dart' as fee_mock;
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';

import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:jayasha_childrens_academy/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/students/data/repositories/student_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/features/attendance/data/repositories/attendance_repository.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final onboardingRepo = OnboardingRepositoryImpl();
  final isComplete = await onboardingRepo.isOnboardingComplete();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => fee_mock.FeeRepository()),
        ChangeNotifierProvider(create: (_) => ClassRepository()),
        Provider<OnboardingRepository>(create: (_) => onboardingRepo),
        ChangeNotifierProvider(create: (_) => DashboardRepository()),
        Provider<StudentRepository>(create: (_) => StudentRepositoryImpl()),
        Provider<StaffRepository>(create: (_) => StaffRepositoryImpl()),
        ChangeNotifierProvider<fee_domain.FeeRepository>(create: (_) => FeeRepositoryImpl()),
        Provider<CertificateRepository>(create: (_) => CertificateRepository()),
        Provider<AttendanceRepository>(create: (_) => AttendanceRepository()),
        Provider<ExamRepository>(create: (_) => ExamRepository()),
      ],
      child: MyApp(isComplete: isComplete),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isComplete;
  const MyApp({super.key, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jayasha Children\'s Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: isComplete ? const DashboardPage() : const GreetingPage(),
    );
  }
}
