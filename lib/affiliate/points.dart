import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';
import 'popup.dart';
import 'notifikasi.dart';
import 'profil.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  _PointsScreen createState() => _PointsScreen();
}

class _PointsScreen extends State<PointsScreen> {
  int _currentIndex = 1;
  int? currentPoints;

  String? _currentAffiliateId;
  List<Map<String, dynamic>> rewards = [];
  bool isLoading = true;
  final Uuid _uuid = const Uuid();


  @override
  void initState() {
    super.initState();

    _fetchAffiliateId().then((_) {
      fetchAllData();

    });
  }

  Future<void> fetchAllData() async {
    // fetchPointsFromSupabase akan menggunakan user.id,
    // yang akan mendapatkan total_points dari afiliasi yang terkait.
    await fetchPointsFromSupabase();
    await fetchRewardsFromSupabase();
    setState(() {
      isLoading = false;
    });
  }


  Future<void> _fetchAffiliateId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {

        print('User not logged in. Cannot fetch affiliate ID.');

        setState(() {
          _currentAffiliateId = null;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('affiliates')

         

          .select('id') // <--- Ambil kolom 'id' dari tabel affiliates
          .eq('id_user', user.id) // <--- Cari berdasarkan 'id_user' dari Supabase Auth

          .maybeSingle();

      setState(() {
        if (response != null && response['id'] != null) {
          _currentAffiliateId = response['id'] as String;


          print('DEBUG: Fetched _currentAffiliateId (affiliates.id): $_currentAffiliateId');
        } else {
          _currentAffiliateId = null;
          print('Affiliate ID not found for user: ${user.id}. Attempting to create new entry.');
          // Jika afiliasi tidak ditemukan, buat entri baru untuk user ini

          _createAffiliateEntry(user.id);
        }
      });
    } catch (e) {

      print('Error fetching affiliate ID: $e');

      setState(() {
        _currentAffiliateId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching affiliate ID: $e')),
      );
    }
  }


  // Fungsi untuk membuat entri baru di tabel affiliates jika user belum memiliki
  Future<void> _createAffiliateEntry(String userId) async {
    try {
      final newAffiliateId = _uuid.v4(); // Generate UUID baru untuk kolom 'id'
      await Supabase.instance.client.from('affiliates').insert({
        'id': newAffiliateId,      // Ini akan menjadi Primary Key yang dirujuk
        'id_user': userId,        // Ini adalah user.id dari Supabase Auth
        'total_points': 0,        // Nilai awal poin
      });
      setState(() {
        _currentAffiliateId = newAffiliateId;
        currentPoints = 0; // Inisialisasi poin menjadi 0 juga
      });
      print('New affiliate entry created with ID: $newAffiliateId for user: $userId');
    } catch (e) {
      print('Error creating affiliate entry: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating affiliate entry: $e')),
      );
    }
  }


  Future<void> fetchPointsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('User not logged in. Cannot fetch points.');
        return;
      }

      final response = await Supabase.instance.client
          .from('affiliates')
          .select('total_points')
          .eq('id_user', user.id)
          .maybeSingle();

      if (response != null && response['total_points'] != null) {
        setState(() {
          currentPoints = response['total_points'];
        });
      } else {


        // Jika tidak ada points ditemukan, set ke 0
        setState(() {
          currentPoints = 0;
        });
        print('No points found for user: ${user.id}');
        // Perbaikan: Jika _currentAffiliateId masih null setelah fetch,
        // coba buat entri baru (opsional, karena sudah ditangani di _fetchAffiliateId)
        if (_currentAffiliateId == null) {
          _createAffiliateEntry(user.id);
        }
      }
    } catch (e) {

      print('Error fetching points: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching points: $e')),
      );
    }
  }

  Future<void> fetchRewardsFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('klaim_rewards')
          .select();

      setState(() {
        rewards = List<Map<String, dynamic>>.from(response).map((r) {
          return {
            "title": r['judul'] ?? '',
            "description": r['deskripsi'] ?? '',
            "points": r['points'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {

      print('Error fetching rewards: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rewards: $e')),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // BG full putih
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Points',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.green, // Garis hijau seperti di home
            height: 2.0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),

                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Point Saat Ini",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentPoints != null ? "$currentPoints" : "0",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: rewards.isEmpty
                      ? Center(
                          child: Text(
                            "Tidak ada reward tersedia",
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            return _buildRewardCard(
                              context,
                              reward["title"],
                              reward["description"],
                              reward["points"],
                            );
                          },
                        ),
                ),
              ],
            ),


      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifikasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],

      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, String title, String description, int points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.13),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 4),
          Text(description,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("$points Points",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ),
              ElevatedButton(
                onPressed: currentPoints != null && currentPoints! >= points
                    ? () => showRedeemDialog(context, title, points, description)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text("Klaim reward",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showRedeemDialog(BuildContext context, String title, int points, String description) {
    if (currentPoints! < points) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Poin Tidak Cukup"),
            content: const Text("Maaf, poin Anda tidak cukup untuk menukar reward ini."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Penukaran"),
          content: Text("Tukar $points poin untuk $title?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final user = Supabase.instance.client.auth.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anda harus login untuk menukar reward.')),
                  );
                  return;
                }



                if (_currentAffiliateId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: ID afiliasi tidak ditemukan. Coba restart aplikasi atau login ulang.')),
                  );

                  print('Error: _currentAffiliateId is NULL when trying to open PopupPage.');
                  return;
                }

                //int updatedPoints = currentPoints! - points;
                //try {
                  //await Supabase.instance.client
                    //  .from('affiliates')
                      //.update({'total_points': updatedPoints})
                      //.eq('id_user', user.id);

                  //setState(() {
                    //currentPoints = updatedPoints;
                  //});
                //} catch (e) {
                  //print('Error updating points: $e');
                  //ScaffoldMessenger.of(context).showSnackBar(
                    //SnackBar(content: Text('Gagal memperbarui poin: $e')),
                  //);
                  //return;
                //}

                String transactionId = _uuid.v4();
                String affiliateIdToSend = _currentAffiliateId!; // <--- Kirim ID afiliasi yang BENAR


                final bool? redemptionSuccessful = await showDialog<bool>(
                  context: context,
                  builder: (context) => PopupPage(
                    title: title,
                    points: points,
                    transactionId: transactionId,

                    affiliateId: affiliateIdToSend, // <--- Gunakan ID afiliasi yang sudah diambil

                    description: description,
                  ),
                );

                if (redemptionSuccessful == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Penukaran berhasil dicatat!')),


                  );
                  await fetchPointsFromSupabase(); // Perbarui poin setelah sukses
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pencatatan penukaran gagal atau dibatalkan.')),
                  );
                  // Opsional: Jika pencatatan gagal, pertimbangkan untuk mengembalikan poin
                  // await Supabase.instance.client
                  //   .from('affiliates')
                  //   .update({'total_points': currentPoints! + points}) // Kembalikan poin
                  //   .eq('id_user', user.id);
                  // setState(() {
                  //   currentPoints = currentPoints! + points;
                  // });
                }
              },
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
  }
}