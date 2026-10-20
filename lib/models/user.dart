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
}