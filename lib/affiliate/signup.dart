import 'package:flutter/material.dart';
// import 'package:bicopi_pos/affiliate/font_awesome_flutter.dart';
import 'verifikasi_email.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SignUpScreen(),
  ));
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSigningUp = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  // Tambahkan di LUAR _signUp() atau class _SignUpScreenState
  String generateReferralCode(String name) {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  final cleanedName = name.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  final prefix = cleanedName.length >= 3 ? cleanedName.substring(0, 3) : cleanedName.padRight(3, 'X');
  return '$prefix$timestamp';
}


  Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;
  if (_isSigningUp) return; // untuk mencegah pemanggilan ganda


  setState(() {
    _isSigningUp = true;
  });

  try {
    final response = await Supabase.instance.client.auth.signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
      data: {
        'username': nameController.text.trim(),
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Gagal mendaftar.');
    }

    final referralCode = generateReferralCode(nameController.text.trim());

    // Masukkan data ke tabel users
    await Supabase.instance.client.from('users').insert({
      'id_user': user.id,
      'username': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'id_user_level': 4,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Masukkan referral code ke tabel affiliates
    await Supabase.instance.client.from('affiliates').insert({
      'id_user': user.id,
      'referral_code': referralCode,
      'total_points': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pendaftaran berhasil!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VerifikasiEmailScreen(
          email: emailController.text.trim(),
        ),
      ),
    );
  } on AuthException catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.message}')),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}')),
    );
  } finally {
    setState(() {
      _isSigningUp = false;
    });
  }
}


  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: "logo",
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/logo_bicopi.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Buat Akun",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Daftar untuk melanjutkan",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            label: "Nama Lengkap",
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "Nama Lengkap tidak boleh kosong";
                              return null;
                            },
                          ),
                          _buildTextField(
                              controller: phoneController,
                              label: "No Telepon",
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 20),
                          _buildTextField(
                              controller: emailController,
                              label: "Email",
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "Email tidak boleh kosong";
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value))
                                  return "Masukkan email yang valid";
                                return null;
                              }),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                              controller: passwordController,
                              label: "Password",
                              isVisible: _isPasswordVisible,
                              onToggle: () {
                                setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible);
                              }),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                              controller: confirmPasswordController,
                              label: "Konfirmasi Password",
                              isVisible: _isConfirmPasswordVisible,
                              onToggle: () {
                                setState(() => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible);
                              }),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isSigningUp ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text("Daftar",
                                style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun?",
                            style: TextStyle(color: Colors.black)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()));
                          },
                          child: const Text("Login",
                              style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSigningUp)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    IconData icon = Icons.person;
    if (label.contains("Nama")) icon = Icons.account_circle;
    if (label.contains("Telepon")) icon = Icons.phone;
    if (label.contains("Email")) icon = Icons.email;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty)
              return "$label tidak boleh kosong";
            return null;
          },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "$label tidak boleh kosong";
        if (label.contains("Konfirmasi") && value != passwordController.text)
          return "Password tidak cocok";
        if (label.contains("Password") && value.length < 6)
          return "Password minimal 6 karakter";
        return null;
      },
    );
  }
}
