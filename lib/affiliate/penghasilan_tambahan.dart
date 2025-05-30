import 'package:bicopi_pos/affiliate/login.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class PenghasilanTambahanScreen extends StatelessWidget {
  const PenghasilanTambahanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: SizedBox()),

            // Gambar utama
            Image.asset(
              'assets/penghasilan_tambahan.png',
              width: 250,
            ),

            const SizedBox(height: 20),

            // Indicator slider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(isActive: false),
                _buildIndicator(isActive: false),
                _buildIndicator(isActive: true),
              ],
            ),

            const SizedBox(height: 20),

            // Judul
            const Text(
              'Penghasilan Tambahan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            // Deskripsi
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Dapatkan komisi dari setiap penjualan! \nTanpa modal, cukup bagikan link \n& mulai hasilkan uang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Tombol Skip
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),

            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  // Widget indikator halaman
  Widget _buildIndicator({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
