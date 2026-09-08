import 'package:flutter/foundation.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';

abstract class FeeRepository extends ChangeNotifier {
  Future<bool> recordPayment(FeePayment payment);
  Future<Map<String, dynamic>> getStudentFeeStatus(String studentId);
  Future<List<FeePayment>> getStudentPayments(String studentId);
  Future<bool> saveFeeStructure(List<Map<String, dynamic>> fees);
  Future<List<dynamic>> getFeeStructures();
  Future<Map<String, dynamic>> getFeeStats();
}
