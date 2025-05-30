import 'order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> orderList = [];
  bool isLoading = false;
  String? errorMessage;
  DateTime? selectedDate;
  String filterType = 'all'; // 'all', 'date', 'month', 'year'

  @override
  void initState() {
    super.initState();
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory({DateTime? filterDate, String filterType = 'all'}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      dynamic response;

      if (filterDate != null && filterType != 'all') {
        DateTime start, end;

        switch (filterType) {
          case 'date':
          // Filter berdasarkan tanggal spesifik
            start = DateTime(filterDate.year, filterDate.month, filterDate.day).toUtc();
            end = start.add(Duration(days: 1)).subtract(Duration(seconds: 1)).toUtc();
            break;
          case 'month':
          // Filter berdasarkan bulan
            start = DateTime(filterDate.year, filterDate.month, 1).toUtc();
            end = DateTime(filterDate.year, filterDate.month + 1, 1)
                .subtract(Duration(seconds: 1))
                .toUtc();
            break;
          case 'year':
          // Filter berdasarkan tahun
            start = DateTime(filterDate.year, 1, 1).toUtc();
            end = DateTime(filterDate.year + 1, 1, 1)
                .subtract(Duration(seconds: 1))
                .toUtc();
            break;
          default:
            start = DateTime.now().toUtc();
            end = DateTime.now().toUtc();
        }

        response = await supabase
            .from('history_kasir')
            .select()
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String())
            .order('created_at', ascending: false);
      } else {
        response = await supabase
            .from('history_kasir')
            .select()
            .order('created_at', ascending: false);
      }

      setState(() {
        orderList = response ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Semua Data'),
                leading: Radio<String>(
                  value: 'all',
                  groupValue: filterType,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _applyFilter('all', null);
                  },
                ),
              ),
              ListTile(
                title: Text('Filter Tanggal'),
                leading: Radio<String>(
                  value: 'date',
                  groupValue: filterType,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _pickSpecificDate();
                  },
                ),
              ),
              ListTile(
                title: Text('Filter Bulan'),
                leading: Radio<String>(
                  value: 'month',
                  groupValue: filterType,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _pickMonthYear();
                  },
                ),
              ),
              ListTile(
                title: Text('Filter Tahun'),
                leading: Radio<String>(
                  value: 'year',
                  groupValue: filterType,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _pickYear();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickSpecificDate() async {
    try {
      final selected = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );

      if (selected != null) {
        _applyFilter('date', selected);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih tanggal: ${e.toString()}')),
      );
    }
  }

  void _pickMonthYear() async {
    try {
      final selected = await showMonthYearPicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );

      if (selected != null) {
        _applyFilter('month', selected);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih bulan: ${e.toString()}')),
      );
    }
  }

  void _pickYear() async {
    try {
      final selected = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pilih Tahun'),
            content: Container(
              width: double.minPositive,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                selectedDate: selectedDate ?? DateTime.now(),
                onChanged: (DateTime dateTime) {
                  Navigator.pop(context, dateTime.year);
                },
              ),
            ),
          );
        },
      );

      if (selected != null) {
        _applyFilter('year', DateTime(selected));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih tahun: ${e.toString()}')),
      );
    }
  }

  void _applyFilter(String type, DateTime? date) {
    setState(() {
      filterType = type;
      selectedDate = date;
    });
    fetchOrderHistory(filterDate: date, filterType: type);
  }

  String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '-';
    }
  }

  String formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _generatePDF(List<dynamic> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada data untuk dicetak')),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final printDate = DateFormat('dd-MM-yyyy HH:mm').format(now);

      final totalPendapatan = data.fold<num>(
        0,
            (sum, item) => sum + (item['total_harga'] ?? 0),
      );

      // Load logo with error handling
      Uint8List? logoImage;
      try {
        final ByteData logoBytes = await rootBundle.load('assets/Bicopi.jpg');
        logoImage = logoBytes.buffer.asUint8List();
      } catch (e) {
        print('Logo tidak ditemukan: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (context) => [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Image(pw.MemoryImage(logoImage), width: 60, height: 60),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Bicopi POS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sistem Point of Sale',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Title and info
            pw.Center(
              child: pw.Text(
                'LAPORAN PENJUALAN',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Waktu Dicetak: $printDate'),
                if (selectedDate != null)
                  pw.Text('Periode: ${DateFormat('MMMM yyyy', 'id').format(selectedDate!)}'),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Table
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Order No',
                'Nama Pelanggan',
                'Meja',
                'Total Item',
                'Total Harga',
                'Tanggal',
              ],
              data: List.generate(data.length, (index) {
                final order = data[index];
                final tanggal = order['created_at'] ?? '';
                final date = DateTime.tryParse(tanggal)?.toLocal();
                final formattedDate = date != null
                    ? DateFormat('dd/MM/yyyy').format(date)
                    : '-';

                return [
                  '${index + 1}',
                  order['order_no']?.toString() ?? '-',
                  order['nama_pelanggan']?.toString() ?? '-',
                  order['nomor_meja']?.toString() ?? '-',
                  '${order['total_item'] ?? 0}',
                  formatCurrency(order['total_harga']),
                  formattedDate,
                ];
              }),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RINGKASAN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Order: ${data.length}'),
                  pw.Text('Total Pendapatan: ${formatCurrency(totalPendapatan)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error membuat PDF: ${e.toString()}')),
      );
    }
  }

  String _getFilterDisplayText() {
    if (filterType == 'all' || selectedDate == null) {
      return 'Semua Data';
    }

    switch (filterType) {
      case 'date':
        return DateFormat('dd MMM yyyy').format(selectedDate!);
      case 'month':
        return DateFormat('MMMM yyyy').format(selectedDate!);
      case 'year':
        return selectedDate!.year.toString();
      default:
        return 'Semua Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('Riwayat Order'),
            Text(
              _getFilterDisplayText(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: "Filter Data",
          ),
          if (filterType != 'all')
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() => selectedDate = null);
                fetchOrderHistory();
              },
              tooltip: "Hapus Filter",
            ),

        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchOrderHistory(filterDate: selectedDate, filterType: filterType),
        child: _buildBody(),
      ),
      floatingActionButton: orderList.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _generatePDF(orderList),
        label: Text('Cetak PDF', style: TextStyle(color: Colors.white),),
        icon: Icon(Icons.print, color: Colors.white,),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => fetchOrderHistory(filterDate: selectedDate, filterType: filterType),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (orderList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              filterType != 'all'
                  ? 'Tidak ada data untuk ${_getFilterDisplayText()}'
                  : 'Tidak ada data order',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[100], // background hijau muda
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300), // outline hijau
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Total Order',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    '${orderList.length}',
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Total Pendapatan',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    formatCurrency(orderList.fold<num>(0, (sum, item) => sum + (item['total_harga'] ?? 0))),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),


        // Order list
        Expanded(
          child: ListView.builder(
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index];
              final items = order['items'] is List
                  ? order['items']
                  : (order['items'] != null
                  ? jsonDecode(order['items'] ?? '[]')
                  : []);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                    backgroundColor: Colors.green, // hijau muda
                    foregroundColor: Colors.white,
                  ),
                  title: Text(
                    'Order No: ${order['order_no']?.toString() ?? "-"}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Nama: ${order['nama_pelanggan']?.toString() ?? "-"}'),
                      Text('Meja: ${order['nomor_meja']?.toString() ?? "-"}'),
                      Text('Total: ${formatCurrency(order['total_harga'])}'),
                      Text('Waktu: ${formatDate(order['created_at'])}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(
                            order: order,
                            items: items,
                          ),
                        ),
                      );
                    },
                    child: Text("Detail", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}