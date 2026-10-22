import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'user_role.dart';

/// User account data model representing a Guest, Student, or Admin.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? studentId;
  final String? passwordHash;
  final String? salt;
  final List<String> savedLocationIds;
  final List<String> savedRoomIds;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.studentId,
    this.passwordHash,
    this.salt,
    this.savedLocationIds = const [],
    this.savedRoomIds = const [],
  });

  /// Creates a Guest session user
  factory UserModel.guest() {
    return const UserModel(
      userId: 'user_guest',
      name: 'Guest Visitor',
      email: 'guest@campus.edu',
      role: UserRole.guest,
    );
  }

  /// Hashes a plain password with a given salt using SHA-256
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    return sha256.convert(bytes).toString();
  }

  /// Verifies if a given plain password matches this user's stored hash
  bool verifyPassword(String inputPassword) {
    if (passwordHash == null || salt == null) return false;
    final computed = hashPassword(inputPassword, salt!);
    return computed == passwordHash;
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? studentId,
    String? passwordHash,
    String? salt,
    List<String>? savedLocationIds,
    List<String>? savedRoomIds,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      savedLocationIds: savedLocationIds ?? this.savedLocationIds,
      savedRoomIds: savedRoomIds ?? this.savedRoomIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department,
      'studentId': studentId,
      'passwordHash': passwordHash,
      'salt': salt,
      'savedLocationIds': savedLocationIds,
      'savedRoomIds': savedRoomIds,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.guest,
      ),
      department: json['department'] as String?,
      studentId: json['studentId'] as String?,
      passwordHash: json['passwordHash'] as String?,
      salt: json['salt'] as String?,
      savedLocationIds: (json['savedLocationIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      savedRoomIds: (json['savedRoomIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Authentication result data wrapper
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  const AuthResult.ok(UserModel user) : this(success: true, user: user);
  const AuthResult.failure(String message) : this(success: false, message: message);
}
