import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopupPage extends StatefulWidget { // Nama kelas tetap PopupPage seperti di import
  final String title;
  final int points;
  final String transactionId; // Ini akan menerima ID dari Supabase

  const PopupPage({
    super.key,
    required this.title,
    required this.points,
    required this.transactionId,
  });

  @override
  State<PopupPage> createState() => _PopupPageState(); // Nama state disesuaikan
}

class _PopupPageState extends State<PopupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Mulai animasi saat widget diinisialisasi
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          false, // Mencegah dialog tertutup dengan tombol kembali fisik selama animasi
      child: Center(
        child: Material(
          color: Colors.transparent, // Membuat latar belakang material transparan
          child: ScaleTransition(
            scale: _scaleAnimation, // Menggunakan animasi scale kustom
            child: FadeTransition(
              opacity: _fadeAnimation, // Menggunakan animasi fade kustom
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.receipt_long,
                          size: 60, color: Colors.green[400]),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Tanda Terima Penukaran",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(thickness: 1, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "ID Penukaran",
                      style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.transactionId, // Mengambil ID transaksi dari properti widget
                      style: GoogleFonts.nunitoSans(
                          color: Colors.black87, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Penukaran Point",
                      style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.sync, size: 20, color: Colors.green[400]),
                        const SizedBox(width: 8),
                        Text("${widget.points} POIN", // Mengambil poin dari properti widget
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Membalik animasi sebelum menutup dialog
                          _controller.reverse().then((_) {
                            Navigator.pop(context);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF078603),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}