enum PaymentMode { cash, online, cheque, other }
enum FeeCategory { monthly, admission, exam, annual, other }

class FeePayment {
  final String? id;
  final String studentId;
  final String academicSessionId;
  final double amount;
  final DateTime date;
  final PaymentMode mode;
  final FeeCategory category;
  final List<String> paidMonths;
  final String? remarks;

  FeePayment({
    this.id,
    required this.studentId,
    required this.academicSessionId,
    required this.amount,
    required this.date,
    required this.mode,
    required this.category,
    this.paidMonths = const [],
    this.remarks,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: json['_id'],
      studentId: json['student'] is Map ? json['student']['_id'] : json['student'],
      academicSessionId: json['academicSession'] is Map ? json['academicSession']['_id'] : json['academicSession'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: DateTime.parse(json['paymentDate'] ?? json['createdAt']),
      mode: PaymentMode.values.where(
        (e) => e.name == (json['paymentMode'] ?? 'cash'),
      ).firstOrNull ?? PaymentMode.cash,
      category: FeeCategory.values.where(
        (e) => e.name == (json['category'] ?? 'monthly'),
      ).firstOrNull ?? FeeCategory.monthly,
      paidMonths: List<String>.from(json['paidMonths'] ?? []),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'academicSessionId': academicSessionId,
      'amount': amount,
      'paymentMode': mode.name,
      'category': category.name,
      'paidMonths': paidMonths,
      'remarks': remarks,
    };
  }
}
