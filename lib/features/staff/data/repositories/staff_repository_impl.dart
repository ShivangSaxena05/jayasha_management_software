import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/salary_record.dart';
import 'package:jayasha_childrens_academy/core/models/leave_record.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class StaffRepositoryImpl implements StaffRepository {
  static const String _tokenKey = 'auth_token';
  List<Teacher> _teachers = [];

  @override
  List<Teacher> get teachers => _teachers;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<List<Teacher>> getTeachers() async {
    try {
      final token = await _getToken();
      final response = await ApiClient.get(
        ApiConfig.teachers,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _teachers = data.map((json) => Teacher.fromJson(json)).toList();
      return _teachers;
    } catch (e) {
      if (e is AppException) rethrow;
      return [];
    }
  }

  @override
  Future<bool> addTeacher(Teacher teacher) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.post(
        '${ApiConfig.teachers}/add',
        teacher.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }

  @override
  Future<bool> updateTeacher(String id, Teacher teacher) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.put(
        '${ApiConfig.teachers}/$id',
        teacher.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }

  @override
  Future<bool> deleteTeacher(String id) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.delete(
        '${ApiConfig.teachers}/$id',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }

  @override
  Future<bool> addSalaryRecord(String teacherId, SalaryRecord record) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.post(
        '${ApiConfig.teachers}/$teacherId/salary',
        record.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }

  @override
  Future<List<SalaryRecord>> getSalaryRecords(String teacherId) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.get(
        '${ApiConfig.teachers}/$teacherId/salary',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SalaryRecord.fromJson(json)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      return [];
    }
  }

  @override
  Future<bool> applyLeave(String teacherId, LeaveRecord record) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.post(
        '${ApiConfig.teachers}/$teacherId/leaves',
        record.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }

  @override
  Future<List<LeaveRecord>> getLeaveRecords(String teacherId) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.get(
        '${ApiConfig.teachers}/$teacherId/leaves',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LeaveRecord.fromJson(json)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      return [];
    }
  }

  @override
  Future<bool> updateLeaveStatus(String leaveId, String status) async {
    try {
      final token = await _getToken();
      final response = await ApiClient.put(
        '${ApiConfig.teachers}/leaves/$leaveId',
        {'status': status},
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is AppException) rethrow;
      return false;
    }
  }
}
