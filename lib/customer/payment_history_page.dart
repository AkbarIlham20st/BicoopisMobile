import 'package:bicopi_pos/customer/reservation_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
 // Make sure this import path is correct

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key, required String memberId})
      : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final String? currentAuthUserId =
        Supabase.instance.client.auth.currentUser?.id;

    if (currentAuthUserId == null || currentAuthUserId.isEmpty) {
      setState(() {
        _errorMessage =
            'Tidak ada pengguna yang masuk atau ID autentikasi tidak valid. Tidak dapat memuat riwayat pembayaran.';
        _isLoading = false;
      });
      print(
          'DEBUG: No Supabase user authenticated or Auth ID is empty. Cannot fetch payment history.');
      return;
    }

    // --- STEP 1: Get the 'id' (PK) from the 'members' table using auth.users.id ---
    String? actualMemberIdForQuery;
    try {
      print(
          'DEBUG: Looking up member ID in "members" table for auth user ID: $currentAuthUserId');
      final memberRecord = await Supabase.instance.client
          .from('members')
          .select('id') // Select the primary key 'id' from the members table
          .eq('id_user', currentAuthUserId) // Match using the auth.users.id
          .maybeSingle();

      if (memberRecord != null && memberRecord['id'] != null) {
        actualMemberIdForQuery = memberRecord['id'] as String;
        print(
            'DEBUG: Found actual member ID from "members" table: $actualMemberIdForQuery');
      } else {
        setState(() {
          _errorMessage =
              'Tidak ada catatan member ditemukan di tabel "members" untuk user yang masuk. Pastikan user terdaftar sebagai member.';
          _isLoading = false;
        });
        print(
            'DEBUG: No corresponding member record found in "members" table for auth user ID: $currentAuthUserId');
        return; // Stop if no member record is found
      }
    } on PostgrestException catch (e) {
      print(
          'DEBUG: Supabase PostgrestException when fetching member ID: ${e.message}');
      setState(() {
        _errorMessage = 'Gagal memuat ID member dari database: ${e.message}.';
        _isLoading = false;
      });
      return;
    } catch (e) {
      print('DEBUG: Unexpected error fetching member ID: $e');
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat memuat ID member: ${e.toString()}.';
        _isLoading = false;
      });
      return;
    }

    // --- STEP 2: Use the 'actualMemberIdForQuery' (PK from 'members' table) to query orderkasir_history ---
    print(
        'DEBUG: Attempting to fetch payment history for memberId (from "members" table): $actualMemberIdForQuery');

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('orderkasir_history')
          .select('*')
          .eq('member_id',
              actualMemberIdForQuery) // Use the actual member ID (PK from 'members' table)
          .order('created_at', ascending: false);

      setState(() {
        _paymentHistory =
            response.map((item) => item as Map<String, dynamic>).toList();
        _isLoading = false;
      });

      print(
          'DEBUG: Successfully fetched ${_paymentHistory.length} payment history entries.');
    } on PostgrestException catch (e) {
      print('DEBUG: Supabase PostgrestException: ${e.message}');
      if (e.message.contains('column "member_id" does not exist')) {
        _errorMessage =
            'Kesalahan database: Kolom "member_id" tidak ditemukan. Hubungi dukungan.';
      } else if (e.message.contains('invalid input syntax for type uuid')) {
        _errorMessage =
            'Format ID member tidak valid. Pastikan ID member adalah UUID yang benar.';
      } else {
        _errorMessage = 'Gagal memuat riwayat: ${e.message}.';
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Unexpected error fetching payment history: $e');
      _errorMessage = 'Terjadi kesalahan tidak terduga: ${e.toString()}.';
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPaymentHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Hapus Semua Riwayat?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua riwayat pembayaran Anda? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey[700]), // Reduced font size
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 3,
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14), // Reduced font size
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        final String? currentAuthUserId =
            Supabase.instance.client.auth.currentUser?.id;
        if (currentAuthUserId == null || currentAuthUserId.isEmpty) {
          throw Exception(
              'Tidak ada pengguna yang masuk atau ID autentikasi tidak valid.');
        }

        String? actualMemberIdForDeletion;
        try {
          final memberRecord = await Supabase.instance.client
              .from('members')
              .select('id')
              .eq('id_user', currentAuthUserId)
              .maybeSingle();

          if (memberRecord != null && memberRecord['id'] != null) {
            actualMemberIdForDeletion = memberRecord['id'] as String;
          } else {
            throw Exception(
                'Tidak ada catatan member ditemukan untuk user yang masuk.');
          }
        } catch (e) {
          throw Exception(
              'Gagal mendapatkan ID member untuk penghapusan: ${e.toString()}');
        }

        await Supabase.instance.client
            .from('orderkasir_history')
            .delete()
            .eq('member_id', actualMemberIdForDeletion);

        // Update the state
        setState(() {
          _paymentHistory = []; // Clear the list
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Riwayat pembayaran berhasil dihapus!',
              style: GoogleFonts.poppins(fontSize: 13), // Reduced font size
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } on PostgrestException catch (e) {
        setState(() {
          _errorMessage = 'Gagal menghapus riwayat: ${e.message}.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus riwayat: ${e.message}',
              style: GoogleFonts.poppins(fontSize: 13), // Reduced font size
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan tidak terduga: ${e.toString()}.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan: ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 13), // Reduced font size
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF078603),
        elevation: 1.5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Lengkungan bawah
          ),
        ), // Subtle shadow for depth

        title: Text(
          "Riwayat Pembayaran",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 19, // Slightly adjusted font size
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey[700]),
        actions: [
          // New button for Reservation History
          IconButton(
            icon: Icon(Icons.bookmark_added_outlined, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReservationHistoryScreen(),
                ),
              );
            },
            tooltip: 'Riwayat Reservasi',
          ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.red[400], size: 24), // Reduced icon size
            onPressed: _paymentHistory.isEmpty ? null : _clearPaymentHistory,
            tooltip: 'Hapus Semua Riwayat',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green[700]!)))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _paymentHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _paymentHistory.length,
                      itemBuilder: (context, index) {
                        final history = _paymentHistory[index];
                        return _buildPaymentCard(history);
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              color: Colors.red[400],
              size: 65, // Reduced icon size
            ),
            const SizedBox(height: 15), // Reduced spacing
            Text(
              "Terjadi Kesalahan",
              style: GoogleFonts.poppins(
                fontSize: 18, // Reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13, // Reduced font size
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 25), // Reduced spacing
            ElevatedButton.icon(
              onPressed: _fetchPaymentHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Reduced border radius
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                elevation: 3,
              ),
              icon: const Icon(Icons.refresh, size: 16), // Reduced icon size
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600), // Reduced font size
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.grey[300],
              size: 80, // Reduced icon size
            ),
            const SizedBox(height: 15), // Reduced spacing
            Text(
              "Tidak Ada Riwayat Pembayaran",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18, // Reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              "Transaksi Anda akan muncul di sini. Mulai berbelanja!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13, // Reduced font size
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 25), // Reduced spacing
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> history) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Slightly reduced border radius
      ),
      elevation: 4, // Slightly reduced elevation
      shadowColor: Colors.black.withOpacity(0.06), // Lighter shadow
      child: Padding(
        padding: const EdgeInsets.all(18.0), // Slightly reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order No: ${history['order_no'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16, // Reduced font size
                      color: Colors.grey[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(5), // Reduced border radius
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.poppins(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 10, // Reduced font size
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 18, thickness: 0.5, color: Colors.grey[200]), // Adjusted divider
            _buildInfoRow(
              icon: Icons.table_bar_outlined,
              label: 'Meja',
              value: history['nomor_meja']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Pelanggan',
              value: history['nama_pelanggan'] ?? 'N/A',
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'Total Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 13, // Reduced font size
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currencyFormatter.format(history['total_harga'] ?? 0),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 20, // Reduced font size
                color: Colors.green[700],
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Transaksi pada: ${history['created_at'] != null ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(history['created_at']).toLocal()) : 'N/A'}',
                style: GoogleFonts.poppins(
                    fontSize: 10, // Reduced font size
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic),
              ),
            ),
            if (history['items'] != null &&
                history['items'] is List &&
                (history['items'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 20, thickness: 0.5, color: Colors.grey[200]), // Adjusted divider
                  Text(
                    'Detail Pesanan:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Reduced font size
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (history['items'] as List).length,
                    itemBuilder: (context, itemIndex) {
                      final item = (history['items'] as List)[itemIndex];
                      return _buildItemRow(item);
                    },
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12.0), // Reduced padding
                child: Text(
                  'Detail Pesanan: Tidak ada item yang tercatat.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500]), // Reduced font size
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Reduced vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.green[400]), // Reduced icon size
          const SizedBox(width: 8), // Reduced spacing
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 13, // Reduced font size
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 5), // Reduced spacing
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13, // Reduced font size
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final itemName = item['item_name'] ?? 'N/A';
    final itemQuantity = item['quantity'] ?? 'N/A';
    final itemPrice = item['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 6.0), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$itemQuantity x $itemName',
              style: GoogleFonts.poppins(
                fontSize: 12, // Reduced font size
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormatter.format(itemPrice),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12, // Reduced font size
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}