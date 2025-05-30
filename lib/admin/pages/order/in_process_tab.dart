import 'package:flutter/material.dart';

class InProcessTab extends StatelessWidget {
  const InProcessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        children: List.generate(5, (index) => OrderCard(index: index)),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final int index;
  const OrderCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Image.network(
            'https://via.placeholder.com/80',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu Name $index', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Sedang diproses...'),
                Text('Harga: Rp25.000'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}