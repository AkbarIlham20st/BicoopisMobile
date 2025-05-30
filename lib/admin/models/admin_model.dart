class AdminModel {
  final String id;
  final String email;
  final String username;
  final String password;
  final String role; // Misalnya: 'admin'

  AdminModel({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.role,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
    );
  }
}