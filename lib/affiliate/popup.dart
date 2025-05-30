import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PopupPage extends StatefulWidget {
  final String title;
  final int points;
  final String transactionId;
  final String affiliateId; // Ini seharusnya adalah ID dari kolom 'id' di tabel affiliates
  final String description;

  const PopupPage({
    super.key,
    required this.title,
    required this.points,
    required this.transactionId,
    required this.affiliateId,
    this.description = 'Redemption successful',
  });

  @override
  State<PopupPage> createState() => _PopupPageState();
}

class _PopupPageState extends State<PopupPage> {
  bool _isLoading = false;
  String? _errorMessage;

  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  bool _isUuid(String str) {
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(str);
  }

  Future<void> _saveRedemptionToSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String redemptionId = widget.transactionId;
      if (redemptionId.isEmpty || !_isUuid(redemptionId)) {
        redemptionId = _uuid.v4();
        print('Generated new UUID for redemption ID: $redemptionId');
      }

      final String affiliateIdToUse = widget.affiliateId;
      final String? memberIdToUse = null;

      // --- VALIDASI AFFILIATE ID ---
      if (!_isUuid(affiliateIdToUse)) {
        _errorMessage = 'Format ID Afiliasi tidak valid.';
        print('Error: Invalid Affiliate ID format: $affiliateIdToUse');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Perbaikan di sini: Cek di kolom 'id' tabel affiliates
      final affiliateCheck = await supabase
          .from('affiliates')
          .select('id') // Tetap 'id' karena kita hanya perlu tahu apakah ID itu ada
          .eq('id', affiliateIdToUse) // <--- UBAH DARI 'id_user' KE 'id'
          .limit(1);

      if (affiliateCheck.isEmpty) {
        _errorMessage = 'Error: ID Afiliasi "$affiliateIdToUse" tidak ditemukan di tabel affiliates (kolom id).'; // Perbarui pesan error agar lebih jelas
        print('Error: Affiliate ID "$affiliateIdToUse" not found in affiliates table (id column).');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Member ID is explicitly set to NULL, skipping member validation.');

      print('Attempting to insert redemption with:');
      print('    id: $redemptionId');
      print('    affiliate_id: $affiliateIdToUse');
      print('    member_id: NULL (explicitly set)');

      // --- INSERT DATA KE TABEL penukaran_point ---
      await supabase.from('penukaran_point').insert({
        'id': redemptionId,
        'penukaran_point': widget.points,
        'affiliate_id': affiliateIdToUse,
        'member_id': null,
        // 'member_id': affiliateIdToUse,
        'deskripsi': widget.description,
        'redeemet_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      setState(() {
        if (e.message.contains('penukaran_point_affiliate_id_fkey')) {
          _errorMessage = 'Error: ID Afiliasi "${widget.affiliateId}" tidak ada atau tidak valid di tabel affiliates.';
        } else if (e.message.contains('penukaran_point_member_id_fkey')) {
          _errorMessage = 'Error: ID Member (kosong) tidak valid. Pastikan kolom member_id di DB Anda nullable.';
        } else {
          _errorMessage = 'Database Error: ${e.message}';
        }
      });
      print('Supabase error: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tak terduga: $e';
      });
      print('Unexpected error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 50, color: Colors.black),
            const SizedBox(height: 12),
            const Text("Tanda Terima Penukaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(thickness: 1.2, color: Colors.black38),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text("ID Penukaran", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(widget.transactionId, style: const TextStyle(color: Colors.black87))),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text("Penukaran Point", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.sync, size: 18),
                const SizedBox(width: 6),
                Text("${widget.points} POIN", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const Divider(thickness: 1.2, color: Colors.black38),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _saveRedemptionToSupabase,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : const Text(
                        "Confirm",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}