import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';

import 'package:jayasha_childrens_academy/core/error/exceptions.dart';

class DashboardRepository extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/dashboard/stats',
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      _stats = data['data'] ?? {};
      notifyListeners();
      return data;
    } catch (e) {
      if (e is AppException) rethrow;
      throw FetchDataException('Error connecting to server: $e');
    }
  }

  Future<AcademicSession?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiClient.get(
        '${ApiConfig.academicSession}/active',
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      return AcademicSession.fromJson(data);
    } catch (e) {
      print('Error getting current session: $e');
      if (e is AppException) rethrow;
      return null;
    }
  }
}
