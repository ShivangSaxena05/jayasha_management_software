import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';

class StudentRepositoryImpl implements StudentRepository {
  static const String _tokenKey = 'auth_token';

  @override
  Future<Map<String, dynamic>> registerAdmission(StudentAdmission admission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      print('DEBUG: Sending Admission Data to ${ApiConfig.baseUrl}/students/admission');
      print('DEBUG: Data: ${jsonEncode(admission.toJson())}');

      final response = await ApiClient.post(
        '${ApiConfig.baseUrl}/students/admission',
        admission.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: registerAdmission Status Code: ${response.statusCode}');
      print('DEBUG: registerAdmission Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'error': responseData['error']
        };
      }
    } catch (e) {
      print('ERROR in registerAdmission: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> studentsJson = data['data'];
        return studentsJson.map((json) => StudentAdmission.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getStudents: $e');
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StudentAdmission.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error in getStudentById: $e');
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

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      print('Error in updateStudent: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
