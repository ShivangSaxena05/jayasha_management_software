import 'package:flutter/foundation.dart';
import 'package:jayasha_childrens_academy/features/fees/data/models/fee_structure.dart';

class TimetableEntry {
  final String subject;
  final String teacherName;

  TimetableEntry({required this.subject, required this.teacherName});

  @override
  String toString() => '$subject ($teacherName)';

  Map<String, dynamic> toJson() => {'subject': subject, 'teacherName': teacherName};

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
    subject: json['subject'] as String,
    teacherName: json['teacherName'] as String,
  );
}

class SchoolClass {
  final String? id;
  final String name;
  final String classTeacher;
  final String? assistantTeacher;
  final List<FeeComponent> feeStructure;
  final int numberOfPeriods;
  final List<List<TimetableEntry?>> timetable; // [Period][Day]
  final List<String> sections;
  final List<String> subjects;

  SchoolClass({
    this.id,
    required this.name,
    required this.classTeacher,
    this.assistantTeacher,
    required this.feeStructure,
    this.numberOfPeriods = 6,
    required this.timetable,
    this.sections = const [],
    this.subjects = const [],
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    // Handle both String list and Object list for sections to be safe
    var sectionsData = json['sections'] as List?;
    List<String> parsedSections = [];
    if (sectionsData != null) {
      parsedSections = sectionsData.map((s) {
        if (s is String) return s;
        if (s is Map && s.containsKey('name')) return s['name'] as String;
        return s.toString();
      }).toList();
    }

    // Parse fee structure
    List<FeeComponent> parsedFees = [];
    if (json['feeStructure'] != null) {
      try {
        if (json['feeStructure'] is List) {
          parsedFees = (json['feeStructure'] as List)
              .map((c) => FeeComponent.fromJson(c))
              .toList();
        } else if (json['feeStructure'] is Map) {
          // Legacy support for Map<String, double>
          (json['feeStructure'] as Map).forEach((key, value) {
            parsedFees.add(FeeComponent(
              name: key,
              amount: (value as num).toDouble(),
              frequency: key.contains('Monthly') ? 'monthly' : 'annually',
            ));
          });
        }
      } catch (e) {
        debugPrint('Error parsing feeStructure: $e');
      }
    }

    // Parse timetable
    int periods = json['numberOfPeriods'] ?? 6;
    List<List<TimetableEntry?>> parsedTimetable = List.generate(periods, (p) => List.generate(6, (d) => null));
    if (json['timetable'] != null) {
      try {
        var ttData = json['timetable'] as List;
        for (int p = 0; p < ttData.length && p < periods; p++) {
          var row = ttData[p] as List;
          for (int d = 0; d < row.length && d < 6; d++) {
            if (row[d] != null) {
              parsedTimetable[p][d] = TimetableEntry.fromJson(row[d]);
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing timetable: $e');
      }
    }

    return SchoolClass(
      id: json['_id'],
      name: json['name'] ?? '',
      classTeacher: json['classTeacher'] ?? 'Not Assigned',
      assistantTeacher: json['assistantTeacher'],
      feeStructure: parsedFees,
      numberOfPeriods: periods,
      timetable: parsedTimetable,
      sections: parsedSections,
      subjects: List<String>.from(json['subjects'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'classTeacher': classTeacher,
      'assistantTeacher': assistantTeacher,
      'sections': sections,
      'subjects': subjects,
      'feeStructure': feeStructure.map((c) => c.toJson()).toList(),
      'numberOfPeriods': numberOfPeriods,
      'timetable': timetable.map((row) => row.map((entry) => entry?.toJson()).toList()).toList(),
    };
  }

  SchoolClass copyWith({
    String? id,
    String? name,
    String? classTeacher,
    String? assistantTeacher,
    List<FeeComponent>? feeStructure,
    int? numberOfPeriods,
    List<List<TimetableEntry?>>? timetable,
    List<String>? sections,
    List<String>? subjects,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      classTeacher: classTeacher ?? this.classTeacher,
      assistantTeacher: assistantTeacher ?? this.assistantTeacher,
      feeStructure: feeStructure ?? this.feeStructure,
      numberOfPeriods: numberOfPeriods ?? this.numberOfPeriods,
      timetable: timetable ?? this.timetable,
      sections: sections ?? this.sections,
      subjects: subjects ?? this.subjects,
    );
  }
}
