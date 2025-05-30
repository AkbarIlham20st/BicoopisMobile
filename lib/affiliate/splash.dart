import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Impor Supabase
import 'fleksibel_praktis.dart'; // Impor halaman tujuan
import 'login.dart'; // Impor halaman login jika perlu
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> checkFirstLaunchAndAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final user = Supabase.instance.client.auth.currentUser;

    await Future.delayed(Duration(seconds: 2)); // Delay splash

    if (user != null) {
      // Sudah login
      Navigator.pushReplacementNamed(context, '/home');
    } else if (isFirstLaunch) {
      // Pertama kali buka
      await prefs.setBool('isFirstLaunch', false);
      Navigator.pushReplacementNamed(context, '/fleksibel_praktis');
    } else {
      // Sudah pernah buka, tapi belum login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();
    checkFirstLaunchAndAuth();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih sesuai desain
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_bicopi.png', // Pastikan path gambar benar
              width: 200, // Ukuran gambar lebih besar sesuai desain
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat Datang\nPada Aplikasi Kami',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, // Ukuran font lebih besar
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '"Secangkir Inspirasi, Sejuta Kreasi"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
