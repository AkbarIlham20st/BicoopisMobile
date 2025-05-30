import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bicopi_pos/customer/login.dart' as login_page; // Keep this import if you still use login_page elsewhere
import 'package:bicopi_pos/customer/main.dart'; // Import your HomePage from main.dart

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  bool isLoading = false;

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak sama!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'nama': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      final user = response.user;
      if (user == null) throw Exception('Gagal mendaftar');

      int newUserLevel = 1; // Default user level
      String? affiliateId;
      final referralCode = referralCodeController.text.trim();
      int initialPoints =
          0; // Poin referral untuk pendaftar saat menggunakan kode

      if (referralCode.isNotEmpty) {
        final referralMatch = await Supabase.instance.client
            .from('affiliates')
            .select('id')
            .eq('referral_code', referralCode)
            .maybeSingle();

        if (referralMatch != null &&
            referralMatch.containsKey('id') &&
            referralMatch['id'] != null) {
          affiliateId = referralMatch['id'];
          newUserLevel = 4; // Set user level menjadi 4 jika referral valid
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kode referal tidak valid')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      } else {
        initialPoints = 0; // Poin awal jika tidak ada kode referral
      }

      // 1. Insert data user ke tabel "users" TERLEBIH DAHULU
      try {
        await Supabase.instance.client.from('users').insert({
          'id_user': user.id,
          'username': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'phone': phoneController.text.trim(),
          'id_user_level': newUserLevel, // Menggunakan nilai newUserLevel
          'created_at': DateTime.now().toIso8601String(),
        });
        print(
            'Berhasil memasukkan data ke tabel "users" dengan ID: ${user.id}');
        await Future.delayed(const Duration(seconds: 2)); // Jeda lebih lama
      } catch (usersError) {
        print('Error saat memasukkan data ke tabel "users": $usersError');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat mendaftarkan pengguna.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 2. Insert data member ke tabel "members" dengan affiliate_id
      try {
        double? parsedPhoneNumber;
        try {
          parsedPhoneNumber = double.tryParse(phoneController.text.trim());
        } catch (e) {
          print('Gagal mem-parse nomor telepon: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format nomor telepon tidak valid.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        await Supabase.instance.client.from('members').insert({
          'id_user': user.id,
          'joined_at': DateTime.now().toIso8601String(),
          'nama_lengkap': nameController.text.trim(),
          'nomor_telepon': parsedPhoneNumber,
          'affiliate_id': affiliateId,
          'total_points': 0,
          'kelipatan': 10,
          'presentase': 10,
          'created_at': DateTime.now().toIso8601String(),
        });
        print(
            'Berhasil memasukkan data ke tabel "members" dengan id: ${user.id} dan affiliate_id: $affiliateId');
        await Future.delayed(const Duration(seconds: 1)); // Tambahkan jeda
      } catch (membersError) {
        print('Error saat memasukkan data ke tabel "members": $membersError');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat membuat profil member.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 3. Tambahkan poin referral untuk pendaftar jika ada referral
      if (referralCodeController.text.trim().isNotEmpty &&
          affiliateId != null) {
        try {
          await Supabase.instance.client.from('member_points_log').insert({
            'member_id': user
                .id, // Mereferensikan 'id' dari tabel 'members' (yang sama dengan user.id)
            'points_earned': initialPoints,
            'description': 'Poin referral dari pendaftaran',
            'created_at': DateTime.now().toIso8601String(),
          });
          print('Berhasil menambahkan poin referral untuk pendaftar (log).');

          // Update total poin pendaftar
          final currentPointsPendaftar = await Supabase.instance.client
              .from('members')
              .select('total_points')
              .eq('id', user.id)
              .single()
              .then((data) => data['total_points'] as int? ?? 0);
          await Supabase.instance.client.from('members').update({
            'total_points': currentPointsPendaftar + initialPoints
          }).eq('id', user.id);
          print('Berhasil memperbarui total poin pendaftar.');
        } catch (pointsError) {
          print(
              'Error saat menambahkan poin referral untuk pendaftar: $pointsError');
        }

        // 4. Tambahkan poin untuk user yang memberikan referral ke tabel 'affiliates'
        try {
          print(
              'Mencari affiliate pemberi referral dengan id_user: $affiliateId');
          final referrerAffiliate = await Supabase.instance.client
              .from('affiliates')
              .select(
                  'total_points') // Asumsikan ada kolom 'total_points' di tabel 'affiliates'
              .eq('id_user', affiliateId)
              .maybeSingle();
          print(
              'Hasil pencarian affiliate pemberi referral: $referrerAffiliate');

          const referralPointsPemberi = 90;

          if (referrerAffiliate != null &&
              referrerAffiliate.containsKey('total_points')) {
            final currentPointsPemberi =
                referrerAffiliate['total_points'] as int? ?? 0;
            await Supabase.instance.client.from('affiliates').update({
              'total_points': currentPointsPemberi + referralPointsPemberi
            }).eq('id_user', affiliateId);
            print(
                'Berhasil menambahkan poin referral pemberi ke tabel "affiliates".');

            // Optional: Log poin pemberi di member_points_log juga
            final referrerMember = await Supabase.instance.client
                .from('members')
                .select('id')
                .eq('id_user', affiliateId)
                .maybeSingle();

            if (referrerMember != null && referrerMember.containsKey('id')) {
              final referrerMemberId = referrerMember['id'];
              await Supabase.instance.client.from('member_points_log').insert({
                'member_id': referrerMemberId,
                'points_earned': referralPointsPemberi,
                'description':
                    'Mendapatkan referral dari pendaftaran ${user.id} (poin tercatat di afiliasi)',
                'created_at': DateTime.now().toIso8601String(),
              });
              print('Berhasil menambahkan log poin untuk pemberi referral.');
            }
          } else {
            print(
                'Error: ID user pemberi referral tidak ditemukan di tabel "affiliates".');
          }
        } catch (pointsError) {
          print(
              'Error saat menambahkan poin untuk pemberi referral: $pointsError');
        }
      } else {
        // Tambahkan poin awal untuk pendaftar jika tidak ada referral
        try {
          await Supabase.instance.client.from('member_points_log').insert({
            'member_id': user.id,
            'points_earned': initialPoints,
            'description': 'Poin pendaftaran awal',
            'created_at': DateTime.now().toIso8601String(),
          });
          print('Berhasil menambahkan poin awal untuk pendaftar (log).');

          final currentPointsPendaftar = await Supabase.instance.client
              .from('members')
              .select('total_points')
              .eq('id', user.id)
              .single()
              .then((data) => data['total_points'] as int? ?? 0);
          await Supabase.instance.client.from('members').update({
            'total_points': currentPointsPendaftar + initialPoints
          }).eq('id', user.id);
          print('Berhasil memperbarui total poin pendaftar.');
        } catch (pointsError) {
          print('Error saat menambahkan poin awal: $pointsError');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pendaftaran berhasil! Silakan login.'), // Pesan diubah
        ),
      );


     await Supabase.instance.client.auth.signOut();

Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const login_page.LoginScreen()),
);


    } on AuthException catch (error) {
      if (error.message.contains('users_email_key')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Email ini sudah terdaftar. Silakan coba login atau gunakan email lain.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error otentikasi: ${error.message}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${error.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ... rest of your SignUpScreen class ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              const SizedBox(height: 30),
              Center(
                child: Image.asset(
                  'assets/bicopi_logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Daftar Akun',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: nameController, label: 'Nama Lengkap'),
              _buildTextField(controller: phoneController, label: 'No Telepon'),
              _buildTextField(controller: emailController, label: 'Email'),
              _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  isPassword: true),
              _buildTextField(
                  controller: confirmPasswordController,
                  label: 'Konfirmasi Password',
                  isPassword: true),
              _buildTextField(
                  controller: referralCodeController,
                  label: 'Kode Referal (Opsional)'),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078603),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Daftar',
                        style: TextStyle(
                             color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const login_page.LoginScreen()),
                  );
                },
               child: const Text(
                'Sudah punya akun? Login',
                style: TextStyle(
                  color: Color(0xFF078603), // Warna teks hijau
                ),
              ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MemberPointsLogScreen()),
                  );
                },
                child: const Text(
                  'Lihat Log Poin Member',
                  style: TextStyle(
                    color: Color(0xFF078603),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: label.contains('Telepon')
            ? TextInputType.phone
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}

class MemberPointsLogScreen extends StatefulWidget {
  const MemberPointsLogScreen({super.key});

  @override
  State<MemberPointsLogScreen> createState() => _MemberPointsLogScreenState();
}

class _MemberPointsLogScreenState extends State<MemberPointsLogScreen> {
  late final Stream<List<Map<String, dynamic>>> _memberPointsStream;

  @override
  void initState() {
    super.initState();
    _memberPointsStream = Supabase.instance.client
        .from('member_points_log')
        .stream(primaryKey: ['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Poin Member'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _memberPointsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final memberPointsList = snapshot.data!;

          if (memberPointsList.isEmpty) {
            return const Center(child: Text('Tidak ada data log poin member.'));
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              final pointsLog = memberPointsList[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${pointsLog['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Member ID: ${pointsLog['member_id']}'),
                      if (pointsLog['order_id'] != null)
                        Text('Order ID: ${pointsLog['order_id']}'),
                      Text('Poin Didapatkan: ${pointsLog['points_earned']}'),
                      if (pointsLog['description'] != null)
                        Text('Deskripsi: ${pointsLog['description']}'),
                      Text(
                          'Dibuat pada: ${DateTime.parse(pointsLog['created_at']).toLocal()}'),
                      if (pointsLog['reward_id'] != null)
                        Text('ID Reward: ${pointsLog['reward_id']}'),
                      if (pointsLog['redeemed_at'] != null)
                        Text(
                            'Redeem pada: ${DateTime.parse(pointsLog['redeemed_at']).toLocal()}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}