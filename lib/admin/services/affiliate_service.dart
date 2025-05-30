import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/affiliate_model.dart';

class AffiliateService {
  final supabase = Supabase.instance.client;

  Future<List<AffiliateModel>> fetchAffiliates() async {
    final response = await supabase
        .from('affiliates')
        .select('''
          id,
          total_points,
          referral_code,
          users (
            email,
            phone,
            username,
            password,
            photo_url,
            id_user_level
          )
        ''');
        // .eq('users.id_user_level', 4);
    print('Fetched affiliate response: $response');
    return (response as List).map((json) => AffiliateModel.fromJson(json)).toList();
  }
}
