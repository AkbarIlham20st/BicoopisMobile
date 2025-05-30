import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<dynamic>> fetchOrders(String status) async {
    final response = await supabase
        .from('history_kasir')
        .select()
        .eq('status', status)
        .order('order_no', ascending: true);
    return response;
  }
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  Widget buildOrderList(String status) {
    return FutureBuilder<List<dynamic>>(
      future: fetchOrders(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Gagal memuat data.'));
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('Tidak ada data.'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text('Order #${order['order_no']}'),
                subtitle: Text('Meja: ${order['nomor_meja']} - Status: ${order['status']}'),

              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.green,       // Warna tab aktif
            unselectedLabelColor: Colors.black, // Warna tab tidak aktif
            indicatorColor: Colors.green,   // Garis bawah tab aktif
            tabs: const [
              Tab(text: 'In Process'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              buildOrderList('In Process'),
              buildOrderList('Completed'),
            ],
          ),
        ),
      ],
    );
  }
}
