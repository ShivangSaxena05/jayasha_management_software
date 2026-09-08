import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';

class FeeRepositoryImpl extends ChangeNotifier implements FeeRepository {
  static const String _tokenKey = 'auth_token';

  @override
  Future<bool> recordPayment(FeePayment payment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fees/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payment.toJson()),
      );

      if (response.statusCode == 201) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in recordPayment: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentFeeStatus(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/student/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Error in getStudentFeeStatus: $e');
      return {};
    }
  }

  @override
  Future<bool> saveFeeStructure(List<Map<String, dynamic>> fees) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fees/structure'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fees': fees}),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in saveFeeStructure: $e');
      return false;
    }
  }

  @override
  Future<List<dynamic>> getFeeStructures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/structure'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error in getFeeStructures: $e');
      return [];
    }
  }

  @override
  Future<List<FeePayment>> getStudentPayments(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/student/$studentId/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FeePayment.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error in getStudentPayments: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getFeeStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Error in getFeeStats: $e');
      return {};
    }
  }
}
