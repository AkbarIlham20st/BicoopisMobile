import 'package:flutter/material.dart';
import 'input_reservasi.dart'; // Import halaman formulir reservasi

class ReservasiPage extends StatelessWidget {
  const ReservasiPage({super.key, required Map<String, dynamic> selectedItem});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ReservationScreen(),
    );
  }
}

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  final List<Map<String, String>> categories = const [
    {
      'name': 'Lantai 2 Indoor',
      'capacity': 'Untuk Acara bersama keluarga',
      'image': 'assets/indoor2.jpg',
    },
    {
      'name': 'Lantai 2 Outdoor',
      'capacity': 'Kapasitas 20 Orang',
      'image': 'assets/outdoor22.jpg',
    },
    {
      'name': 'Lantai 1 Indoor',
      'capacity': 'Kapasitas 10 Orang',
      'image': 'assets/indoor1.jpg',
    },
    {
      'name': 'Lantai 1 Outdoor',
      'capacity': 'Kapasitas 50 Orang',
      'image': 'assets/outdoor1.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[200],
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(60), // tinggi AppBar
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF078603), // warna hijau
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Text(
              "Reservasi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ), // Menghilangkan tombol back
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // SizedBox ditambahkan di sini
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Daftar Kategori Tempat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigasi ke halaman formulir reservasi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationFormScreen(
                          category: categories[index],
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    // Tambahkan Padding di luar Card untuk memberi ruang shadow
                    padding: const EdgeInsets.only(
                        bottom: 20), // Tambah sedikit jarak bawah
                    child: _buildCategoryCard(categories[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 8, // Tingkatkan nilai elevasi untuk shadow yang lebih jelas
      shadowColor: Colors.grey.withOpacity(0.5), // Gelapkan warna shadow
      margin: EdgeInsets
          .zero, // Hapus margin bawaan Card karena sudah diatur di Padding luar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Gambar dengan border radius
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Image.asset(
                  category['image']!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              // Overlay Gradient
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              // Label kategori "Featured" dengan warna hijau
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF078603), // Warna hijau
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Featured",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category['capacity']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
