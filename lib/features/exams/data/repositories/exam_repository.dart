import 'dart:convert';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class ExamRepository {
  Future<Map<String, dynamic>> createExam(Map<String, dynamic> examData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.post(
        ApiConfig.exams,
        examData,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateExam(String examId, Map<String, dynamic> examData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.put(
        '${ApiConfig.exams}/$examId',
        examData,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateExamDatesheet(String examId, List<Map<String, dynamic>> datesheet) async {
    return updateExam(examId, {'datesheet': datesheet});
  }

  Future<Map<String, dynamic>> getExamDatesheet(String examId, {String? classId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String url = '${ApiConfig.exams}/$examId/datesheet';
      if (classId != null) url += '?classId=$classId';

      final response = await ApiClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteExam(String examId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.delete(
        '${ApiConfig.exams}/$examId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) return {'success': true};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {'success': true};
      }
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getExams(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.get(
        '${ApiConfig.exams}?session=$sessionId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitMarks({
    required String examId,
    required String classId,
    required List<Map<String, dynamic>> marksData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.post(
        ApiConfig.examMarks,
        {
          'examId': examId,
          'classId': classId,
          'marksData': marksData,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMarks(String examId, String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.get(
        '${ApiConfig.examMarks}?examId=$examId&classId=$classId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getReportCard(String studentId, String examId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.get(
        '${ApiConfig.reportCard}?studentId=$studentId&examId=$examId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      if (e is AppException) rethrow;
      return {'success': false, 'message': e.toString()};
    }
  }
}
