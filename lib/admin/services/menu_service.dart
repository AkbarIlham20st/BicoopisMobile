import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';

class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MenuModel>> fetchMenusByCategory(String category) async {
    final response = await _client
        .from('menu') // pastikan ini nama tabel di Supabase kamu
        .select()
        .eq('kategori', category)
        .order('created_at', ascending: false);

    final data = response;
    return (data as List)
        .map((menuJson) => MenuModel.fromJson(menuJson))
        .toList();
  }

  Future<void> addMenu(MenuModel menu) async {
    final now = DateTime.now().toIso8601String();

    final data = {
      'nama_menu': menu.title,
      'deskripsi_menu': menu.description,
      'harga_menu': menu.price,
      'foto_menu': menu.imageUrl,
      'kategori': menu.category,
      'id_kategori_menu': menu.categoryId,
      'created_at': now,
      'updated_at': now,
    };

    final response = await _client.from('menu').insert(data);
    print('Insert response: $response');
  }


  Future<void> updateMenu(String id, MenuModel menu) async {
    await _client
        .from('menu')
        .update(menu.toJson())
        .eq('id_menu', id);
  }

  Future<void> deleteMenu(String id) async {
    await _client.from('menu').delete().eq('id_menu', id);
  }
}
