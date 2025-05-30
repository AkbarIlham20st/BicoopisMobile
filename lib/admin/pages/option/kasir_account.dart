// import 'package:flutter/material.dart';
// import 'package:admin_bicopi/models/kasir_model.dart';
// import 'package:admin_bicopi/services/kasir_service.dart';
//
// class KasirAccount extends StatefulWidget {
//   const KasirAccount({Key? key}) : super(key: key);
//
//   @override
//   State<KasirAccount> createState() => _KasirAccountState();
// }
//
// class _KasirAccountState extends State<KasirAccount> {
//   List<KasirModel> kasirList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchKasir();
//   }
//
//   Future<void> fetchKasir() async {
//     final data = await KasirService.getKasir();
//     setState(() {
//       kasirList = data;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Akun Kasir"),
//         backgroundColor: Colors.orange,
//       ),
//       body: ListView.builder(
//         itemCount: kasirList.length,
//         itemBuilder: (context, index) {
//           final kasir = kasirList[index];
//           return ListTile(
//             title: Text(kasir.nama),
//             subtitle: Text('Username: ${kasir.username}'),
//             trailing: Icon(Icons.person),
//           );
//         },
//       ),
//     );
//   }
// }
