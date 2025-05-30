import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrderModel>> fetchOrdersByStatus(String status) async {
    print('Fetching orders with status: $status');
    try {
      final response = await _client
          .from('history_kasir')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      print('Raw data for $status: $response');

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching $status orders: $e');
      return [];
    }
  }

  Future<void> updateOrderStatus(int id, String newStatus) async {
    await _client
        .from('history_kasir')
        .update({'status': newStatus})
        .eq('id', id);
  }
}
