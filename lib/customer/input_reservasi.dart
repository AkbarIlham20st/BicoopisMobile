import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Diperlukan untuk StreamSubscription

// Ini adalah contoh widget untuk menampilkan hasil reservasi.
// Pastikan ini ada di file yang sama atau diimpor dengan benar.
// Contoh: import 'package:your_app_name/screens/hasil_reservasi_screen.dart';
// Saya akan menyertakannya di bawah untuk kelengkapan.
// import 'package:your_app_name/screens/hasil_reservasi_screen.dart';

class ReservationFormScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const ReservationFormScreen({super.key, required this.category});

  @override
  _ReservationFormScreenState createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController waktuController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  bool _isLoading = false;
  String? _currentUserId; // Untuk menyimpan ID pengguna dari auth.users
  StreamSubscription<AuthState>? _authStateSubscription; // Untuk mendengarkan perubahan status autentikasi

  @override
  void initState() {
    super.initState();
    _getInitialUserId(); // Ambil ID pengguna saat inisialisasi
    _listenToAuthChanges(); // Dengarkan perubahan status autentikasi
  }

  void _getInitialUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      // Opsional: Isi nama dari profil pengguna jika tersedia
      _fetchUserName(user.id);
    }
  }

  // Metode untuk mengambil nama pengguna dari tabel 'members'
  Future<void> _fetchUserName(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('members') // Sesuaikan dengan nama tabel profil Anda
          .select('nama_lengkap') // Sesuaikan dengan kolom nama di tabel members Anda
          .eq('id', userId) // Mencari berdasarkan primary key 'id' di tabel members
          .single(); // Mengambil satu baris saja

      if (response != null && response['nama_lengkap'] != null) {
        namaController.text = response['nama_lengkap'] as String;
      }
    } catch (e) {
      print('Error fetching user name from members table: $e');
      // Tidak perlu menampilkan SnackBar di sini, karena ini hanya pengisian awal
    }
  }

  void _listenToAuthChanges() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _currentUserId = data.session?.user?.id;
      });
      if (_currentUserId == null) {
        // Jika pengguna logout saat di form ini, bisa arahkan kembali ke Home atau Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda telah logout. Silakan login kembali untuk reservasi.')),
        );
        // Opsional: Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Jika pengguna baru saja login (setelah logout), coba isi nama
        _fetchUserName(_currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    namaController.dispose();
    tanggalController.dispose();
    waktuController.dispose();
    jumlahController.dispose();
    keteranganController.dispose();
    _authStateSubscription?.cancel(); // Batalkan langganan saat widget dibuang
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF078603),
            colorScheme: const ColorScheme.light(primary: Color(0xFF078603)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF078603),
            colorScheme: const ColorScheme.light(primary: Color(0xFF078603)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      waktuController.text = DateFormat('HH:mm').format(dt);
    }
  }

  Future<void> _submitReservation() async {
    final nama = namaController.text.trim();
    final tanggal = tanggalController.text.trim();
    final waktu = waktuController.text.trim();
    final jumlah = jumlahController.text.trim();
    final keterangan = keteranganController.text.trim();
    final namaTempat = widget.category['name'];

    // Validasi input
    if (nama.isEmpty || tanggal.isEmpty || waktu.isEmpty || jumlah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi semua field yang diperlukan.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');

    if (!dateRegex.hasMatch(tanggal) || !timeRegex.hasMatch(waktu)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Format tanggal (dd/mm/yyyy) atau waktu (HH:mm) tidak valid.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Pastikan _currentUserId tidak null sebelum mencoba submit
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Anda belum login atau sesi telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Validasi jumlah harus angka
    int? parsedJumlah = int.tryParse(jumlah);
    if (parsedJumlah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Jumlah orang harus berupa angka.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.from('reservasii').insert({
        'nama_pengguna': nama,
        'tanggal': _formatDateForSupabase(tanggal),
        'waktu': waktu,
        'jumlah_orang': parsedJumlah, // Menggunakan int.parse() yang sudah divalidasi
        'keterangan': keterangan,
        'nama_tempat': namaTempat,
        'created_at': DateTime.now().toIso8601String(),
        'member_id': _currentUserId, // Mengirim ID pengguna yang login
      }).select(); // Gunakan .select() untuk mendapatkan data yang dimasukkan jika perlu

      if (response == null || response.isEmpty) {
        // Ini mungkin terjadi jika .select() tidak mengembalikan data, tapi insert berhasil
        // atau jika ada error di Supabase tapi tidak dilempar sebagai PostgrestException.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menyimpan reservasi. Coba lagi.'),
              backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reservasi berhasil disimpan!'),
              backgroundColor: Colors.green),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HasilReservasiScreen(
              nama: nama,
              tanggal: tanggal,
              waktu: waktu,
              jumlah: jumlah,
              keterangan: keterangan,
              namaTempat: namaTempat,
            ),
          ),
        );

        // Bersihkan controllers setelah submit berhasil dan navigasi
        namaController.clear();
        tanggalController.clear();
        jumlahController.clear();
        waktuController.clear();
        keteranganController.clear();
      }
    } on PostgrestException catch (e) {
      print('PostgrestError: ${e.message}, Code: ${e.code}, Details: ${e.details}');
      String errorMessage = 'Terjadi kesalahan saat menyimpan reservasi.';
      if (e.code == '23503' && e.message.contains('reservasii_member_id_fkey')) {
        errorMessage = 'Gagal: ID pengguna belum terdaftar di profil member. Mohon login ulang atau hubungi admin.';
      } else {
        errorMessage = 'Kesalahan database: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red),
      );
    } catch (error) {
      print('Error menyimpan reservasi: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Terjadi kesalahan umum: ${error.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateForSupabase(String dateString) {
    // Mengubah format dd/MM/yyyy menjadi yyyy-MM-dd
    try {
      final DateTime parsedDate = DateFormat('dd/MM/yyyy').parseStrict(dateString);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print('Error parsing date for Supabase: $e');
      return dateString; // Kembali ke string asli jika parsing gagal
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    appBar: AppBar(
      backgroundColor: Color(0xFF078603), // Warna hijau untuk AppBar
      foregroundColor: Colors.white, // Membuat teks dan ikon jadi putih
      centerTitle: true,
      title: Text('Reservasi ${widget.category['name']}'),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buat Reservasi Anda',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF078603),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: Text(
                'Lengkapi detail di bawah ini untuk memesan di ${widget.category['name']}.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildRoundedTextField(
                    labelText: 'Nama Pemesan',
                    hintText: 'Masukkan nama Anda',
                    controller: namaController,
                    icon: Icons.person_outline,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Tanggal Reservasi',
                    hintText: 'Format: dd/mm/yyyy',
                    controller: tanggalController,
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.none,
                    onTap: _selectDate,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Waktu Reservasi',
                    hintText: 'Format: HH:mm (24 jam)',
                    controller: waktuController,
                    icon: Icons.access_time_outlined,
                    keyboardType: TextInputType.none,
                    onTap: _selectTime,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Jumlah Orang',
                    hintText: 'Masukkan jumlah orang',
                    controller: jumlahController,
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Keterangan (Opsional)',
                    hintText: 'Catatan tambahan seperti preferensi meja, dll.',
                    controller: keteranganController,
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF078603)),
                          )
                        : ElevatedButton.icon(
                            onPressed: _submitReservation,
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: const Text(
                              'Konfirmasi Reservasi',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                             style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF078603), // Warna hijau custom
                            padding: const EdgeInsets.symmetric(vertical: 14), // Opsional: tinggi tombol
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Opsional: sudut membulat
                            ),
                          ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedTextField({
    required String labelText,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: onTap != null, // Membuat TextField readOnly jika ada onTap
        onTap: onTap,
        cursorColor: const Color(0xFF078603),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

// --- HasilReservasiScreen (Sertakan juga ini jika belum ada di file terpisah) ---

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bukti Reservasi'),
        backgroundColor: const Color(0xFF078603),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: const Color(0xFF078603), size: 80),
            const SizedBox(height: 10),
            Text(
              'Reservasi Berhasil!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF078603),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Terima kasih, $nama! Reservasi Anda untuk $namaTempat akan dikonfirmasi lebih lanjut.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nama Pemesan:', nama, Icons.person_outline),
                    _buildDetailRow('Tanggal Reservasi:', tanggal, Icons.calendar_today_outlined),
                    _buildDetailRow('Waktu Reservasi:', waktu, Icons.access_time_outlined),
                    _buildDetailRow('Jumlah Orang:', jumlah, Icons.people_outline),
                    if (keterangan.isNotEmpty)
                      _buildDetailRow('Keterangan:', keterangan, Icons.note_outlined),
                    const SizedBox(height: 10),
                    _buildDetailRow('Tempat Reservasi:', namaTempat, Icons.location_on_outlined),
                  ],
                ),
              ),
            ),
           const SizedBox(height: 30),
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () => _kirimKeWhatsApp(context),
    icon: Image.asset(
      'assets/whatsapp.png',
      width: 24,
      height: 24,
      color: Colors.white,
    ),
    label: const Text(
      'Lanjutkan ke WhatsApp',
      style: TextStyle(color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF078603),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),
const SizedBox(height: 10),
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    },
    icon: const Icon(Icons.home_outlined, color: Colors.white),
    label: const Text(
      'Kembali ke Beranda',
      style: TextStyle(color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF078603),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[700], size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _kirimKeWhatsApp(BuildContext context) async {
    final pesan = '''
Halo, saya ingin konfirmasi reservasi:
📍 Tempat: $namaTempat
👤 Nama: $nama
📅 Tanggal: $tanggal
⏰ Waktu: $waktu
👥 Jumlah Orang: $jumlah
📝 Keterangan: ${keterangan.isEmpty ? '-' : keterangan}

Terima kasih.
''';

    const nomorTujuan = '6281230735844'; // Ganti dengan nomor WhatsApp tujuan Anda

    final url = Uri.parse(
        'https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}');

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print("WhatsApp terbuka");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstall.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Terjadi kesalahan saat membuka WhatsApp.'),
            backgroundColor: Colors.red),
      );
      print("Error launching WhatsApp: $e");
    }
  }
}