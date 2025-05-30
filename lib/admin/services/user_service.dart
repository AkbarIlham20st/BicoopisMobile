import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final supabase = Supabase.instance.client;

  Future<List<UserModel>> fetchUsers() async {
    final response = await supabase.from('members').select('''
          nama_lengkap,
          total_points,
          users (
            id_user,
            email,
            phone,
            username,
            password,
            photo_url,
            id_user_level
          )
        ''');
    // .eq('users.id_user_level', 1);
    print('Fetched user response: $response');
    return (response as List)
        .map(
          (json) => UserModel.fromJson(json)

        )
        .toList();
  }
}
