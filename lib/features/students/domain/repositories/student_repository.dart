import 'package:jayasha_childrens_academy/core/models/student_admission.dart';

abstract class StudentRepository {
  Future<Map<String, dynamic>> registerAdmission(StudentAdmission admission);
  Future<List<StudentAdmission>> getStudents({String? classId, String? section, String? admissionNumber});
  Future<StudentAdmission?> getStudentById(String id);
  Future<Map<String, dynamic>> updateStudent(String id, StudentAdmission admission);
}
