import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';

class FeeRepositoryImpl extends ChangeNotifier implements FeeRepository {
  static const String _tokenKey = 'auth_token';

  @override
  Future<bool> recordPayment(FeePayment payment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.post(
        '${ApiConfig.baseUrl}/fees/payments',
        payment.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
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

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/student/$studentId',
        headers: {
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

      final response = await ApiClient.post(
        '${ApiConfig.baseUrl}/fees/structure',
        {'fees': fees},
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in saveFeeStructure: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFeeStructures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/structure',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error in getFeeStructures: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/payments',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return {
            'id': json['_id'],
            'amount': double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
            'date': DateTime.parse(json['paymentDate'] ?? json['createdAt']),
            'paidMonths': List<String>.from(json['paidMonths'] ?? []),
            'mode': PaymentMode.values.where(
              (e) => e.name == (json['paymentMode'] ?? 'cash'),
            ).firstOrNull ?? PaymentMode.cash,
            'category': FeeCategory.values.where(
              (e) => e.name == (json['category'] ?? 'monthly'),
            ).firstOrNull ?? FeeCategory.monthly,
            'remarks': json['remarks'],
            'studentName': json['student'] is Map ? json['student']['name'] : 'Unknown',
            'admissionNumber': json['student'] is Map ? json['student']['admissionNumber'] : 'N/A',
            'studentId': json['student'] is Map ? json['student']['_id'] : json['student'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error in getAllPayments: $e');
      return [];
    }
  }

  @override
  Future<List<FeePayment>> getStudentPayments(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/student/$studentId/payments',
        headers: {
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

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/stats',
        headers: {
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

  @override
  Future<List<Map<String, dynamic>>> getPendingFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final response = await ApiClient.get(
        '${ApiConfig.baseUrl}/fees/pending',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error in getPendingFees: $e');
      return [];
    }
  }
}
