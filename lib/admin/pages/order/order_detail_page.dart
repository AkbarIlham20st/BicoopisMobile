import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/print_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isPrinting = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkPrinterConnection();
  }

  Future<void> _checkPrinterConnection() async {
    bool connected = await PrintService.isConnected();
    setState(() {
      _isConnected = connected;
    });
  }

  Future<void> _connectToPrinter() async {
    try {
      List<BluetoothDevice> printers = await PrintService.getAvailablePrinters();

      if (printers.isEmpty) {
        _showMessage('Tidak ada printer thermal yang ditemukan. Pastikan printer sudah dipasangkan via Bluetooth.');
        return;
      }

      // Jika ada lebih dari 1 printer, tampilkan dialog pilihan
      BluetoothDevice? selectedPrinter;
      if (printers.length == 1) {
        selectedPrinter = printers.first;
      } else {
        selectedPrinter = await _showPrinterSelectionDialog(printers);
      }

      if (selectedPrinter != null) {
        _showMessage('Menghubungkan ke ${selectedPrinter.name}...');
        bool connected = await PrintService.connectToPrinter(selectedPrinter);

        if (connected) {
          setState(() {
            _isConnected = true;
          });
          _showMessage('Berhasil terhubung ke printer!');
        } else {
          _showMessage('Gagal terhubung ke printer. Coba lagi.');
        }
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<BluetoothDevice?> _showPrinterSelectionDialog(List<BluetoothDevice> printers) async {
    return showDialog<BluetoothDevice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Printer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: printers.map((printer) {
                return ListTile(
                  title: Text(printer.name ?? 'Unknown'),
                  subtitle: Text(printer.address ?? ''),
                  onTap: () {
                    Navigator.of(context).pop(printer);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCetakStruk() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Konversi data order ke format PrintService
      Map<String, dynamic> strukData = {
        'namaUsaha': 'Bicopis Indonesian',
        'alamat': 'Jalan Raya, Jl. Dr. Ir. H. Soekarno Merr No.678, Gn. Anyar, Kec. Gn. Anyar, Surabaya',
        'telepon': '0878-5580-4679',
        'kasir': 'Admin',
        'noStruk': widget.order.orderNo,
        'tanggal': widget.order.createdAt ?? DateTime.now(),
        'items': widget.order.items.map((item) => {
          'nama': item['nama_menu'].toString(),
          'qty': int.tryParse(item['qty'].toString()) ?? 1,
          'harga': double.tryParse(item['harga'].toString()) ?? 0,
          'total': double.tryParse(item['subtotal'].toString()) ?? 0,
        }).toList(),
        'subtotal': widget.order.totalHarga.toDouble(),
        'pajak': (widget.order.totalHarga * 0.1).toDouble(), // pajak 10%
        'total': (widget.order.totalHarga * 1.1).toDouble(), // total + pajak
        'bayar': (widget.order.totalHarga * 1.1).toDouble(), // asumsi bayar pas
        'kembalian': 0,
        'nomorMeja': widget.order.nomorMeja,
      };

      // Update data ke PrintService
      PrintService.updateStrukData(strukData);

      // Tampilkan dialog pilihan cetak
      await _showPrintOptionsDialog();

    } catch (e) {
      _showMessage('Error saat menyiapkan struk: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<void> _showPrintOptionsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cetak Struk'),
          content: const Text('Pilih opsi cetak:'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _previewPDF();
              },
              child: const Text('Preview PDF'),
            ),
            TextButton(
              onPressed: _isConnected ? () async {
                Navigator.of(context).pop();
                await _printThermal();
              } : null,
              child: Text(_isConnected ? 'Cetak Thermal' : 'Printer Tidak Terhubung'),
            ),
            if (!_isConnected)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _connectToPrinter();
                },
                child: const Text('Hubungkan Printer'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _previewPDF() async {
    try {
      _showMessage('Menyiapkan preview PDF...');
      await PrintService.previewPDF();
    } catch (e) {
      _showMessage('Gagal menampilkan preview: $e');
    }
  }

  Future<void> _printThermal() async {
    try {
      _showMessage('Mencetak struk...');
      await PrintService.printThermal();
      _showMessage('Struk berhasil dicetak!');
    } catch (e) {
      _showMessage('Gagal mencetak struk: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order No: ${widget.order.orderNo}'),
        actions: [
          if (!_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth),
              onPressed: _connectToPrinter,
              tooltip: 'Hubungkan Printer',
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              onPressed: () {},
              tooltip: 'Printer Terhubung',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Meja: ${widget.order.nomorMeja}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.order.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.order.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.order.createdAt ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),

                      // Items
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.order.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.order.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(item['nama_menu'].toString())),
                                  Expanded(flex: 1, child: Text('${item['qty']}', textAlign: TextAlign.center)),
                                  Expanded(flex: 2, child: Text(
                                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(double.tryParse(item['harga'].toString()) ?? 0),
                                    textAlign: TextAlign.right,
                                  )),
                                  Expanded(flex: 2, child: Text(
                                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(double.tryParse(item['subtotal'].toString()) ?? 0),
                                    textAlign: TextAlign.right,
                                  )),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(widget.order.totalHarga),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kondisional tombol
            if (widget.order.status == 'In Order') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await OrderService().updateOrderStatus(widget.order.id, 'In Process');
                        Navigator.pop(context, true);
                      },
                      child: const Text('Set to In Process'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPrinting ? null : _handleCetakStruk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isPrinting
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Menyiapkan...'),
                        ],
                      )
                          : const Text('Cetak Struk'),
                    ),
                  ),
                ],
              )
            ] else if (widget.order.status == 'In Process') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await OrderService().updateOrderStatus(widget.order.id, 'Completed');
                        Navigator.pop(context, true);
                      },
                      child: const Text('Set to Completed'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPrinting ? null : _handleCetakStruk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isPrinting
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Menyiapkan...'),
                        ],
                      )
                          : const Text('Cetak Struk'),
                    ),
                  ),
                ],
              )
            ] else if (widget.order.status == 'Completed') ...[
              // Untuk status completed, hanya tampilkan tombol cetak struk
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPrinting ? null : _handleCetakStruk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isPrinting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Menyiapkan...'),
                    ],
                  )
                      : const Text('Cetak Struk'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Order':
        return Colors.orange;
      case 'In Process':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}