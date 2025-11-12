class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.classroomId,
    this.classroomCode,
  });

  final String id;
  final String username;
  final String role;
  final String? classroomId;
  final String? classroomCode;

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  AppUser copyWith({
    String? username,
    String? role,
    String? classroomId,
    String? classroomCode,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      role: role ?? this.role,
      classroomId: classroomId ?? this.classroomId,
      classroomCode: classroomCode ?? this.classroomCode,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      classroomId: json['classroomId'] as String?,
      classroomCode: json['classroomCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      if (classroomId != null) 'classroomId': classroomId,
      if (classroomCode != null) 'classroomCode': classroomCode,
    };
  }
}
