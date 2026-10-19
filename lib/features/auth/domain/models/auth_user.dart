import 'dart:convert';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'ADMIN', 'AGRONOMIST', 'OPERATOR'
  final String accessToken;
  final String? refreshToken;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
    this.refreshToken,
  });

  String get roleDisplayName {
    switch (role) {
      case 'ADMIN':
        return 'Administrador';
      case 'AGRONOMIST':
        return 'Engenheiro(a) Agrônomo(a)';
      case 'OPERATOR':
        return 'Técnico de Campo';
      default:
        return role;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map, {String? token, String? refreshToken}) {
    return AuthUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'OPERATOR',
      accessToken: token ?? map['accessToken'] ?? '',
      refreshToken: refreshToken ?? map['refreshToken'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AuthUser.fromJson(String source) => AuthUser.fromMap(jsonDecode(source));
}
