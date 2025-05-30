import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KonfirmasiPenukaranPointScreen extends StatefulWidget {
  @override
  _KonfirmasiPenukaranPointScreen createState() =>
      _KonfirmasiPenukaranPointScreen();
}

class _KonfirmasiPenukaranPointScreen extends State<KonfirmasiPenukaranPointScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  List<dynamic> penukaranPointsBelumKonfirmasi = [];
  List<dynamic> penukaranPointsRiwayat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    fetchPenukaranPoints();
  }

  Future<void> fetchPenukaranPoints() async {
    setState(() => isLoading = true);
    try {
      // Data yang belum dikonfirmasi (is_confirmed null atau kosong)
      final belumKonfirmasi = await supabase
          .from('penukaran_point')
          .select('id, member_id, penukaran_point, redeemet_at, is_confirmed')
          .or('is_confirmed.is.null,is_confirmed.eq.')
          .order('redeemet_at', ascending: false);

      // Data yang sudah dikonfirmasi (is_confirmed = 'dikonfirmasi')
      final riwayat = await supabase
          .from('penukaran_point')
          .select('id, member_id, penukaran_point, redeemet_at, is_confirmed')
          .eq('is_confirmed', 'dikonfirmasi')
          .order('redeemet_at', ascending: false);

      setState(() {
        penukaranPointsBelumKonfirmasi = belumKonfirmasi as List<dynamic>;
        penukaranPointsRiwayat = riwayat as List<dynamic>;
      });
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> konfirmasiPoint(dynamic id) async {
    try {
      // Ambil data penukaran terlebih dahulu
      final data = await supabase
          .from('penukaran_point')
          .select('member_id, penukaran_point')
          .eq('id', id)
          .single();

      if (data == null) {
        print('Data tidak ditemukan untuk id $id');
        return;
      }

      final memberId = data['member_id'];
      final penukaranPoint = int.tryParse(data['penukaran_point'].toString()) ?? 0;

      // Update status konfirmasi
      await supabase
          .from('penukaran_point')
          .update({'is_confirmed': 'dikonfirmasi'})
          .eq('id', id);

      // Ambil total_points dari tabel members
      final memberData = await supabase
          .from('members')
          .select('total_points')
          .eq('id', memberId)
          .single();

      if (memberData == null || memberData['total_points'] == null) {
        print('Gagal ambil total_points member');
        return;
      }

      final currentPoints = int.tryParse(memberData['total_points'].toString()) ?? 0;
      int updatedPoints = currentPoints - penukaranPoint;
      if (updatedPoints < 0) updatedPoints = 0;

      // Update total_points
      await supabase
          .from('members')
          .update({'total_points': updatedPoints})
          .eq('id', memberId);

      print('Konfirmasi dan update point berhasil.');
      fetchPenukaranPoints();
    } catch (e) {
      print('Update error: $e');
    }
  }


  Widget buildList(List<dynamic> data, {bool withButton = true}) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return Center(child: Text("Tidak ada data."));
    }

    return RefreshIndicator(
      onRefresh: fetchPenukaranPoints,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final idValue = item['id'];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member ID: ${item['member_id']}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Penukaran Point: ${item['penukaran_point']}'),
                  SizedBox(height: 4),
                  Text('Redeemed At: ${item['redeemet_at'] ?? '-'}'),
                  SizedBox(height: 8),
                  Text('Status Konfirmasi: ${item['is_confirmed'] ?? '-'}'),
                  if (withButton) ...[
                    SizedBox(height: 8),
                    ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(20),
          ),
          ),
                      onPressed: () {
                        print('Tombol konfirmasi ditekan untuk id: $idValue');
                        if (idValue == null) {
                          print('ID null, tidak bisa update.');
                          return;
                        }
                        konfirmasiPoint(idValue);
                      },
                      child: Text('Konfirmasi',
          style: TextStyle(fontSize: 16,color: Colors.white)),




                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Penukaran Point', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
    leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
    ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green, // ✅ Ganti warna garis bawah tab aktif
          labelColor: Colors.green, // Warna teks tab aktif
          unselectedLabelColor: Colors.black54, // Warna teks tab yang tidak aktif

          tabs: [
            Tab(text: 'Konfirmasi Point'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildList(penukaranPointsBelumKonfirmasi, withButton: true),
          buildList(penukaranPointsRiwayat, withButton: false),
        ],
      ),
    );
  }
}
