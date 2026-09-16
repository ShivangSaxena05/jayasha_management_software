import 'dart:convert';
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
  Future<String?> updateLogo(dynamic file);
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
          if (token != null) 'Authorization': 'Bearer $token',
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
  Future<String?> updateLogo(dynamic file) async {
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

      if (kIsWeb) {
        // file is a NamedBytes or similar for web, or we can check if it's Uint8List / XFile
        if (file is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes('logo', file, filename: 'logo.png'),
          );
        } else if (file is Map && file.containsKey('bytes')) {
          request.files.add(
            http.MultipartFile.fromBytes('logo', file['bytes'] as Uint8List, filename: file['name'] as String? ?? 'logo.png'),
          );
        } else {
          // Fallback if it's passed as a custom object or if path is string
          request.files.add(
            await http.MultipartFile.fromPath('logo', file.path.toString()),
          );
        }
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('logo', file.path as String),
        );
      }

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
