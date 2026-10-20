// models/user.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class User {
  String id;
  String username;
  String password;
  DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  static String hashPassword(String plaintext) {
    final salt = _randomSalt();
    final digest = sha256.convert(utf8.encode('$salt$plaintext'));
    return '$salt:$digest';
  }

  static bool verifyPassword(String plaintext, String stored) {
    final idx = stored.indexOf(':');
    if (idx <= 0 || idx == stored.length - 1) return false;
    final salt = stored.substring(0, idx);
    final expected = stored.substring(idx + 1);
    final actual = sha256.convert(utf8.encode('$salt$plaintext')).toString();
    return actual == expected;
  }

  static String _randomSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64.encode(bytes);
  }
}