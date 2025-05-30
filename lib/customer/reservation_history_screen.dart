import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _reservationsFuture;
  String? _currentUserId;

  // Define the original dominant green color palette
  static const Color originalGreen = Color(0xFF078603);
  static const Color originalDarkGreen = Color(0xFF056E02); // A slightly darker shade for gradient
  static const Color originalLightGreen = Color(0xFFE0F2F1); // A very light, almost white green for background
  static const Color originalAccentGreen = Color(0xFF8BC34A); // A brighter, distinct green for accents

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_currentUserId != null) {
      _reservationsFuture = _fetchUserReservations(_currentUserId!);
    } else {
      _reservationsFuture = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserReservations(
      String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('reservasii')
          .select()
          .eq('member_id', userId)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Unexpected response format from Supabase');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      return [];
    }
  }

  Future<void> _deleteReservation(String id) async {
    try {
      await Supabase.instance.client.from('reservasii').delete().eq('id', id);
      if (mounted) {
        setState(() {
          _reservationsFuture = _fetchUserReservations(_currentUserId!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reservasi berhasil dihapus.'),
            backgroundColor: originalGreen, // Consistent green for success
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus reservasi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hapus Reservasi",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus reservasi ini? Tindakan ini tidak dapat dibatalkan.",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Batal", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 3,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteReservation(id);
            },
            child: Text("Hapus", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: originalLightGreen, // Light green for the background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [originalGreen, originalDarkGreen], // Original green gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
             borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), // Sudut melengkung kiri bawah
            bottomRight: Radius.circular(20), // Sudut melengkung kanan bawah
          ),
          ),
        ),
        title: Text(
          'Riwayat Reservasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentUserId == null
          ? _buildMessage('Anda harus login untuk melihat riwayat reservasi.')
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: originalGreen), // Original green loader
                  );
                } else if (snapshot.hasError) {
                  return _buildMessage(
                      'Gagal memuat data: ${snapshot.error.toString()}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildMessage(
                      'Anda belum memiliki riwayat reservasi.');
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data![index];
                      final id = data['id'] ?? '';
                      return Dismissible(
                        key: Key(id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          _confirmDelete(id);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 25),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
                        ),
                        child: _buildReservationCard(data),
                      );
                    },
                  );
                }
              },
            ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 17, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> data) {
    final String namaTempat = data['nama_tempat'] ?? 'N/A';
    final String namaPengguna = data['nama_pengguna'] ?? 'N/A';
    final String tanggal = data['tanggal'] != null
        ? DateFormat('dd MMMEEEE').format(DateTime.parse(data['tanggal'])) // Example with full weekday
        : 'N/A';
    final String waktu = data['waktu'] ?? 'N/A';
    final String jumlahOrang = data['jumlah_orang']?.toString() ?? 'N/A';
    final String keterangan = data['keterangan'] ?? 'Tidak ada keterangan.'; // Added this line
    final String id = data['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, // Cards remain white for contrast
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.8),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.apartment_rounded, color: originalGreen, size: 28), // Original green icon
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  namaTempat,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: originalGreen, // Original green text
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient( // Original accent green gradient for date tag
                    colors: [originalAccentGreen, originalGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: originalAccentGreen.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  tanggal,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Divider(height: 1, thickness: 1.5, color: Colors.grey[200]),
          ),
          _buildInfoRow(Icons.person_outline_rounded, 'Pengguna', namaPengguna),
          _buildInfoRow(Icons.schedule_rounded, 'Waktu', waktu),
          _buildInfoRow(Icons.people_alt_rounded, 'Jumlah', jumlahOrang),
          if (keterangan != 'Tidak ada keterangan.') // Only show if there's actual content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8), // Small space before keterangan
                _buildInfoRow(Icons.notes_rounded, 'Keterangan', keterangan), // New row for keterangan
              ],
            ),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _confirmDelete(id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 24, color: Colors.redAccent.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "Batalkan Reservasi",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.redAccent.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: originalGreen.withOpacity(0.8)), // Icons with original green
          const SizedBox(width: 15),
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}