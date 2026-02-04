import 'package:equatable/equatable.dart';

enum UserRole { owner, kasir }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.kasir:
        return 'kasir';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.kasir:
        return 'Kasir';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'kasir':
        return UserRole.kasir;
      default:
        return UserRole.kasir;
    }
  }
}

class User extends Equatable {
  final int? id;
  final String username;
  final String passwordHash;
  final String name;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.name,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'name': name,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      name: map['name'] as String,
      role: UserRoleExtension.fromString(map['role'] as String),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? name,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Permission checks
  bool get canManageUsers => role == UserRole.owner;
  bool get canManageServices => role == UserRole.owner;
  bool get canAccessReports => role == UserRole.owner;
  bool get canAccessSettings => role == UserRole.owner;
  bool get canDeleteOrders => role == UserRole.owner;
  bool get canExportData => role == UserRole.owner;

  @override
  List<Object?> get props => [
        id,
        username,
        passwordHash,
        name,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];
}
