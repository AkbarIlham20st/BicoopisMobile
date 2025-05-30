import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_detail_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Page'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'In Order'),
            Tab(text: 'In Process'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(provider.inOrderList, provider),
          _buildOrderList(provider.inProcessList, provider),
          _buildOrderList(provider.completedList, provider),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, OrderProvider provider) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Order No: ${order.orderNo}'),
            subtitle: Text(
                'Meja: ${order.nomorMeja} | Total: Rp${order.totalHarga.toStringAsFixed(0)}'),
            trailing: Text(order.status),
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailPage(order: order),
                ),
              );

              // Perbarui data jika user mengubah status
              if (shouldRefresh == true) {
                provider.fetchAllOrders();
              }
            },
          ),
        );
      },
    );
  }
}
