import 'package:flutter/material.dart';

class AccountItemCard extends StatelessWidget {
  final String title;
  final List<String> data;

  const AccountItemCard({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var item in data) Text(item),
          ],
        ),
      ),
    );
  }
}