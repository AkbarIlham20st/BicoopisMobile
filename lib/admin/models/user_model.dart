class UserModel {
  UserModel({
    required this.namaLengkap,
    required this.totalPoints,
    required this.users,
  });

  final String? namaLengkap;
  final int? totalPoints;
  final Users? users;

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      namaLengkap: json["nama_lengkap"],
      totalPoints: json["total_points"],
      users: json["users"] == null ? null : Users.fromJson(json["users"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "nama_lengkap": namaLengkap,
    "total_points": totalPoints,
    "users": users?.toJson(),
  };

}

class Users {
  Users({
    required this.email,
    required this.phone,
    required this.idUser,
    required this.password,
    required this.username,
    required this.photoUrl,
    required this.idUserLevel,
  });

  final String email;
  final String? phone;
  final String? idUser;
  final String? password;
  final String? username;
  final dynamic photoUrl;
  final int? idUserLevel;

  factory Users.fromJson(Map<String, dynamic> json){
    return Users(
      email: json["email"],
      phone: json["phone"],
      idUser: json["id_user"],
      password: json["password"],
      username: json["username"],
      photoUrl: json["photo_url"],
      idUserLevel: json["id_user_level"],
    );
  }

  Map<String, dynamic> toJson() => {
    "email": email,
    "phone": phone,
    "id_user": idUser,
    "password": password,
    "username": username,
    "photo_url": photoUrl,
    "id_user_level": idUserLevel,
  };

}
