import 'package:flutter/foundation.dart';

class KasirModel {
  final String id;
  final String email;
  final String phone;
  final String username;
  final String password;
  final String photoUrl;

  KasirModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
    required this.photoUrl,
  });
}