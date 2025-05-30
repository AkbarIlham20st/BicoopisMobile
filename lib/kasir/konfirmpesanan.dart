import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPesananPage extends StatefulWidget {
  final String idPemesanan;

  const DetailPesananPage({super.key, required this.idPemesanan});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? pesanan;
  bool loading = true;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    fetchPesanan();
  }

  Future<void> fetchPesanan() async {
    try {
      final data = await supabase
          .from('orderkasir_history')
          .select()
          .eq('order_no', widget.idPemesanan)
          .single();

      setState(() {
        pesanan = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  Future<void> konfirmasiPembayaran() async {
    setState(() {
      updating = true;
    });

    try {
      // Update status_pembayaran menjadi 'selesai'
      await supabase
          .from('orderkasir_history')
          .update({'status_pembayaran': 'selesai'})
          .eq('order_no', widget.idPemesanan);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil dikonfirmasi')),
      );

      // Kembali ke halaman sebelumnya dan kirim nilai true
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal konfirmasi pembayaran: $e')),
      );
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailItems = (pesanan?['items'] is List)
        ? pesanan!['items'] as List<dynamic>
        : null;

    int jumlahItem = 0;
    int subtotal = 0;

    if (detailItems != null) {
      for (var item in detailItems) {
        final quantity = (item['quantity'] ?? 0) as int;
        final price = (item['price'] ?? 0) as int;
        jumlahItem += quantity;
        subtotal += price * quantity;
      }
    }

    final ppn = (subtotal * 0.10).round();
    final totalPembayaran = subtotal + ppn;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pesanan == null
          ? const Center(child: Text('Data pesanan tidak ditemukan'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Informasi Pemesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Nama Customer: ${pesanan!['nama_pelanggan'] ?? '-'}'),
            Text('ID Pemesanan: ${pesanan!['id_pemesanan'] ?? '-'}'),
            Text('Nomor Order: ${pesanan!['order_no'] ?? '-'}'),
            const SizedBox(height: 16),
            const Text('Daftar Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.grey[300],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(flex: 4, child: Text('Nama Menu', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Harga', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Total', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            if (detailItems != null)
              ...detailItems.map((item) {
                final itemName = item['item_name'] ?? '-';
                final quantity = item['quantity'] ?? 0;
                final price = item['price'] ?? 0;
                final total = price * quantity;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 4, child: Text(itemName)),
                      Expanded(flex: 2, child: Text(quantity.toString())),
                      Expanded(flex: 2, child: Text('Rp$price', textAlign: TextAlign.end)),
                      Expanded(flex: 3, child: Text('Rp$total', textAlign: TextAlign.end)),
                    ],
                  ),
                );
              }).toList()
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Tidak ada data menu.'),
              ),
            const SizedBox(height: 16),
            const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Item :'),
                Text('$jumlahItem'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal :'),
                Text('Rp$subtotal'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PPN 10% :'),
                Text('Rp$ppn'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran :', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp$totalPembayaran', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: updating ? null : konfirmasiPembayaran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: updating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
