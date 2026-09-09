import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/school_details.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
import 'package:http/http.dart' as http;

abstract class SchoolRepository extends ChangeNotifier {
  SchoolDetails? get schoolDetails;
  Future<SchoolDetails?> fetchSchoolDetails();
  Future<Map<String, dynamic>> updateSchoolDetails(SchoolDetails details);
  Future<String?> updateLogo(File file);
}

class SchoolRepositoryImpl extends SchoolRepository {
  static const String _tokenKey = 'auth_token';
  SchoolDetails? _schoolDetails;

  @override
  SchoolDetails? get schoolDetails => _schoolDetails;

  @override
  Future<SchoolDetails?> fetchSchoolDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/school',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          _schoolDetails = SchoolDetails.fromJson(data['data']);
          notifyListeners();
          return _schoolDetails;
        }
      }
      return null;
    } catch (e) {
      print('Error in fetchSchoolDetails: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> updateSchoolDetails(SchoolDetails details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.put(
        '${ApiConfig.baseUrl}/school',
        details.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _schoolDetails = SchoolDetails.fromJson(responseData['data']);
        notifyListeners();
        return {'success': true, 'data': _schoolDetails};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      print('Error in updateSchoolDetails: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  @override
  Future<String?> updateLogo(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/school/logo'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('logo', file.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Error in updateLogo: $e');
      return null;
    }
  }
}
