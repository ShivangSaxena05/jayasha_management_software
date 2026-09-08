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
  final Map<String, double> feeStructure;
  final List<List<TimetableEntry?>> timetable; // [Period][Day]
  final List<String> sections;

  SchoolClass({
    this.id,
    required this.name,
    required this.classTeacher,
    this.assistantTeacher,
    required this.feeStructure,
    required this.timetable,
    this.sections = const [],
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

    return SchoolClass(
      id: json['_id'],
      name: json['name'] ?? '',
      classTeacher: json['classTeacher'] ?? 'Not Assigned',
      assistantTeacher: json['assistantTeacher'],
      feeStructure: {},
      timetable: List.generate(6, (p) => List.generate(6, (d) => null)),
      sections: parsedSections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'classTeacher': classTeacher,
      'assistantTeacher': assistantTeacher,
      'sections': sections,
    };
  }

  SchoolClass copyWith({
    String? id,
    String? name,
    String? classTeacher,
    String? assistantTeacher,
    Map<String, double>? feeStructure,
    List<List<TimetableEntry?>>? timetable,
    List<String>? sections,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      classTeacher: classTeacher ?? this.classTeacher,
      assistantTeacher: assistantTeacher ?? this.assistantTeacher,
      feeStructure: feeStructure ?? this.feeStructure,
      timetable: timetable ?? this.timetable,
      sections: sections ?? this.sections,
    );
  }
}
