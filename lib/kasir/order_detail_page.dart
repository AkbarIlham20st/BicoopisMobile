import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<dynamic> items;

  OrderDetailPage({required this.order, required this.items});

  String formatDate(String? isoString) {
    if (isoString == null) return '-';
    final date = DateTime.parse(isoString).toLocal();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // Warna background AppBar
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white,               // Warna tombol back
        ),// Menengahkan judul
        title: Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,       // Warna teks judul
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order No: ${order['order_no'] ?? "-"}'),
                    Text('Nama: ${order['nama_pelanggan'] ?? "-"}'),
                    Text('Meja: ${order['nomor_meja'] ?? "-"}'),
                    Text('Tanggal: ${formatDate(order['created_at'])}'),
                  ],
                ),
                // Text('Tanggal: ${formatDate(order['created_at'])}'),
              ],
            ),
            Divider(height: 32),
            // Items
            Text('Item Pesanan:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${item['nama_menu'] ?? 'Menu'}')),
                        Text('Qty: ${item['qty'] ?? '-'}'),
                        SizedBox(width: 10),
                        Text('Rp ${item['subtotal'] ?? '-'}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 32),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text('Catatan: ${order['catatan'] ?? "-"}'),
                Text('Total Harga: Rp ${order['total_harga'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
