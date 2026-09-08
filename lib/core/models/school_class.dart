class SchoolClass {
  final String className;
  final List<String> sections;

  SchoolClass({
    required this.className,
    required this.sections,
  });

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'sections': sections,
    };
  }

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      className: json['className'] ?? '',
      sections: List<String>.from(json['sections'] ?? []),
    );
  }
}
