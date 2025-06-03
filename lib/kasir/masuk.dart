
import 'package:bicopi_pos/kasir/Register.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomeScreen.dart';
import 'menu_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi semua field')),
      );
      return;
    }

    final response = await supabase
        .from('users') // Ganti nama tabel dari User_kasir ke users
        .select()
        .eq('username', username) // Sesuaikan dengan kolom username
        .eq('password', password) // Sesuaikan dengan kolom password
        .maybeSingle();

    if (response != null) {
      final int userLevel = response['id_user_level'];

      if (userLevel == 2 || userLevel == 3) { // Hanya izinkan level 1, 2, 3
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login berhasil')),
        );

        // Navigasi ke MenuScreen setelah delay singkat agar SnackBar bisa terlihat dulu
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akses ditolak: level user tidak valid')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengguna atau password salah')),
      );
    }
  }// <- jangan lupa tutup method _login

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/Bicopilogo.png',
                  height: 150,
                ),
                const SizedBox(height: 32),
                TextField(
                  style: TextStyle(color: Colors.black), // Warna teks
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pengguna',
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.grey),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                  ),),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(color: Colors.black), // Warna teks

                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    hintStyle: TextStyle(color: Colors.grey),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green,foregroundColor: Colors.white),
                  child: const Text('Login'),
                ),
                // TextButton(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => const RegisterPage()),
                //     );
                //   },
                //   child: const Text("Belum punya akun? Daftar di sini",style: TextStyle(color: Colors.green),),
                // ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
Widget _field(TextEditingController c, String hint, [TextInputType? keyboard]) {
  return TextField(
    controller: c,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}