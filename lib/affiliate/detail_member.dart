import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailMemberScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailMemberScreen({Key? key, required this.data}) : super(key: key);

  @override
  _DetailMemberScreenState createState() => _DetailMemberScreenState();
}

class _DetailMemberScreenState extends State<DetailMemberScreen> {
  List<Map<String, dynamic>> _riwayatTransaksi = [];
  StreamSubscription<List<Map<String, dynamic>>>? _affiliateLogSubscription;

  bool _isLoadingRiwayat = true;

  Stream<List<Map<String, dynamic>>>? _affiliatePointLogStream;
  String? _currentAffiliateId; // ID affiliate yang login

  // Variabel lokal untuk UI dropdown
  int kelipatan = 10;
  int _selectedPercentage = 10;
  final int maxPersen = 100;

  List<int> get _percentages =>
      List.generate((maxPersen ~/ kelipatan), (index) => (index + 1) * kelipatan);

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _fetchRiwayatTransaksi();
    _getCurrentAffiliateId();
  }

  Future<void> _getCurrentAffiliateId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentAffiliateId = user.id;
      });
    } else {
      print('Tidak ada affiliate yang login.');
    }
  }

  void _setupAffiliatePointLogListener() {
    // Tidak digunakan lagi
  }

  Future<void> _processAffiliatePoints(
      int totalPoinAffiliate, String memberIdToReceivePoints, String? orderId) async {
    // Tidak digunakan lagi
  }

  @override
  void dispose() {
    _affiliateLogSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchRiwayatTransaksi() async {
    final memberId = widget.data['id'];

    try {
      final response = await Supabase.instance.client
          .from('member_points_log')
          .select()
          .eq('member_id', memberId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _riwayatTransaksi = List<Map<String, dynamic>>.from(response);
          _isLoadingRiwayat = false;
        });
      }
    } catch (e) {
      print('Gagal mengambil riwayat transaksi: $e');
      if (mounted) {
        setState(() {
          _isLoadingRiwayat = false;
        });
      }
    }
  }

  String _getNamaBulan(int bulan) {
    const bulanIndo = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return bulanIndo[bulan];
  }

  void _initializeValues() {
    setState(() {
      kelipatan = widget.data['kelipatan'] as int? ?? 10;
      _selectedPercentage = widget.data['presentase'] as int? ?? kelipatan;
    });
  }

  Future<void> _updateKelipatanDanPersentase() async {
    final id = widget.data['id'];
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final response = await Supabase.instance.client.from('members').update({
        'kelipatan': kelipatan,
        'presentase': _selectedPercentage,
        'updated_at': now,
      }).eq('id', id).select();

      if (response.isEmpty) {
        print('Gagal update data: Response kosong');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui pengaturan poin member. Data tidak ditemukan atau tidak diizinkan.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('Kelipatan dan presentase berhasil diupdate di database.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengaturan poin member berhasil diperbarui!'),
          ),
        );
      }
    } catch (e) {
      print('Gagal update data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memperbarui: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.data['users'] ?? {};
    final name = user['username'] ?? 'Tidak diketahui';
    final email = user['email'] ?? '-';
    final status = widget.data['status'] ?? 'Aktif';
    final phone = user['phone'] ?? '-';
    final photoUrl = user['photo_url'] ?? '';

    ImageProvider profileImageProvider;
    if (photoUrl.isEmpty || photoUrl == 'assets/icons/avatar.png') {
      profileImageProvider = AssetImage('assets/profil.png');
    } else if (photoUrl.startsWith('http')) {
      profileImageProvider = NetworkImage(photoUrl);
    } else {
      profileImageProvider = AssetImage(photoUrl);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(
          "Detail Member",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.green,
            height: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(name, email, status, phone, profileImageProvider),
            const SizedBox(height: 20),
            _buildPointSection(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222B45)),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingRiwayat
                      ? const Center(child: CircularProgressIndicator())
                      : _riwayatTransaksi.isEmpty
                          ? Container(
                              height: 120,
                              alignment: Alignment.center,
                              child: const Text(
                                'Belum ada transaksi.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _riwayatTransaksi.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 18, color: Color(0xFFF3F4F8)),
                              itemBuilder: (context, idx) {
                                final log = _riwayatTransaksi[idx];
                                final dateTime = DateTime.parse(log['created_at']);
                                final tanggal =
                                    '${dateTime.day} ${_getNamaBulan(dateTime.month)} ${dateTime.year}';
                                final poin = log['points_earned'] ?? 0;
                                final description = log['description'] as String? ?? 'Transaksi';

                                Color statusColor = Colors.green.shade700;
                                String statusText = 'Terkirim';

                                if (description.contains('Menerima') &&
                                    description.contains('affiliate')) {
                                  statusColor = Colors.green.shade700;
                                  statusText = 'Diterima dari Affiliate';
                                } else if (description.contains('Dikirim')) {
                                  statusColor = Colors.green.shade400;
                                  statusText = 'Dikirim';
                                }

                                // Gradasi hijau untuk semua status
                                Color bgColor = Colors.white;
                                if (statusText == 'Diterima dari Affiliate') {
                                  bgColor = Colors.green.shade50;
                                } else if (statusText == 'Terkirim' || statusText == 'Dikirim') {
                                  bgColor = Colors.green.withOpacity(0.07);
                                }

                                return _buildTransactionItem(
                                  tanggal,
                                  '$poin poin',
                                  statusText,
                                  statusColor,
                                  bgColor,
                                );
                              },
                            ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, String status, String phone,
      ImageProvider imageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF222B45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.email, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(email,
                    style: const TextStyle(
                        color: Color(0xFF555B6A), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(phone,
                    style: const TextStyle(
                        color: Color(0xFF555B6A), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan Point Member',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B45)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text("Kelipatan: ",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: kelipatan,
                borderRadius: BorderRadius.circular(10),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222B45)),
                items: [5, 10, 20, 25].map((k) {
                  return DropdownMenuItem(
                    value: k,
                    child: Text('$k%'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      kelipatan = val;
                      _selectedPercentage = val;
                    });
                    _updateKelipatanDanPersentase();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedPercentage,
            decoration: InputDecoration(
              labelText: 'Pilih Presentase',
              labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222B45)),
            items: _percentages.map((percent) {
              return DropdownMenuItem(
                value: percent,
                child: Text('$percent %'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPercentage = value;
                });
                _updateKelipatanDanPersentase();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      String date, String amount, String status, Color statusColor, Color bgColor) {
    // Gradasi hijau pada background dan badge
    BoxDecoration boxDecoration = BoxDecoration(
      color: bgColor,
      gradient: (status == 'Diterima dari Affiliate')
          ? LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : (status == 'Terkirim' || status == 'Dikirim')
              ? LinearGradient(
                  colors: [Colors.green.withOpacity(0.07), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: statusColor.withOpacity(0.18),
        width: 1.2,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: boxDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'Diterima dari Affiliate'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: statusColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF8F9BB3),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}