import 'package:flutter/material.dart';

class AffiliateAccount extends StatelessWidget {
  const AffiliateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Affiliate Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Nama: Affiliate User'),
            Text('Email: affiliate@example.com'),
            Text('No HP: 08987654321'),
            Text('Username: aff123'),
            Text('Password: ******'),
            Text('Poin: 75'),
            Text('Kode Referal: AFF2025'),
          ],
        ),
      ),
    );
  }
}