import 'enums.dart';

/// A person associated with a paper, together with the role they hold on it.
class Author {
  final String id;
  final String name;
  final String email;
  final String affiliation;
  final UserRole role;

  const Author({
    required this.id,
    required this.name,
    this.email = '',
    this.affiliation = '',
    this.role = UserRole.author,
  });

  Author copyWith({
    String? name,
    String? email,
    String? affiliation,
    UserRole? role,
  }) {
    return Author(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      affiliation: affiliation ?? this.affiliation,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'affiliation': affiliation,
        'role': role.name,
      };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        affiliation: json['affiliation'] as String? ?? '',
        role: userRoleFromName(json['role'] as String?),
      );
}
