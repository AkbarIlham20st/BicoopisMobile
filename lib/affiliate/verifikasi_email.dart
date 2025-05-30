import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart'; // Ganti dengan file halaman login kamu

class VerifikasiEmailScreen extends StatefulWidget {
  final String email;
   final Map<String, dynamic>? userData; // ← tambah ini

  const VerifikasiEmailScreen({super.key, required this.email, this.userData});

  @override
  State<VerifikasiEmailScreen> createState() => _VerifikasiEmailScreenState();
}

class _VerifikasiEmailScreenState extends State<VerifikasiEmailScreen> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Cek status verifikasi setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    if (_checking) return;
    _checking = true;

    try {
      final user = await Supabase.instance.client.auth.getUser();
      await Supabase.instance.client.auth.refreshSession();

      final updatedUser = await Supabase.instance.client.auth.getUser();

      if (updatedUser.user?.emailConfirmedAt != null) {
        _timer?.cancel();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), // Ganti dengan halaman login kamu
          (route) => false,
        );
      }
    } catch (e) {
      // Error log atau ignore
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Silakan Cek Email Anda Untuk Verifikasi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Kami telah mengirim email verifikasi ke ${widget.email}.\nSilakan periksa dan klik tautan untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Kembali ke Halaman Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
