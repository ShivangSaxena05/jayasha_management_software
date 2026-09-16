import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class StudentRepositoryImpl implements StudentRepository {
  static const String _tokenKey = 'auth_token';

  @override
  Future<Map<String, dynamic>> registerAdmission(StudentAdmission admission, {dynamic photo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final url = Uri.parse('${ApiConfig.baseUrl}/students/admission');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      // Add student data
      admission.toJson().forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add photo if present
      if (photo != null) {
        if (kIsWeb) {
          final Uint8List bytes = photo is Uint8List ? photo : await (photo as XFile).readAsBytes();
          final String fileName = photo is XFile ? photo.name : 'photo.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: fileName,
          ));
        } else {
          final XFile xFile = photo as XFile;
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            xFile.path,
          ));
        }
      }

      final streamedResponse = await request.send().timeout(ApiClient.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to register student.',
        };
      }
    } catch (e) {
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
  Future<Map<String, dynamic>> updateStudent(String id, StudentAdmission admission, {dynamic photo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final url = Uri.parse('${ApiConfig.baseUrl}/students/$id');
      final request = http.MultipartRequest('PUT', url);

      request.headers['Authorization'] = 'Bearer $token';

      // Add student data
      admission.toJson().forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add photo if present
      if (photo != null) {
        if (kIsWeb) {
          final Uint8List bytes = photo is Uint8List ? photo : await (photo as XFile).readAsBytes();
          final String fileName = photo is XFile ? photo.name : 'photo.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: fileName,
          ));
        } else {
          final XFile xFile = photo as XFile;
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            xFile.path,
          ));
        }
      }

      final streamedResponse = await request.send().timeout(ApiClient.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update student.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
