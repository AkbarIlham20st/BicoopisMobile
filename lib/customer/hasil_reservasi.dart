import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HasilReservasiScreen extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String waktu;
  final String jumlah;
  final String keterangan;
  final String namaTempat;

  const HasilReservasiScreen({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
    required this.keterangan,
    required this.namaTempat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan PreferredSize untuk membuat AppBar memiliki bentuk kustom
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 30.0), // Menambah tinggi untuk area lengkungan
        child: ClipPath(
          clipper: _AppBarBottomClipper(), // Clipper baru untuk lengkungan di bagian bawah AppBar
          child: AppBar(
            title: Text(
              'Bukti Reservasi',
              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white, // Warna latar belakang AppBar
            iconTheme: IconThemeData(color: Colors.green[700]), // Warna ikon di AppBar
            elevation: 0, // Menghilangkan shadow pada AppBar
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Konten utama di bawah AppBar, dengan latar belakang melengkung di bagian atasnya
            ClipPath(
              clipper: _RoundedClipper(), // Clipper untuk melengkungkan bagian atas container ini
              child: Container(
                padding: const EdgeInsets.all(20.0),
                color: Colors.grey[100], // Latar belakang yang lebih terang untuk bagian konten
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terima kasih, $nama!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Teks konfirmasi yang diubah
                    Text(
                      'Reservasi Anda untuk $namaTempat akan dikonfirmasi lebih lanjut.',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Detail Reservasi:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem('Nama Pemesan', nama),
                    _buildDetailItem('Tanggal Reservasi', tanggal),
                    _buildDetailItem('Waktu Reservasi', waktu),
                    _buildDetailItem('Jumlah Orang', jumlah),
                    if (keterangan.isNotEmpty) _buildDetailItem('Keterangan', keterangan),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text('Reservasi Anda untuk $namaTempat telah berhasil.'),
            const SizedBox(height: 20),
            const Text('Detail Reservasi:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Nama Pemesan: $nama'),
            Text('Tanggal Reservasi: $tanggal'),
            Text('Waktu Reservasi: $waktu'),
            Text('Jumlah Orang: $jumlah'),
            if (keterangan.isNotEmpty) Text('Keterangan: $keterangan'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _kirimKeWhatsApp(context),
                icon: const Icon(Icons.home),
                label: const Text('Lanjutkan ke WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),

                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk menampilkan detail reservasi
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  // Fungsi untuk mengirim detail reservasi ke WhatsApp
  void _kirimKeWhatsApp(BuildContext context) async {
    final pesan = Uri.encodeComponent('''
Halo, saya ingin konfirmasi reservasi:
📍 Tempat: $namaTempat
👤 Nama: $nama
📅 Tanggal: $tanggal
⏰ Waktu: $waktu
👥 Jumlah Orang: $jumlah
📝 Keterangan: ${keterangan.isEmpty ? '-' : keterangan}
''');

    const nomorTujuan = '6281230735844'; // Ganti dengan nomor tujuan yang sesuai
    final url = 'https://wa.me/$nomorTujuan?text=$pesan';

    // Memeriksa apakah URL dapat diluncurkan sebelum mencoba meluncurkannya
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Menampilkan SnackBar jika WhatsApp tidak dapat dibuka
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }
}

// Custom Clipper untuk melengkungkan bagian atas konten body
class _RoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 20); // Mulai sedikit ke bawah dari kiri atas
    // Membuat lengkungan dari kiri atas ke kanan atas
    path.quadraticBezierTo(size.width / 2, 0, size.width, 20);
    path.lineTo(size.width, size.height); // Garis ke kanan bawah
    path.lineTo(0, size.height); // Garis ke kiri bawah
    path.close(); // Menutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false; // Tidak perlu reclip kecuali ukuran berubah
  }
}

// Custom Clipper baru untuk melengkungkan bagian bawah AppBar
class _AppBarBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height); // Mulai dari kiri atas ke kiri bawah
    // Membuat lengkungan ke atas di bagian bawah AppBar
    path.quadraticBezierTo(size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0); // Garis ke kanan atas
    path.close(); // Menutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false; // Tidak perlu reclip kecuali ukuran berubah
  }
}