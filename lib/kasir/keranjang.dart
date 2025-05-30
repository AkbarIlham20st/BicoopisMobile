import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'debouncer.dart';



/* ---------------------------  MODEL  --------------------------- */
class CartItem {
  final String namaMenu; // primary-key logika (bukan id DB)
  final double price;
  String catatan;
  BluetoothDevice? _selectedDevice;
  // int pajaktotal;
  // int total;
  int qtt;


  CartItem({required this.namaMenu, required this.price,
    // required this.total,
    // required this.pajaktotal,
    required this.qtt,required this.catatan });

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    namaMenu: m['menu_name'] as String,
    price: (m['price'] as num).toDouble(),
    qtt: m['qtt'] as int,
    // total: m['total'] as int,
    // pajaktotal: m['pajaktotal'] as int,
      catatan: m['catatan'] as String,

  );
}

/* --------------------------  SCREEN  --------------------------- */
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final supabase = Supabase.instance.client;

  final mejaC = TextEditingController();
  final namaC = TextEditingController();
  final catatC = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 600);

  List<CartItem> cart = [];
  bool loading = false;

  // Instance printer
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _printerConnected = false;
  List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _initPrinter();
  }




  Future<void> updateCatatan(String namaMenu, String catatan) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('cartt')
          .update({'catatan': catatan})
          .eq('nama_menu', namaMenu);

      print('Catatan berhasil diperbarui');
    } catch (e) {
      print('Gagal update catatan: $e');
    }
  }

  Future<void> _initPrinter() async {
    try {
      // Cek apakah printer sudah terhubung
      bool isConnected = await printer.isConnected ?? false;
      if (isConnected) {
        setState(() {
          _printerConnected = true;
        });
        _snack('Sudah terhubung ke printer.');
        return;
      }

      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? printerDevice;

      for (var device in devices) {
        if (device.name == 'RPP02N') {
          printerDevice = device;
          break;
        }
      }

      if (printerDevice == null) {
        _snack('Printer RPP02N tidak ditemukan.');
        return;
      }
      BluetoothDevice? _selectedDevice;

      await printer.connect(printerDevice);
      setState(() {
        _selectedDevice = printerDevice;
        _printerConnected = true;
      });
      _snack('Berhasil terhubung ke printer!');
    } catch (e) {
      _snack('Gagal koneksi printer: $e');
    }
  }


  Future<void> _fetch() async {
    setState(() => loading = true);
    try {
      final List<dynamic> res =
      await supabase.from('cartt').select('menu_name, price, qtt, catatan');
      cart = res.map((e) => CartItem.fromMap(e)).toList();
    } catch (e) {
      _snack('Gagal ambil data: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _setQtt(String nama, int newQtt) async {
    try {
      await supabase.from('cartt').update({'qtt': newQtt}).eq('menu_name', nama);
      final i = cart.indexWhere((e) => e.namaMenu == nama);
      if (i != -1) setState(() => cart[i].qtt = newQtt);
    } catch (e) {
      _snack('Gagal update: $e');
    }
  }

  Future<void> _del(String nama) async {
    try {
      await supabase.from('cartt').delete().eq('menu_name', nama);
      setState(() => cart.removeWhere((e) => e.namaMenu == nama));
    } catch (e) {
      _snack('Gagal hapus: $e');
    }
  }

  Future<void> _printStruk() async {
    if (mejaC.text.trim().isEmpty || namaC.text.trim().isEmpty) {
      _snack('Nomor meja & nama pelanggan wajib diisi');
      return;
    }

    final orderNo = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final itemsJson = cart.map((e) => {
      'nama_menu': e.namaMenu,
      'harga': e.price,
      'qty': e.qtt,
      'catatan': e.catatan,
      'subtotal': e.qtt * e.price,
    }).toList();

    try {
      await supabase.from('history_kasir').insert({
        'order_no': orderNo,
        'nomor_meja': mejaC.text.trim(),
        'nama_pelanggan': namaC.text.trim(),
        'items': itemsJson,
        'total_item': totalItem,
        'total_harga': totalRp,
        'status': "In Order",
        'pajak': pajakTotal, // tambahkan ini

      });
    } catch (e) {
      _snack('Gagal simpan ke history: $e');
      return;
    }

    // Cetak PDF seperti biasa
    final doc = pw.Document();
    final fmtRp = (num n) => 'Rp ${n.toStringAsFixed(0)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('STRUK PEMESANAN',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Order No : $orderNo'),
            pw.Text('Meja     : ${mejaC.text}'),
            pw.Text('Nama     : ${namaC.text}'),
            if (catatC.text.trim().isNotEmpty)
              pw.Text('Catatan  : ${catatC.text}'),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Menu', 'Qty', 'Harga', 'Subtotal'],
              data: cart.map((e) => [
                e.namaMenu,
                e.qtt.toString(),
                e.catatan.toString(),
                fmtRp(e.price),
                fmtRp(e.price * e.qtt)
              ]).toList(),
              border: null,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total Item : $totalItem',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total Harga : ${fmtRp(totalRp)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
          ],
        ),
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat _) async => doc.save(),
      );

      // Cetak juga ke printer thermal (jika terhubung)
      if (_printerConnected) {
        await printThermalStruk(orderNo);
      } else {
        _snack('Printer thermal tidak terhubung');
      }

      // Setelah cetak selesai, hapus semua data di 'cartt'
      await supabase.from('cartt').delete().neq('menu_name', '');
      // Bisa juga pakai delete() tanpa kondisi jika ingin hapus semua

      // Clear local cart list dan reset inputan
      setState(() {
        cart.clear();
        mejaC.clear();
        namaC.clear();
        catatC.clear();
      });

      _snack('Struk berhasil dicetak dan keranjang dikosongkan.');

    } catch (e) {
      _snack('Gagal mencetak struk: $e');
    }
  }

  Future<void> printThermalStruk(String orderNo) async {
    final fmtRp = (num n) => 'Rp ${n.toStringAsFixed(0)}';


    try {
      final ByteData data = await rootBundle.load('assets/logo_bicopi.png');
      final Uint8List bytes = data.buffer.asUint8List();

      final img.Image? original = img.decodeImage(bytes);
      if (original != null) {
        final img.Image resized = img.copyResize(
          original,
          width: 160,
          height: 160,
        );

        if (resized != null) {
        // Jika kamu pakai blue_thermal_printer:
        await printer.printImageBytes(img.encodePng(resized));
        printer.printNewLine();
        printer.printCustom('STRUK PEMESANAN', 3, 1); // size 3, bold
        printer.printNewLine();

        printer.printLeftRight('Order No:', orderNo, 1);
        printer.printLeftRight('Meja:', mejaC.text.trim(), 1);
        printer.printLeftRight('Nama:', namaC.text.trim(), 1);

          printer.printLeftRight('Catatan:', catatC.text.trim(), 1);
          printer.printNewLine();

          printer.printCustom('Menu       Qty   Harga    Subtotal', 1, 0);
          printer.printCustom('-----------------------------------', 1, 0);

          for (var item in cart) {
            // Format tiap baris agar rapi
            String menu = item.namaMenu.padRight(10);
            String qty = item.qtt.toString().padLeft(3);
            String price = fmtRp(item.price).padLeft(8);
            String subtotal = fmtRp(item.price * item.qtt).padLeft(10);

            printer.printCustom('$menu $qty $price $subtotal', 1, 0);


              printer.printCustom('  Catatan: ${item.catatan}', 1, 0);}


          printer.printCustom('-----------------------------------', 1, 0);
          printer.printCustom('Total Item: ${totalItem.toString()}', 2, 0); // 1 = size, 0 = align left
          printer.printCustom('Pajak 10% : ${fmtRp(pajakTotal)}', 2, 0);
          printer.printCustom('Total Harga: ${fmtRp(totalRp)}', 2, 0);


          printer.printNewLine();

          printer.printNewLine();
          printer.printCustom('Terima Kasih!', 2, 1);
          printer.printNewLine();

          printer.paperCut();


      }}


    } catch (e) {
      _snack('Gagal cetak ke printer thermal: $e');
    }
  }

  int get totalItem => cart.fold(0, (s, e) => s + e.qtt);

  double get total => cart.fold(0, (s, e) => s + e.qtt * e.price);

  double get pajakTotal => total * 0.1; // contoh pajak 10%


  double get totalRp => total + pajakTotal;


  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  TextStyle get bold =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _field(mejaC, 'Nomor Meja', TextInputType.number),
          const SizedBox(height: 8),
          _field(namaC, 'Nama Pelanggan'),
          const SizedBox(height: 8),
          _field(catatC, 'Catatan'),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : cart.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : _list(),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item: $totalItem', style: bold),
                Text('Total: Rp ${total.toStringAsFixed(0)}', style: bold),
                Text('Pajak: Rp ${totalRp.toStringAsFixed(0)}', style: bold),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              label: const Text('Konfirmasi & Cetak Struk', style: TextStyle(color: Colors.white)),
              onPressed: cart.isEmpty ? null : _printStruk,


            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _list() => ListView.builder(
    itemCount: cart.length,
    itemBuilder: (_, i) {
      final it = cart[i];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.namaMenu, style: bold),
                    const SizedBox(height: 4),
                    Text('Rp ${it.price.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          it.catatan = value; // pastikan field `catatan` ada di model cart
                        });
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: it.qtt <= 1
                        ? null
                        : () => _setQtt(it.namaMenu, it.qtt - 1),
                  ),
                  Text(it.qtt.toString(), style: bold),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _setQtt(it.namaMenu, it.qtt + 1),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _del(it.namaMenu),
              ),
            ],
          ),
        ),
      );
    },
  );


  // Widget _list() => ListView.builder(
  //   itemCount: cart.length,
  //   itemBuilder: (_, i) {
  //     final it = cart[i];
  //     return Card(
  //       margin: const EdgeInsets.symmetric(vertical: 6),
  //       child: Padding(
  //         padding: const EdgeInsets.all(12),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(it.namaMenu, style: bold),
  //                   const SizedBox(height: 4),
  //                   Text('Rp ${it.price.toStringAsFixed(0)}'),
  //                 ],
  //               ),
  //             ),
  //             Row(
  //               children: [
  //                 IconButton(
  //                   icon: const Icon(Icons.remove),
  //                   onPressed: it.qtt <= 1
  //                       ? null
  //                       : () => _setQtt(it.namaMenu, it.qtt - 1),
  //                 ),
  //                 Text(it.qtt.toString(), style: bold),
  //                 IconButton(
  //                   icon: const Icon(Icons.add),
  //                   onPressed: () => _setQtt(it.namaMenu, it.qtt + 1),
  //                 ),
  //               ],
  //             ),
  //             IconButton(
  //               icon: const Icon(Icons.delete),
  //               onPressed: () => _del(it.namaMenu),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   },
  // );

  Widget _field(TextEditingController c, String hint, [TextInputType? keyboard]) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
