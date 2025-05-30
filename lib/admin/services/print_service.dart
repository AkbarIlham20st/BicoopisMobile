import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PrintService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  static BluetoothDevice? _selectedDevice;
  static bool _isConnected = false;

  // Data struk yang akan dicetak
  static Map<String, dynamic> strukData = {
    'namaUsaha': 'TOKO SERBAGUNA',
    'alamat': 'Jl. Contoh No. 123, Surabaya',
    'telepon': '031-1234567',
    'kasir': 'Admin',
    'noStruk': 'TRX-001',
    'tanggal': DateTime.now(),
    'items': [
      {'nama': 'Beras 5kg', 'qty': 2, 'harga': 65000, 'total': 130000},
      {'nama': 'Minyak Goreng 2L', 'qty': 1, 'harga': 35000, 'total': 35000},
      {'nama': 'Gula Pasir 1kg', 'qty': 3, 'harga': 15000, 'total': 45000},
    ],
    'subtotal': 210000,
    'pajak': 21000,
    'total': 231000,
    'bayar': 250000,
    'kembalian': 19000,
  };

  // Scan perangkat Bluetooth
  static Future<List<BluetoothDevice>> scanDevices() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error scanning devices: $e');
      return [];
    }
  }

  // Koneksi ke printer
  static Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = await _bluetooth.isConnected ?? false;
      return _isConnected;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  // Disconnect printer
  static Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
      _isConnected = false;
      _selectedDevice = null;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  // Check status koneksi
  static Future<bool> isConnected() async {
    return await _bluetooth.isConnected ?? false;
  }

  // Generate PDF untuk preview
  static Future<Uint8List> generatePDF() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      strukData['namaUsaha'],
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      strukData['alamat'],
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Telp: ${strukData['telepon']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.Divider(thickness: 1),

              // Info transaksi
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No: ${strukData['noStruk']}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Kasir: ${strukData['kasir']}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text(
                'Tanggal: ${dateFormat.format(strukData['tanggal'])}',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.Divider(thickness: 1),

              // Header items
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Harga', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),

              pw.Divider(thickness: 0.5),

              // Items
              ...strukData['items'].map<pw.Widget>((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item['nama'], style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${item['qty']}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['harga']), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 2, child: pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['total']), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 1),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['subtotal']), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pajak:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['pajak']), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['total']), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.Divider(thickness: 1),

              // Pembayaran
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['bayar']), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembalian:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['kembalian']), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Terima Kasih', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Selamat Berbelanja Kembali', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Preview PDF
  static Future<void> previewPDF() async {
    try {
      final pdfData = await generatePDF();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'Struk_${strukData['noStruk']}.pdf',
      );
    } catch (e) {
      print('Error preview PDF: $e');
      throw Exception('Gagal menampilkan preview PDF: $e');
    }
  }

  // Cetak ke thermal printer
  static Future<void> printThermal() async {
    try {
      if (!_isConnected) {
        throw Exception('Printer tidak terhubung. Silakan hubungkan printer terlebih dahulu.');
      }

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // Header
      _bluetooth.printNewLine();
      _bluetooth.printCustom(strukData['namaUsaha'], 2, 1); // Size 2, Center
      _bluetooth.printCustom(strukData['alamat'], 0, 1); // Size 0, Center
      _bluetooth.printCustom('Telp: ${strukData['telepon']}', 0, 1);
      _bluetooth.printCustom('================================', 0, 1);

      // Info transaksi
      _bluetooth.printLeftRight('No: ${strukData['noStruk']}', 'Kasir: ${strukData['kasir']}', 0);
      _bluetooth.printCustom('Tanggal: ${dateFormat.format(strukData['tanggal'])}', 0, 0);
      _bluetooth.printCustom('================================', 0, 1);

      // Header items
      _bluetooth.printCustom('Item         Qty  Harga    Total', 0, 0);
      _bluetooth.printCustom('--------------------------------', 0, 1);

      // Items
      for (var item in strukData['items']) {
        String nama = item['nama'].toString().padRight(12);
        if (nama.length > 12) nama = nama.substring(0, 12);

        String qty = item['qty'].toString().padLeft(3);
        String harga = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0)
            .format(item['harga']).padLeft(8);
        String total = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0)
            .format(item['total']).padLeft(8);

        _bluetooth.printCustom('$nama $qty $harga $total', 0, 0);
      }

      _bluetooth.printCustom('================================', 0, 1);

      // Total
      String subtotalStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['subtotal']);
      String pajakStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['pajak']);
      String totalStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['total']);

      _bluetooth.printLeftRight('Subtotal:', subtotalStr, 0);
      _bluetooth.printLeftRight('Pajak:', pajakStr, 0);
      _bluetooth.printLeftRight('TOTAL:', totalStr, 1); // Bold

      _bluetooth.printCustom('================================', 0, 1);

      // Pembayaran
      String bayarStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['bayar']);
      String kembalianStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(strukData['kembalian']);

      _bluetooth.printLeftRight('Bayar:', bayarStr, 0);
      _bluetooth.printLeftRight('Kembalian:', kembalianStr, 0);

      _bluetooth.printNewLine();

      // Footer
      _bluetooth.printCustom('Terima Kasih', 1, 1); // Size 1, Center, Bold
      _bluetooth.printCustom('Selamat Berbelanja Kembali', 0, 1);

      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();

      print('Struk berhasil dicetak');
    } catch (e) {
      print('Error printing thermal: $e');
      throw Exception('Gagal mencetak struk: $e');
    }
  }

  // Update data struk
  static void updateStrukData(Map<String, dynamic> newData) {
    strukData = newData;
  }

  // Get daftar printer yang tersedia
  static Future<List<BluetoothDevice>> getAvailablePrinters() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      // Filter hanya printer thermal (bisa disesuaikan dengan nama device)
      return devices.where((device) =>
      device.name?.toLowerCase().contains('thermal') == true ||
          device.name?.toLowerCase().contains('printer') == true ||
          device.name?.toLowerCase().contains('pos') == true ||
          device.name?.toLowerCase().contains('mp-80') == true ||
          device.name?.toLowerCase().contains('vsc') == true
      ).toList();
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  // Auto connect ke printer yang sudah pernah terhubung
  static Future<bool> autoConnect() async {
    try {
      List<BluetoothDevice> printers = await getAvailablePrinters();
      if (printers.isNotEmpty) {
        return await connectToPrinter(printers.first);
      }
      return false;
    } catch (e) {
      print('Error auto connecting: $e');
      return false;
    }
  }
}