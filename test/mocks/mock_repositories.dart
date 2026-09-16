import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart' as fee_domain;
import 'package:jayasha_childrens_academy/features/certificates/data/repositories/certificate_repository.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/features/settings/data/repositories/school_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/salary_record.dart';
import 'package:jayasha_childrens_academy/core/models/leave_record.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/core/models/school_details.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:jayasha_childrens_academy/features/fees/data/models/fee_structure.dart';

class MockOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> savePrincipalDetails(Principal principal) async {}
  @override
  Future<Principal?> getPrincipalDetails() async => Principal(
    name: 'Test Principal',
    email: 'test@example.com',
    phone: '1234567890',
    dob: '1980-01-01',
    gender: 'Male',
    address: 'Test Address',
    qualification: 'PhD',
    experience: '10 years',
    maritalStatus: 'Married',
  );
  @override
  Future<void> saveTeachersDetails(List<Teacher> teachers) async {}
  @override
  Future<List<Teacher>> getTeachersDetails() async => [];
  @override
  Future<void> completeOnboarding() async {}
  @override
  Future<Principal?> getPrincipalProfileFromServer() async => getPrincipalDetails();
  @override
  Future<bool> updatePrincipalProfile(Principal principal) async => true;
  @override
  Future<void> clearOnboardingData() async {}
  @override
  Future<AcademicSession?> getAcademicSession() async => null;
  @override
  Future<bool> isSchoolSetup() async => true;
  @override
  Future<bool> loginWithPin(String pin) async => true;
  @override
  Future<void> saveAcademicSession(AcademicSession session) async {}
  @override
  Future<void> saveFeeStructure(Map<String, Map<String, double>> fees) async {}
  @override
  Future<bool> setupPrincipal({
    required String name,
    required String securityPin,
    required Principal principalDetails,
  }) async => true;
  @override
  Future<void> syncOnboardingData() async {}
  @override
  Future<String?> uploadFile(dynamic filePathOrBytes, String fieldName) async => 'url';
}

class MockDashboardRepository extends ChangeNotifier implements DashboardRepository {
  @override
  Map<String, dynamic> stats = {'totalStudents': 0, 'totalStaff': 0, 'totalClasses': 0, 'totalRevenue': 0};
  @override
  Future<Map<String, dynamic>> getDashboardStats() async => stats;
  @override
  Future<AcademicSession?> getCurrentSession() async => null;
}

class MockStudentRepository implements StudentRepository {
  @override
  Future<Map<String, dynamic>> registerAdmission(StudentAdmission admission, {dynamic photo}) async => {'success': true};
  @override
  Future<List<StudentAdmission>> getStudents({String? classId, String? section, String? admissionNumber}) async => [];
  @override
  Future<StudentAdmission?> getStudentById(String id) async => null;
  @override
  Future<Map<String, dynamic>> updateStudent(String id, StudentAdmission admission, {dynamic photo}) async => {'success': true};
  @override
  Future<void> deleteStudent(String id) async {}
}

class MockStaffRepository implements StaffRepository {
  @override
  List<Teacher> get teachers => [];
  @override
  Future<List<Teacher>> getTeachers() async => [];
  @override
  Future<bool> addTeacher(Teacher teacher, {XFile? photo}) async => true;
  @override
  Future<bool> updateTeacher(String id, Teacher teacher, {XFile? photo}) async => true;
  @override
  Future<bool> deleteTeacher(String id) async => true;
  @override
  Future<bool> addSalaryRecord(String teacherId, SalaryRecord record) async => true;
  @override
  Future<List<SalaryRecord>> getSalaryRecords(String teacherId) async => [];
  @override
  Future<bool> applyLeave(String teacherId, LeaveRecord record) async => true;
  @override
  Future<List<LeaveRecord>> getLeaveRecords(String teacherId) async => [];
  @override
  Future<bool> updateLeaveStatus(String leaveId, String status) async => true;
}

class MockFeeRepository extends ChangeNotifier implements fee_domain.FeeRepository {
  @override
  Future<bool> recordPayment(FeePayment payment) async => true;
  @override
  Future<Map<String, dynamic>> getStudentFeeStatus(String studentId) async => {};
  @override
  Future<List<FeePayment>> getStudentPayments(String studentId) async => [];
  @override
  Future<bool> saveFeeStructure(List<Map<String, dynamic>> fees) async => true;
  @override
  Future<List<Map<String, dynamic>>> getFeeStructures() async => [];
  @override
  Future<List<Map<String, dynamic>>> getAllPayments() async => [];
  @override
  Future<List<Map<String, dynamic>>> getPendingFees() async => [];
  @override
  Future<Map<String, dynamic>> getFeeStats() async => {};
}

class MockClassRepository extends ChangeNotifier implements ClassRepository {
  @override
  List<SchoolClass> get classes => [];
  @override
  List<String> get classNames => [];
  @override
  bool get isLoading => false;
  @override
  Future<List<dynamic>> getClasses() async => [];
  @override
  Future<bool> addClass(String sessionId, String name, List<String> sections) async => true;
  @override
  Future<bool> updateClass(SchoolClass updatedClass) async => true;
  @override
  Future<bool> deleteClass(String id) async => true;
  @override
  Future<bool> addSubjectToClass(String classId, String subject) async => true;
  @override
  Future<void> fetchClasses(String sessionId) async {}
  @override
  SchoolClass? getClass(String name) => null;
  @override
  SchoolClass? getClassByName(String name) => null;
  @override
  Future<bool> updateClassSubjects(String classId, List<String> subjects) async => true;
  @override
  Future<bool> updateFeeStructure(String classId, List<FeeComponent> newFees) async => true;
  @override
  Future<bool> updateNumberOfPeriods(String classId, int newCount) async => true;
  @override
  Future<bool> updateTimetableEntry(String classId, int period, int day, TimetableEntry? entry) async => true;
}

class MockCertificateRepository implements CertificateRepository {
  @override
  Future<Map<String, dynamic>> generateCertificate({
    required String studentId,
    required String type,
    Map<String, dynamic>? details,
  }) async => {};

  @override
  Future<Map<String, dynamic>> updateCertificate({
    required String certificateId,
    required String type,
    required Map<String, dynamic> details,
  }) async => {};

  @override
  Future<Map<String, dynamic>> getRecentCertificates() async => {};
}

class MockExamRepository implements ExamRepository {
  @override
  Future<Map<String, dynamic>> createExam(Map<String, dynamic> examData) async => {};
  @override
  Future<Map<String, dynamic>> updateExam(String examId, Map<String, dynamic> examData) async => {};
  @override
  Future<Map<String, dynamic>> getExams(String sessionId) async => {};
  @override
  Future<Map<String, dynamic>> getExamResults(String examId) async => {};
  @override
  Future<Map<String, dynamic>> submitMarks({
    required String examId,
    required String classId,
    required List<Map<String, dynamic>> marksData,
  }) async => {};
  @override
  Future<Map<String, dynamic>> deleteExam(String examId) async => {};
  @override
  Future<Map<String, dynamic>> getExamDatesheet(String examId, {String? classId}) async => {};
  @override
  Future<Map<String, dynamic>> getMarks(String examId, String classId) async => {};
  @override
  Future<Map<String, dynamic>> getReportCard(String studentId, String examId) async => {};
  @override
  Future<Map<String, dynamic>> updateExamDatesheet(String examId, List<Map<String, dynamic>> datesheet) async => {};
}

class MockSchoolRepository extends ChangeNotifier implements SchoolRepository {
  @override
  SchoolDetails? get schoolDetails => SchoolDetails(
    id: '1',
    schoolName: 'Test School',
    address: 'Test Address',
    phone: '1234567890',
    email: 'test@school.com',
    affiliationLine: 'Affiliated to UP Board',
    logoUrl: 'logo_url',
    principalSignatureLabel: 'Principal Signature',
  );
  @override
  Future<SchoolDetails?> fetchSchoolDetails() async => schoolDetails;
  @override
  Future<Map<String, dynamic>> updateSchoolDetails(SchoolDetails details) async => {'success': true};
  @override
  Future<String?> updateLogo(dynamic file) async => 'logo_url';
}
