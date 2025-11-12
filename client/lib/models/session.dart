class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.status,
    required this.studentsCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String type;
  final String description;
  final String status;
  final int studentsCount;
  final DateTime createdAt;

  bool get isActive => status == 'active';

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'general',
      description: (json['description'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'active',
      studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
