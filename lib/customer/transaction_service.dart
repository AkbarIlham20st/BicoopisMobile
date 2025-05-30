import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionService {
  // Fungsi untuk membuat transaksi QRIS
  Future<void> createTransaction(List<Map<String, dynamic>> cartItems) async {
    // Menghitung total harga keranjang
    double totalAmount = 0;
    for (var item in cartItems) {
      totalAmount += item['price'] * item['quantity'];
    }

    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';  // ID order unik berdasarkan timestamp
    final name = 'Customer Name';  // Bisa diganti dengan data nama pengguna
    final tableNumber = 'A1';  // Ganti sesuai kebutuhan, misalnya meja pengguna

    // Kirim request ke backend untuk membuat transaksi QRIS
    final url = Uri.parse('http://localhost:3000/create-transaction'); // Ganti dengan URL backend kamu jika sudah deploy

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'order_id': orderId,
        'gross_amount': totalAmount,
        'name': name,
        'table_number': tableNumber,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Payment URL: ${data['payment_url']}');
      // Kamu bisa menggunakan URL ini untuk menampilkan QRIS kepada pengguna
    } else {
      print('Failed to create transaction');
    }
  }
}
