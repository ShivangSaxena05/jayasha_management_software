import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/salary_record.dart';
import 'package:jayasha_childrens_academy/core/models/leave_record.dart';
import 'package:jayasha_childrens_academy/features/staff/domain/repositories/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<List<Teacher>> getTeachers() async {
    try {
      final token = await _getToken();
      print('Fetching teachers from: ${ApiConfig.teachers}');
      final response = await http.get(
        Uri.parse(ApiConfig.teachers),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Teacher.fromJson(json)).toList();
      } else {
        print('Failed to load teachers. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getTeachers: $e');
      return [];
    }
  }

  @override
  Future<bool> addTeacher(Teacher teacher) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.teachers}/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(teacher.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error in addTeacher: $e');
      return false;
    }
  }

  @override
  Future<bool> updateTeacher(String id, Teacher teacher) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.teachers}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(teacher.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateTeacher: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteTeacher(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.teachers}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteTeacher: $e');
      return false;
    }
  }

  @override
  Future<bool> addSalaryRecord(String teacherId, SalaryRecord record) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.teachers}/$teacherId/salary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(record.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error in addSalaryRecord: $e');
      return false;
    }
  }

  @override
  Future<List<SalaryRecord>> getSalaryRecords(String teacherId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.teachers}/$teacherId/salary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SalaryRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getSalaryRecords: $e');
      return [];
    }
  }

  @override
  Future<bool> applyLeave(String teacherId, LeaveRecord record) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.teachers}/$teacherId/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(record.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error in applyLeave: $e');
      return false;
    }
  }

  @override
  Future<List<LeaveRecord>> getLeaveRecords(String teacherId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.teachers}/$teacherId/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LeaveRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getLeaveRecords: $e');
      return [];
    }
  }

  @override
  Future<bool> updateLeaveStatus(String leaveId, String status) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.teachers}/leaves/$leaveId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateLeaveStatus: $e');
      return false;
    }
  }
}
