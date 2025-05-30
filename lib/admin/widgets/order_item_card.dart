import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String detail;
  final String price;

  const OrderItemCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.detail,
    required this.price,
  });

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
          Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(detail),
                Text(price),
              ],
            ),
          ),
        ],
      ),
    );
  }
}