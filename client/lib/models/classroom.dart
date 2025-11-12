class ClassroomStudent {
  const ClassroomStudent({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;

  factory ClassroomStudent.fromJson(Map<String, dynamic> json) {
    return ClassroomStudent(
      id: json['id'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}

class ClassroomInfo {
  const ClassroomInfo({
    required this.id,
    required this.code,
    required this.name,
    this.teacherName,
    this.students = const [],
    this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String? teacherName;
  final List<ClassroomStudent> students;
  final DateTime? createdAt;

  int get studentCount => students.length;

  ClassroomInfo copyWith({
    String? code,
    String? name,
    String? teacherName,
    List<ClassroomStudent>? students,
    DateTime? createdAt,
  }) {
    return ClassroomInfo(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      teacherName: teacherName ?? this.teacherName,
      students: students ?? this.students,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ClassroomInfo.fromJson(Map<String, dynamic> json) {
    return ClassroomInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      name: (json['name'] as String?) ?? '',
      teacherName: json['teacher'] == null
          ? null
          : (json['teacher'] as Map<String, dynamic>)['username'] as String?,
      students: (json['students'] as List<dynamic>? ?? [])
          .map((data) => ClassroomStudent.fromJson(data as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      if (teacherName != null) 'teacherName': teacherName,
      'students': students.map((s) => s.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
