// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/main.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/settings/data/repositories/school_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'mocks/mock_repositories.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OnboardingRepository>(create: (_) => MockOnboardingRepository()),
          ChangeNotifierProvider<DashboardRepository>(create: (_) => MockDashboardRepository()),
          Provider<StudentRepository>(create: (_) => MockStudentRepository()),
          Provider<StaffRepository>(create: (_) => MockStaffRepository()),
          ChangeNotifierProvider<fee_domain.FeeRepository>(create: (_) => MockFeeRepository()),
          ChangeNotifierProvider<ClassRepository>(create: (_) => MockClassRepository()),
          Provider<CertificateRepository>(create: (_) => MockCertificateRepository()),
          Provider<ExamRepository>(create: (_) => MockExamRepository()),
          ChangeNotifierProvider<SchoolRepository>(create: (_) => MockSchoolRepository()),
        ],
        child: const MyApp(isComplete: true),
      ),
    );

    // Verify that DashboardPage is shown (it has 'Dashboard' title)
    expect(find.text('Dashboard'), findsAtLeast(1));
  });
}
