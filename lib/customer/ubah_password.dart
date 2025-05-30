import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  _UbahPasswordScreenState createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  double _passwordStrengthValue = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  final supabase = Supabase.instance.client;

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrengthValue = strength;
      if (strength <= 0.25) {
        _passwordStrengthText = 'Lemah';
        _passwordStrengthColor = Colors.redAccent;
      } else if (strength <= 0.5) {
        _passwordStrengthText = 'Sedang';
        _passwordStrengthColor = Colors.orangeAccent;
      } else if (strength <= 0.75) {
        _passwordStrengthText = 'Baik';
        _passwordStrengthColor = Colors.yellow[700]!;
      } else {
        _passwordStrengthText = 'Kuat';
        _passwordStrengthColor = Colors.greenAccent[400]!;
      }
    });
  }

  Future<void> _ubahPassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      _showMessage("Konfirmasi password tidak cocok.");
      return;
    }

    if (_passwordStrengthValue < 0.75) {
      _showMessage(
          "Password belum cukup kuat. Gunakan kombinasi huruf besar, angka, dan simbol.");
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showMessage("Pengguna tidak ditemukan.");
        return;
      }

      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        _showMessage("Gagal mengubah password.");
        return;
      }

      _showMessage("Password berhasil diubah.");
      Navigator.pop(context);
    } catch (e) {
      _showMessage("Gagal mengubah password: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ubah Password",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Gradien hijau
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[200]!, Colors.white], // Gradien latar belakang lembut
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Keamanan Akun",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              "Pastikan password baru Anda kuat dan berbeda dari yang sebelumnya.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            _buildPasswordField(
              "Password Saat Ini",
              _currentPasswordController,
              _obscureCurrentPassword,
              () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              "Password Baru",
              _newPasswordController,
              _obscureNewPassword,
              () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              onChanged: _checkPasswordStrength,
              icon: Icons.lock_open_outlined,
            ),
            if (_passwordStrengthText.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _passwordStrengthValue,
                backgroundColor: Colors.grey[300],
                color: _passwordStrengthColor,
                minHeight: 5,
              ),
              const SizedBox(height: 4),
              Text(
                'Kekuatan: $_passwordStrengthText',
                style: TextStyle(
                  color: _passwordStrengthColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 15),
            _buildPasswordField(
              "Konfirmasi Password Baru",
              _confirmPasswordController,
              _obscureConfirmPassword,
              () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icons.replay_outlined,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _ubahPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "Simpan Perubahan",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Batalkan",
                  style: TextStyle(color: Colors.green[700]!, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility, {
    void Function(String)? onChanged,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600]),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}