// class AffiliateModel {
//   final String id;
//   // final String name;
//   final String email;
//   final String phone;
//   final String photoUrl;
//   final String username;
//   final String password;
//   final int point;
//   final String referralCode;
//
//   AffiliateModel({
//     required this.id,
//     // required this.name,
//     required this.email,
//     required this.phone,
//     required this.photoUrl,
//     required this.username,
//     required this.password,
//     required this.point,
//     required this.referralCode,
//   });
// }
class AffiliateModel {
  AffiliateModel({
    required this.id,
    required this.totalPoints,
    required this.refferalcode,
    required this.users,
  });

  final String? id;
  final int? totalPoints;
  final String? refferalcode;
  final Users? users;

  factory AffiliateModel.fromJson(Map<String, dynamic> json){
    return AffiliateModel(
      id: json["id"],
      totalPoints: json["total_points"],
      refferalcode: json["referral_code"],
      users: json["users"] == null ? null : Users.fromJson(json["users"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "total_points": totalPoints,
    "referral_code": refferalcode,
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
