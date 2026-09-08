import 'package:jayasha_childrens_academy/core/models/school_class.dart';

class AcademicSession {
  final String? id;
  final String sessionName; // e.g., "2026-2027"
  final String startDate;
  final String endDate;
  final List<SchoolClass> classes;

  AcademicSession({
    this.id,
    required this.sessionName,
    required this.startDate,
    required this.endDate,
    this.classes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionName': sessionName,
      'startDate': startDate,
      'endDate': endDate,
      'classes': classes.map((e) => e.toJson()).toList(),
    };
  }

  factory AcademicSession.fromJson(Map<String, dynamic> json) {
    return AcademicSession(
      id: json['_id'] ?? json['id'],
      sessionName: json['sessionName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      classes: (json['classes'] as List?)
              ?.map((e) => SchoolClass.fromJson(e))
              .toList() ??
          [],
    );
  }
}
