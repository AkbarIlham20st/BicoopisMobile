import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'reedem_up.dart';


class RiwayatReedemPage extends StatefulWidget {
  const RiwayatReedemPage({super.key});

  @override
  _RiwayatReedemPageState createState() => _RiwayatReedemPageState();
}

class _RiwayatReedemPageState extends State<RiwayatReedemPage> {
  List<Map<String, dynamic>> redemptionHistory = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRedemptionHistory();
  }

  Future<void> _fetchRedemptionHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            errorMessage = "Anda belum login. Riwayat klaim tidak dapat dimuat.";
            isLoading = false;
          });
        }
        return;
      }

      final memberResponse = await supabase
          .from('members')
          .select('id')
          .eq('id_user', user.id)
          .single();

      if (memberResponse == null || memberResponse['id'] == null) {
        if (mounted) {
          setState(() {
            errorMessage = "Profil member tidak ditemukan.";
            isLoading = false;
          });
        }
        return;
      }

      final actualMemberId = memberResponse['id'] as String;

      final List<dynamic> rawResponse = await supabase
          .from('penukaran_point')
          .select('id, created_at, penukaran_point')
          .eq('member_id', actualMemberId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        redemptionHistory = rawResponse.map((item) => item as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching redemption history: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Gagal memuat riwayat klaim: $e";
          isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat riwayat klaim: ${e.toString()}",
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF078603), Color(0xFF078603)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Riwayat Klaim",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRedemptionHistory,
        color: const Color(0xFF078603),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF078603)))
            : errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchRedemptionHistory,
                  icon: Icon(Icons.refresh),
                  label: Text("Coba Lagi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF078603),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        )
            : redemptionHistory.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, color: Colors.grey[400], size: 60),
                const SizedBox(height: 15),
                Text(
                  "Belum ada riwayat klaim reward.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Mulai klaim reward impianmu sekarang!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: redemptionHistory.length,
          itemBuilder: (context, index) {
            final record = redemptionHistory[index];
            final String transactionId = record['id'] ?? 'N/A';
            final int pointsClaimed = record['penukaran_point'] ?? 0;
            final DateTime claimedDate = (record['created_at'] != null)
                ? DateTime.parse(record['created_at'])
                : DateTime.now();

            final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm');

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: ModalRoute.of(context)!.animation!,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeIn,
                    ),
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    // --- MODIFIKASI PENTING DI SINI ---
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return PopupPage(
                            title: "Detail Klaim", // Anda bisa sesuaikan judul
                            points: pointsClaimed,
                            transactionId: transactionId,
                          );
                        },
                      );
                    },
                    // --- AKHIR MODIFIKASI PENTING ---
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Transaksi ID",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              // Menggunakan full transactionId karena popup akan menampilkannya lengkap
                              Text(
                                "#$transactionId",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Poin Diklaim",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "$pointsClaimed Poin",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tanggal Klaim",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                formatter.format(claimedDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}