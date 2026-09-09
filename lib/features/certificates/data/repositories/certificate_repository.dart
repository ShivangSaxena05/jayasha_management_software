import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CertificateRepository {
  /// Safely decodes a response body. Returns a clean failure map instead of
  /// throwing if the body is empty or not valid JSON (e.g. a 401/500 HTML
  /// error page from the server).
  Map<String, dynamic> _safeDecode(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server (status ${response.statusCode})',
        };
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response format'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Server error (status ${response.statusCode})',
      };
    }
  }

  Future<Map<String, dynamic>> generateCertificate({
    required String studentId,
    required String type,
    Map<String, dynamic>? details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // FIX: token was being read under the wrong key ('token'), which is
      // never set anywhere in this app — the login flow saves it as
      // 'auth_token' (see FeeRepositoryImpl / ExamRepository). This caused
      // every request to send "Authorization: Bearer null" -> Unauthorized.
      final token = prefs.getString('auth_token');

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

      return _safeDecode(response);
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
      final token = prefs.getString('auth_token'); // FIX: was 'token'

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

      return _safeDecode(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRecentCertificates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); // FIX: was 'token'

      final response = await http.get(
        Uri.parse(ApiConfig.recentCertificates),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _safeDecode(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}