import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kasir_model.dart';

class KasirService {
  final supabase = Supabase.instance.client;

  Future<List<KasirModel>> fetchKasirs() async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id_user_level', 3); // ID user_level untuk Kasir
    print('Fetched kasir response: $response');
    return (response as List).map((json) =>
        KasirModel(
          id: json['id_user'],
          email: json['email'],
          phone: json['phone'],
          username: json['username'],
          password: json['password'],
          photoUrl: json['photo_url'],
        )).toList();
  }
}