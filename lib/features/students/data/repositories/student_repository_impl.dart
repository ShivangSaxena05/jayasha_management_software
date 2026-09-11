import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class StudentRepositoryImpl implements StudentRepository {
  static const String _tokenKey = 'auth_token';

  @override
  Future<Map<String, dynamic>> registerAdmission(StudentAdmission admission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.post(
        '${ApiConfig.baseUrl}/students/admission',
        admission.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {'success': true, 'data': responseData};
    } catch (e) {
      if (e is AppException) rethrow;
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  @override
  Future<List<StudentAdmission>> getStudents({String? classId, String? section, String? admissionNumber}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      String url = '${ApiConfig.baseUrl}/students';
      List<String> params = [];
      if (classId != null) params.add('classId=$classId');
      if (section != null) params.add('section=$section');
      if (admissionNumber != null) params.add('admissionNumber=$admissionNumber');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final response = await ApiClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      final List<dynamic> studentsJson = data['data'];
      return studentsJson.map((json) => StudentAdmission.fromJson(json)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      return [];
    }
  }

  @override
  Future<StudentAdmission?> getStudentById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/students/$id',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      return StudentAdmission.fromJson(data['data']);
    } catch (e) {
      if (e is AppException) rethrow;
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> updateStudent(String id, StudentAdmission admission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.put(
        '${ApiConfig.baseUrl}/students/$id',
        admission.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {'success': true, 'data': responseData};
    } catch (e) {
      if (e is AppException) rethrow;
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
