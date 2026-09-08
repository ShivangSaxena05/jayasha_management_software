class FeeComponent {
  final String name;
  final double amount;
  final String frequency;
  final List<String> applicableMonths;

  FeeComponent({
    required this.name,
    required this.amount,
    required this.frequency,
    this.applicableMonths = const [
      'April', 'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December', 'January', 'February', 'March'
    ],
  });

  factory FeeComponent.fromJson(Map<String, dynamic> json) {
    return FeeComponent(
      name: json['name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      frequency: json['frequency'] ?? 'monthly',
      applicableMonths: List<String>.from(json['applicableMonths'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'applicableMonths': applicableMonths,
    };
  }

  FeeComponent copyWith({
    String? name,
    double? amount,
    String? frequency,
    List<String>? applicableMonths,
  }) {
    return FeeComponent(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      applicableMonths: applicableMonths ?? this.applicableMonths,
    );
  }
}

class FeeStructure {
  final String? id;
  final String academicSessionId;
  final String classId;
  final List<FeeComponent> components;

  FeeStructure({
    this.id,
    required this.academicSessionId,
    required this.classId,
    required this.components,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json['_id'],
      academicSessionId: json['academicSession'] is Map ? json['academicSession']['_id'] : json['academicSession'],
      classId: json['class'] is Map ? json['class']['_id'] : json['class'],
      components: (json['components'] as List?)
          ?.map((c) => FeeComponent.fromJson(c))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academicSessionId': academicSessionId,
      'classId': classId,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}
