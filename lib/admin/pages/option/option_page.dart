import 'package:bicopi_pos/kasir/masuk.dart';
import 'package:bicopi_pos/landinglogin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../kasir/HomeScreen.dart';
import '../../providers/account_provider.dart';
import '../../models/user_model.dart';
import '../../models/admin_model.dart' as admin_model;
import '../../models/affiliate_model.dart';

class OptionPage extends StatefulWidget {
  const OptionPage({super.key});

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AccountProvider>(context, listen: false).loadAllAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AccountProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Option'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await provider.loadAllAccounts();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...provider.admins.map((admin) => AccountCard(
                title: admin.username,
                subtitle: admin.email,
                icon: Icons.admin_panel_settings,
              )),
              const SizedBox(height: 16),
              const Text('User Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...provider.users.map((user) => AccountCard(
                title: user.namaLengkap ?? "",
                subtitle: user.users?.email ?? "",
                icon: Icons.person,
              )),
              const SizedBox(height: 16),
              const Text('Affiliate Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...provider.affiliates.map((affiliate) => AccountCard(
                title: affiliate.users?.username ?? "",
                subtitle: affiliate.users?.email ?? "",
                icon: Icons.handshake,
              )),
              const SizedBox(height: 16),
              const Text('Cashier Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...provider.kasirs.map((affiliate) => AccountCard(
                title: affiliate.username,
                subtitle: affiliate.email,
                icon: Icons.computer_outlined,
              )),
              const SizedBox(height: 32),
              // Center(
              //   child: ElevatedButton.icon(
              //     icon: const Icon(Icons.logout),
              //     label: const Text('Logout'),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.redAccent,
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              //     ),
              //     onPressed: () {
              //       // Hapus seluruh riwayat navigator dan kembali ke SebelumLoginPage
              //       Navigator.pushAndRemoveUntil(
              //         context,
              //         MaterialPageRoute(builder: (_) => const LoginPage()),
              //             (route) => false, // Menghapus semua halaman sebelumnya
              //       );
              //
              //       // (Opsional) Tampilkan snackbar setelah redirect
              //       // Jika ingin tetap menampilkan snackbar, letakkan di halaman tujuan
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
class AccountCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AccountCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}