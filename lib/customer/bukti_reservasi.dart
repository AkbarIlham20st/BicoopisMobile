import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HasilReservasiScreen extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String waktu;
  final String jumlah;
  final String keterangan;

  const HasilReservasiScreen({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
    required this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reservasi",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF078603),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80, // Tinggi AppBar ditingkatkan
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Membuat AppBar melengkung di bawah
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Announcement",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Screenshot bukti reservasi dan kirimkan bukti kepada WhatsApp untuk melakukan konfirmasi dan pembayaran.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Gambar & Detail Singkat dengan Border Radius
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                    child: Image.asset(
                      'assets/reservasi1.png',
                      width: 100, // Lebih besar agar proporsional
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kursi Deretan Depan",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Kapasitas 20 Orang",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Reservasi dengan Border Radius
            Container(
              padding: const EdgeInsets.all(
                  16), // Padding lebih besar agar lebih nyaman
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Reservasi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow("Nama", nama),
                  _buildDetailRow("Tanggal", tanggal),
                  _buildDetailRow("Waktu", waktu),
                  _buildDetailRow("Jumlah", jumlah),
                  _buildDetailRow(
                      "Keterangan",
                      keterangan.isNotEmpty
                          ? keterangan
                          : "Tidak ada keterangan"),
                ],
              ),
            ),

            const Spacer(),

            // Tombol Hubungi Sekarang dengan Border Radius
            Center(
              child: SizedBox(
                width: double.infinity, // Tombol memenuhi lebar parent
                child: TextButton(
                  onPressed: () {
                    _openWhatsApp();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF078603),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Tinggi tombol lebih besar
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon_wa.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Hubungi Sekarang",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.black, fontSize: 16)),
        ],
      ),
    );
  }

  void _openWhatsApp() async {
    const phoneNumber = "6289601480086"; // Ganti dengan nomor WhatsApp tujuan
    final message = Uri.encodeComponent(
        "Halo, saya ingin mengkonfirmasi reservasi atas nama $nama pada tanggal $tanggal pukul $waktu.");
    final url = "https://wa.me/$phoneNumber?text=$message";

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw "Could not launch $url";
    }
  }
}
