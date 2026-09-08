import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CertificateRepository {
  Future<Map<String, dynamic>> generateCertificate({
    required String studentId,
    required String type,
    Map<String, dynamic>? details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(ApiConfig.certificates),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentId': studentId,
          'type': type,
          'details': details,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCertificate({
    required String certificateId,
    required String type,
    required Map<String, dynamic> details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${ApiConfig.certificates}/$certificateId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'details': details,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRecentCertificates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiConfig.recentCertificates),
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
