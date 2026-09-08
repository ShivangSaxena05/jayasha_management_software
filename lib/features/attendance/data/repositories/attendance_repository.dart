import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRepository {
  Future<Map<String, dynamic>> markAttendance({
    required List<Map<String, dynamic>> attendanceRecords,
    required String date,
    required String sessionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final response = await http.post(
        Uri.parse(ApiConfig.markAttendance),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'attendanceRecords': attendanceRecords,
          'date': date,
          'sessionId': sessionId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAttendanceByClass(String classId, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.classAttendance}?classId=$classId&date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getStudentAttendanceReport({
    required String studentId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.studentAttendanceReport}?studentId=$studentId&startDate=$startDate&endDate=$endDate'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
