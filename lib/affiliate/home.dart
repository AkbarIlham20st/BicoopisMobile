import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bicopi_pos/affiliate//home.dart';
import 'member.dart';
import 'detail_member.dart';
import 'points.dart';
import 'package:bicopi_pos/affiliate/popup.dart';
import 'notifikasi.dart';
import 'profil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _commissionData = [];
  List<Map<String, dynamic>> _members = [];
  int _totalPoints = 0;
  int _currentIndex = 0;
  String _selectedFilter = 'Daily';
  String _userName = '...';

  List<FlSpot> _chartData = [];
  List<String> _xLabels = [];

  @override
  void initState() {
    super.initState();
    _getUserData();
    _fetchMembers();
    _fetchChartData();
    _fetchTotalPoints();
    _fetchCommissionData();
  }

  Future<void> _fetchCommissionData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('commissions')
            .select('amount, created_at')
            .eq('id_user', user.id)
            .order('created_at', ascending: true);

        setState(() {
          _commissionData = List<Map<String, dynamic>>.from(response);
        });
      } catch (e) {
        print('Gagal mengambil data komisi: $e');
      }
    }
  }

  Future<void> _fetchMembers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final affiliate = await Supabase.instance.client
            .from('affiliates')
            .select('id')
            .eq('id_user', user.id)
            .maybeSingle();

        if (affiliate == null) {
          print('Affiliate tidak ditemukan untuk user ini');
          return;
        }

        final affiliateId = affiliate['id'];

        final response = await Supabase.instance.client
            .from('members')
            .select('id_user, joined_at, users(username, photo_url)')
            .eq('affiliate_id', affiliateId)
            .order('joined_at', ascending: false);

        setState(() {
          _members = List<Map<String, dynamic>>.from(response);
        });
      } catch (e) {
        print('Gagal mengambil data members: $e');
      }
    }
  }

  Future<void> _fetchTotalPoints() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('affiliates')
            .select('total_points')
            .eq('id_user', user.id)
            .maybeSingle();

        if (response != null && response['total_points'] != null) {
          setState(() {
            _totalPoints = response['total_points'];
          });
        } else {
          print('Total points tidak ditemukan');
        }
      } catch (e) {
        print('Gagal mengambil total points: $e');
      }
    }
  }

  Future<void> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('username')
            .eq('id_user', user.id)
            .maybeSingle();

        if (response != null && response['username'] != null) {
          setState(() {
            _userName = response['username'];
          });
        } else {
          print('Username tidak ditemukan');
        }
      } catch (error) {
        print('Gagal mengambil data user: $error');
      }
    } else {
      print('User belum login');
    }
  }

  Future<void> _fetchChartData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // GUNAKAN UTC UNTUK FILTER DAN DATA
    DateTime now = DateTime.now().toUtc();
    List<String> xLabels = [];
    Map<String, double> grouped = {};

    try {
      final affiliate = await Supabase.instance.client
          .from('affiliates')
          .select('id')
          .eq('id_user', user.id)
          .maybeSingle();

      if (affiliate == null) {
        print('Affiliate tidak ditemukan');
        return;
      }

      final affiliateId = affiliate['id'];
      final response = await Supabase.instance.client
          .from('affiliate_points_log')
          .select('created_at, points_earned')
          .eq('affiliate_id', affiliateId)
          .order('created_at', ascending: true);

      if (_selectedFilter == 'Daily') {
        for (int i = 0; i < 24; i++) {
          String hour = i.toString().padLeft(2, '0') + ":00";
          xLabels.add(hour);
          grouped[hour] = 0;
        }
        for (var item in response) {
          final createdAt = DateTime.parse(item['created_at']); // UTC
          if (createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day) {
            String hour = createdAt.hour.toString().padLeft(2, '0') + ":00";
            grouped[hour] = (grouped[hour] ?? 0) +
                (item['points_earned'] as num).toDouble();
          }
        }
      } else if (_selectedFilter == 'Weekly') {
        List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        DateTime monday = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          String label = days[i];
          xLabels.add(label);
          grouped[label] = 0;
        }
        for (var item in response) {
          final createdAt = DateTime.parse(item['created_at']).toLocal();
          if (createdAt.isAfter(monday.subtract(const Duration(days: 1))) &&
              createdAt.isBefore(monday.add(const Duration(days: 7)))) {
            String label = days[createdAt.weekday - 1];
            grouped[label] = (grouped[label] ?? 0) +
                (item['points_earned'] as num).toDouble();
          }
        }
      } else if (_selectedFilter == 'Monthly') {
        int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          String label = i.toString();
          xLabels.add(label);
          grouped[label] = 0;
        }
        for (var item in response) {
          final createdAt = DateTime.parse(item['created_at']).toLocal();
          if (createdAt.year == now.year && createdAt.month == now.month) {
            String label = createdAt.day.toString();
            grouped[label] = (grouped[label] ?? 0) +
                (item['points_earned'] as num).toDouble();
          }
        }
      }

      final spots = <FlSpot>[
        for (int i = 0; i < xLabels.length; i++)
          FlSpot(i.toDouble(), (grouped[xLabels[i]] ?? 0).toDouble())
      ];

      setState(() {
        _chartData = spots;
        _xLabels = xLabels;
      });
    } catch (e) {
      print('Gagal mengambil data grafik: $e');
      setState(() {
        _chartData = [const FlSpot(0, 0)];
        _xLabels = [];
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Halo $_userName',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/logo_bicopi.png'),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.green,
            height: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildPointsCard(),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Riwayat Komisi',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            items: ['Daily', 'Weekly', 'Monthly']
                                .map((String value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value,
                                    style: GoogleFonts.poppins(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedFilter = newValue!;
                              });
                              _fetchChartData();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade100, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -30,
                              left: -30,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.10),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -20,
                              right: -20,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.08),
                                ),
                              ),
                            ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _chartData.isEmpty
                              ? Center(
                            child: Text(
                              'Tidak ada data komisi untuk periode ini.',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                            ),
                          )
                              : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: _chartData.isNotEmpty
                                  ? _chartData
                                  .map((spot) => spot.y)
                                  .reduce((a, b) => a > b ? a : b) *
                                  1.2
                                  : 1,
                              lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                                  // tooltipBgColor: Colors.green.shade700.withOpacity(0.9),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final idx = spot.x.toInt();
                                      String label = _xLabels.isNotEmpty && idx < _xLabels.length
                                          ? _xLabels[idx]
                                          : '';
                                      return LineTooltipItem(
                                        '$label\n+${spot.y.toInt()} poin',
                                        GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: (() {
                                      if (_chartData.isEmpty) return 1.0;
                                      double maxY = _chartData.length == 1
                                          ? _chartData.first.y
                                          : _chartData
                                          .map((spot) => spot.y)
                                          .reduce((a, b) => a > b ? a : b);
                                      double interval = (maxY / 4).ceilToDouble();
                                      return interval > 0 ? interval : 1.0;
                                    })(),
                                    getTitlesWidget: (value, meta) {
                                      if (value == meta.max) {
                                        return const SizedBox.shrink();
                                      }
                                      String label = value >= 1000
                                          ? '${(value / 1000).toStringAsFixed(1)}K'
                                          : value.toInt().toString();
                                      return Text(
                                        label,
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.left,
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 36,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= _xLabels.length) {
                                        return const SizedBox.shrink();
                                      }

                                      bool showLabel = false;
                                      if (_selectedFilter == 'Daily') {
                                        showLabel = index % 3 == 0 || index == _xLabels.length - 1;
                                      } else if (_selectedFilter == 'Weekly') {
                                        showLabel = true;
                                      } else {
                                        showLabel =
                                            index % ((_xLabels.length / 6).ceil()) == 0 || index == _xLabels.length - 1;
                                      }

                                      if (!showLabel) return const SizedBox.shrink();

                                      return Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          _xLabels[index],
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.green.withOpacity(0.10),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.green.withOpacity(0.15), width: 1),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.green.shade700,
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withOpacity(0.10),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.withOpacity(0.18),
                                        Colors.green.withOpacity(0.01),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  dotData: FlDotData(show: false),
                                  spots: _chartData,
                                  shadow: const Shadow(
                                    color: Color(0x22000000),
                                    blurRadius: 6,
                                    offset: Offset(2, 4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Padding(
                            //   padding: const EdgeInsets.all(12.0),
                            //   child: _chartData.isEmpty
                            //       ? Center(
                            //     child: Text(
                            //       'Tidak ada data komisi untuk periode ini.',
                            //       style: GoogleFonts.poppins(
                            //           fontSize: 14, color: Colors.grey),
                            //     ),
                            //   )
                            //       : LineChart(
                            //     LineChartData(
                            //       minY: 0,
                            //       maxY: _chartData.isNotEmpty
                            //           ? _chartData
                            //           .map((spot) => spot.y)
                            //           .reduce((a, b) =>
                            //       a > b ? a : b) *
                            //           1.2
                            //           : 1,
                            //       lineTouchData: LineTouchData(
                            //         enabled: true,
                            //         handleBuiltInTouches: true,
                            //         touchTooltipData:
                            //         LineTouchTooltipData(
                            //           tooltipBgColor: Colors
                            //               .green.shade700
                            //               .withOpacity(0.9),
                            //           getTooltipItems: (touchedSpots) {
                            //             return touchedSpots.map((spot) {
                            //               final idx = spot.x.toInt();
                            //               String label = _xLabels
                            //                   .isNotEmpty &&
                            //                   idx < _xLabels.length
                            //                   ? _xLabels[idx]
                            //                   : '';
                            //               return LineTooltipItem(
                            //                 '$label\n+${spot.y.toInt()} poin',
                            //                 GoogleFonts.poppins(
                            //                   color: Colors.white,
                            //                   fontWeight: FontWeight.w600,
                            //                   fontSize: 13,
                            //                 ),
                            //               );
                            //             }).toList();
                            //           },
                            //         ),
                            //       ),
                            //       titlesData: FlTitlesData(
                            //         leftTitles: AxisTitles(
                            //           sideTitles: SideTitles(
                            //             showTitles: true,
                            //             reservedSize: 40,
                            //             getTitlesWidget:
                            //                 (value, meta) {
                            //               if (value == meta.max) {
                            //                 return const SizedBox.shrink();
                            //               }
                            //               String label = value >= 1000
                            //                   ? '${(value / 1000).toStringAsFixed(1)}K'
                            //                   : value.toInt().toString();
                            //               return Text(
                            //                 label,
                            //                 style: const TextStyle(
                            //                     fontSize: 10),
                            //                 textAlign: TextAlign.left,
                            //               );
                            //             },
                            //             interval: (() {
                            //               if (_chartData.isEmpty)
                            //                 return 1.0;
                            //               double maxY = _chartData
                            //                   .length ==
                            //                   1
                            //                   ? _chartData.first.y
                            //                   : _chartData
                            //                   .map((spot) => spot.y)
                            //                   .reduce((a, b) =>
                            //               a > b ? a : b);
                            //               double interval =
                            //               (maxY / 4).ceilToDouble();
                            //               return interval > 0
                            //                   ? interval
                            //                   : 1.0;
                            //             })(),
                            //           ),
                            //         ),
                            //         bottomTitles: AxisTitles(
                            //           sideTitles: SideTitles(
                            //             showTitles: true,
                            //             getTitlesWidget:
                            //                 (value, meta) {
                            //               final index = value.toInt();
                            //               if (index < 0 ||
                            //                   index >= _xLabels.length) {
                            //                 return const SizedBox();
                            //               }
                            //               bool showLabel = false;
                            //               if (_selectedFilter ==
                            //                   'Daily') {
                            //                 showLabel = index % 3 == 0 ||
                            //                     index ==
                            //                         _xLabels.length - 1;
                            //               } else if (_selectedFilter ==
                            //                   'Weekly') {
                            //                 showLabel = true;
                            //               } else {
                            //                 showLabel = index %
                            //                     ((_xLabels.length /
                            //                         6)
                            //                         .ceil()) ==
                            //                     0 ||
                            //                     index ==
                            //                         _xLabels.length - 1;
                            //               }
                            //               return showLabel
                            //                   ? SideTitleWidget(
                            //                 axisSide: meta.axisSide,
                            //                 space: 10,
                            //                 child: Transform.rotate(
                            //                   angle: -0.5,
                            //                   child: Text(
                            //                     _xLabels[index],
                            //                     style: const TextStyle(
                            //                         fontSize: 11,
                            //                         fontWeight:
                            //                         FontWeight
                            //                             .w500),
                            //                     overflow:
                            //                     TextOverflow
                            //                         .ellipsis,
                            //                   ),
                            //                 ),
                            //               )
                            //                   : const SizedBox();
                            //             },
                            //             interval: 1,
                            //             reservedSize: 36,
                            //           ),
                            //         ),
                            //         rightTitles: AxisTitles(
                            //             sideTitles: SideTitles(
                            //                 showTitles: false)),
                            //         topTitles: AxisTitles(
                            //             sideTitles: SideTitles(
                            //                 showTitles: false)),
                            //       ),
                            //       gridData: FlGridData(
                            //         show: true,
                            //         drawHorizontalLine: true,
                            //         drawVerticalLine: false,
                            //         getDrawingHorizontalLine: (value) =>
                            //             FlLine(
                            //               color:
                            //               Colors.green.withOpacity(0.10),
                            //               strokeWidth: 1,
                            //             ),
                            //       ),
                            //       borderData: FlBorderData(
                            //         show: true,
                            //         border: Border.all(
                            //             color: Colors.green
                            //                 .withOpacity(0.15),
                            //             width: 1),
                            //       ),
                            //       lineBarsData: [
                            //         LineChartBarData(
                            //           isCurved: true,
                            //           color: Colors.green.shade700,
                            //           barWidth: 2.5,
                            //           isStrokeCapRound: true,
                            //           belowBarData: BarAreaData(
                            //             show: true,
                            //             color: Colors.green
                            //                 .withOpacity(0.10),
                            //             gradient: LinearGradient(
                            //               colors: [
                            //                 Colors.green
                            //                     .withOpacity(0.18),
                            //                 Colors.green.withOpacity(0.01)
                            //               ],
                            //               begin: Alignment.topCenter,
                            //               end: Alignment.bottomCenter,
                            //             ),
                            //           ),
                            //           dotData: FlDotData(
                            //             show: false,
                            //           ),
                            //           spots: _chartData,
                            //           shadow: const Shadow(
                            //             color: Color(0x22000000),
                            //             blurRadius: 6,
                            //             offset: Offset(2, 4),
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildMembersList(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });

            Widget nextScreen;
            if (index == 1) {
              nextScreen = const PointsScreen();
            } else if (index == 2) {
              nextScreen = const NotificationScreen();
            } else if (index == 3) {
              nextScreen = const ProfileScreen();
            } else {
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Points'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifikasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Point Saat Ini',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          SizedBox(height: 2),
          Text(
            '$_totalPoints',
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Text(
                'Total: ${_members.length}',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500),
              ),
            ],
          ),
          SizedBox(height: 12),
          _members.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Belum ada member yang bergabung.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          )
              : Column(
            children: List.generate(
              _members.length > 3 ? 3 : _members.length,
                  (i) {
                final member = _members[i];
                final name =
                    member['users']?['username'] ?? 'Tidak diketahui';
                final date = member['joined_at'] != null
                    ? member['joined_at'].toString().substring(0, 10)
                    : 'Tidak diketahui';
                final image =
                    member['users']?['photo_url'] ?? 'assets/profil.png';
                final isBaru = i == 0; // member terbaru

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      (image.isEmpty || image == 'assets/profil.png')
                          ? AssetImage('assets/profil.png')
                          : (image.startsWith('http')
                          ? NetworkImage(image)
                          : AssetImage(image)) as ImageProvider,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isBaru)
                          Container(
                            margin: EdgeInsets.only(left: 6),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Baru',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      'Bergabung $date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemberScreen()),
                );
              },
              child: Text(
                'Lihat Semua Member',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemberItem extends StatelessWidget {
  final String name;
  final String date;
  final String image;

  const MemberItem({
    Key? key,
    required this.name,
    required this.date,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (image.startsWith('http://') || image.startsWith('https://')) {
      imageProvider = NetworkImage(image);
    } else {
      imageProvider = AssetImage(image);
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: imageProvider,
        backgroundColor: Colors.grey.shade200,
        child: imageProvider is NetworkImage && image.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        name,
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      subtitle: Text(
        'Bergabung $date',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}