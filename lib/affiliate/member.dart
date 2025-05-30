import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MemberScreen(),
    );
  }
}

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  _MemberScreenState createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMembers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        print('User belum login.');
        return;
      }

      final affiliate = await Supabase.instance.client
          .from('affiliates')
          .select('id')
          .eq('id_user', currentUser.id)
          .maybeSingle();

      if (affiliate == null) {
        print("Kamu belum menjadi affiliate.");
        return;
      }

      final affiliateId = affiliate['id'];

      final response = await Supabase.instance.client
          .from('members')
          .select('*, users (username, email, phone, photo_url)')
          .eq('affiliate_id', affiliateId)
          .order('joined_at', ascending: false);

      final data = response as List;

      setState(() {
        _allMembers = data.cast<Map<String, dynamic>>();
        _members = _allMembers;
        _isLoading = false;
      });
    } catch (e) {
      print('Gagal mengambil data members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMembers(String query) {
    final filtered = _allMembers.where((member) {
      final user = member['users'];
      final name = user?['username']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchQuery = query;
      _members = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8), // abu muda
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Custom AppBar
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.green.shade700),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Member",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 16),
              // Search Field
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  onChanged: _filterMembers,
                  decoration: InputDecoration(
                    hintText: "Cari berdasarkan nama",
                    prefixIcon:
                        Icon(Icons.search, color: Colors.green.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? Expanded(
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.green)))
                  : _members.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text(
                              "Tidak ada member ditemukan.",
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final user = member['users'];
                              final name =
                                  user?['username'] ?? 'Tidak diketahui';
                              final email = user?['email'] ?? '-';
                              final photoUrl = user?['photo_url'] ??
                                  'assets/icons/avatar.png';
                              final joinedAt = member['joined_at'] != null
                                  ? DateTime.parse(member['joined_at'])
                                  : null;
                              final status = member['status'] ?? 'Aktif';

                              ImageProvider memberImageProvider;
                              if (photoUrl.startsWith('http://') ||
                                  photoUrl.startsWith('https://')) {
                                memberImageProvider = NetworkImage(photoUrl);
                              } else {
                                memberImageProvider = AssetImage(photoUrl);
                              }

                              return AnimatedContainer(
                                duration:
                                    Duration(milliseconds: 350 + index * 50),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailMemberScreen(
                                          data: {
                                            'id': member['id'],
                                            'kelipatan': member['kelipatan'],
                                            'presentase': member['presentase'],
                                            'users': member['users'],
                                            'status': member['status'],
                                          },
                                        ),
                                      ),
                                    );
                                    _fetchMembers();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.10),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            backgroundImage: (photoUrl
                                                        .isEmpty ||
                                                    photoUrl ==
                                                        'assets/icons/avatar.png')
                                                ? AssetImage(
                                                    'assets/profil.png')
                                                : (photoUrl.startsWith('http')
                                                        ? NetworkImage(photoUrl)
                                                        : AssetImage(photoUrl))
                                                    as ImageProvider,
                                          ),
                                          // Status badge
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: status == 'Aktif'
                                                    ? Colors.green
                                                    : Colors.orange,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            email,
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 13,
                                                  color: Colors.green.shade300),
                                              SizedBox(width: 4),
                                              Text(
                                                "Bergabung: ${joinedAt != null ? "${joinedAt.day}-${joinedAt.month}-${joinedAt.year}" : "-"}",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.green.shade400,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.arrow_forward_ios,
                                            size: 16, color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
