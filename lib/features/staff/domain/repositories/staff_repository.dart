import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/salary_record.dart';
import 'package:jayasha_childrens_academy/core/models/leave_record.dart';

abstract class StaffRepository {
  Future<List<Teacher>> getTeachers();
  Future<bool> addTeacher(Teacher teacher);
  Future<bool> updateTeacher(String id, Teacher teacher);
  Future<bool> deleteTeacher(String id);

  // Salary Routes
  Future<bool> addSalaryRecord(String teacherId, SalaryRecord record);
  Future<List<SalaryRecord>> getSalaryRecords(String teacherId);

  // Leave Routes
  Future<bool> applyLeave(String teacherId, LeaveRecord record);
  Future<List<LeaveRecord>> getLeaveRecords(String teacherId);
  Future<bool> updateLeaveStatus(String leaveId, String status);
}
