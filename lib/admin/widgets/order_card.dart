// import 'package:flutter/material.dart';
// import 'package:admin_bicopi/models/order_model.dart';
// import 'package:admin_bicopi/pages/order/order_detail_page.dart';
//
// class OrderCard extends StatelessWidget {
//   final OrderModel order;
//
//   const OrderCard({super.key, required this.order});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: ListTile(
//         title: Text('Order #${order.orderNo}'),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Meja: ${order.nomorMeja}'),
//             Text('Pelanggan: ${order.namaPelanggan}'),
//             Text('Total Item: ${order.totalItem}'),
//             Text('Status: ${order.catatan}'),
//           ],
//         ),
//         trailing: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Rp ${order.totalHarga.toStringAsFixed(0)}'),
//           ],
//         ),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OrderDetailPage(order: order),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }