import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'konfirmpesanan.dart';

class KonfirmasiPesananScreen extends StatefulWidget {
  const KonfirmasiPesananScreen({super.key});

  @override
  State<KonfirmasiPesananScreen> createState() =>
      _KonfirmasiPesananScreenState();
}

class _KonfirmasiPesananScreenState extends State<KonfirmasiPesananScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      loading = true;
    });

    try {
      final data = await supabase
          .from('orderkasir_history')
          .select()
          .eq('metode_pembayaran', 'tunai')
          .eq('status_pembayaran', 'pending')
          .ilike('nama_pelanggan', '%$searchQuery%');

      orders = (data as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      print('Error fetch: $e');
      orders = [];
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Konfirmasi Pesanan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari Nama Pelanggan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 0),
              ),
              onChanged: (value) {
                searchQuery = value;
                fetchOrders();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                  ? const Center(child: Text('Tidak ada pesanan.'))
                  : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final idPemesanan = order['order_no'] ?? '';
                  final nama = order['nama_pelanggan'] ?? '';
                  final total = order['total_harga'] ?? 0;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama Customer: $nama',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Order No: $idPemesanan',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Total Harga: Rp $total',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPesananPage(
                                      idPemesanan: idPemesanan,
                                    ),
                                  ),
                                );

                                // Jika berhasil dikonfirmasi di halaman detail
                                if (result == true) {
                                  await fetchOrders();
                                }
                              },
                              child: const Text('Konfirmasi',
                                  style: TextStyle(fontSize: 16,color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
