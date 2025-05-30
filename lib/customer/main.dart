import 'package:bicopi_pos/customer/menu_paket.dart';
import 'package:bicopi_pos/customer/reservasi.dart';
// import 'package:bicopi_pos/customer/profile.dart'; // Pastikan import ProfileScreen
import 'package:bicopi_pos/customer/search_menu_page.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'menu_makanan.dart' as makanan;
import 'menu_minuman.dart';
import 'menu_snack.dart' as snack;
import 'splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reedem.dart';
import 'cart_halaman.dart'; // Import halaman CartPage
import 'register.dart';
import 'login.dart';
import 'menu_list_from_db.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_history_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  int? _focusedIndex; // Menyimpan indeks item yang sedang ditekan
  final Map<String, int> _cart =
      {}; // Menyimpan item dalam keranjang (nama: jumlah)
  String? _memberId; // To store the member ID
  bool _isMemberIdLoading = true; // New state to track loading

  @override
  void initState() {
    super.initState();
    filteredMenus = allMenus;
    _initializeMemberId(); // Call this to get the member ID on init
  }

  // New function to get the member ID
  Future<void> _initializeMemberId() async {
    setState(() {
      _isMemberIdLoading = true; // Start loading
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // First, check the 'members' table for the user's id_user
        final response = await Supabase.instance.client
            .from(
                'members') // Assuming 'members' table holds the member's id_user
            .select(
                'id_user') // Select the 'id_user' column from the 'members' table
            .eq('id',
                user.id) // Assuming 'id' in 'members' table is linked to auth.users.id
            .maybeSingle(); // Use maybeSingle() if it might not exist

        if (response != null && response['id_user'] != null) {
          setState(() {
            _memberId = response['id_user'] as String;
            _isMemberIdLoading = false; // Finished loading
          });
          print(
              'Fetched member ID (id_user from members table): $_memberId'); // For debugging
        } else {
          print(
              'Member profile (id_user in members table) not found for current user ID: ${user.id}');
          setState(() {
            _memberId = user
                .id; // Fallback to auth.users.id if members table doesn't have it
            _isMemberIdLoading = false; // Finished loading
          });
          print('Using auth.users.id as fallback: $_memberId');
        }
      } catch (e) {
        print('Error fetching member ID from members table: $e');
        setState(() {
          _memberId = user.id; // Fallback to auth.users.id on error
          _isMemberIdLoading = false; // Finished loading
        });
        print('Using auth.users.id as fallback due to error: $_memberId');
      }
    } else {
      print('No user logged in. Member ID cannot be fetched.');
      setState(() {
        _memberId = null; // No user, so no member ID
        _isMemberIdLoading = false; // Finished loading
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Update this list to EXCLUDE ProfileScreen
  final List<Widget> _pages = [
    HomeContent(addItemToCart: (itemName) {
      // Implement your addItemToCart logic here or pass it from HomeContent
      // For now, let's keep it simple as it's passed directly to HomeContent
    }),
    ReservasiPage(selectedItem: {}),
    RewardPage(memberId: ''),
    // Show ProfileScreen instead of PaymentHistoryPage
    const ProfileScreen(),
  ];

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _focusedIndex = index; // Set fokus saat item ditekan
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200), // Animasi lebih cepat
      curve: Curves.easeInOut,
    );
    // Reset fokus setelah animasi selesai (opsional)
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _focusedIndex = null;
      });
    });
  }

  void _onCartButtonTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: _cart,
          menu_makanan: _getFoodMenuPrices(),
          menu_minuman: _getDrinkMenuPrices(),
          menu_snack: {},
          menu_paket: {},
        ),
      ),
    );
  }

  List<Map<String, dynamic>> allMenus = [
    {"name": "Ricebowl", "price": 15000, "image": "assets/ricebowl.png"},
    {
      "name": "Mie Goreng Jawa",
      "price": 14000,
      "image": "assets/mie_goreng.png"
    },
    {"name": "Bakso Campur", "price": 13000, "image": "assets/bakso.png"},
    {
      "name": "Nasi Goreng Jawa",
      "price": 14000,
      "image": "assets/nasi_goreng.png"
    },
  ];
  List<Map<String, dynamic>> filteredMenus = [];

  void _filterMenu(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMenus = allMenus;
      } else {
        filteredMenus = allMenus
            .where((menu) =>
                menu["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void navigateToMenuPage(String categoryName, BuildContext context) {
    if (categoryName == "Minuman") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DrinkMenuPage(
                  categoryName: '',
                )),
      );
    } else if (categoryName == "Snack") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => snack.SnackMenuPage(
                  categoryName: '3',
                )),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => makanan.FoodMenuPage(
                  categoryName: categoryName,
                  categoryId: 2,
                )),
      );
    }
  }

  void _addItemToCart(String itemName) {
    setState(() {
      _cart[itemName] = (_cart[itemName] ?? 0) + 1;
    });
    print("Keranjang: $_cart"); // Untuk debugging
  }

  Map<String, int> _getFoodMenuPrices() {
    Map<String, int> prices = {};
    // Anda perlu mengganti ini dengan data harga menu makanan Anda
    for (var menu in allMenus) {
      if (["Ricebowl", "Mie Goreng Jawa", "Bakso Campur", "Nasi Goreng Jawa"]
          .contains(menu["name"])) {
        prices[menu["name"]] = menu["price"] as int;
      }
    }
    return prices;
  }

  Map<String, int> _getDrinkMenuPrices() {
    Map<String, int> prices = {};
    // Anda perlu mengganti ini dengan data harga menu minuman Anda
    // Contoh: prices["Boba"] = 15000;
    return prices;
  }

  @override
  Widget build(BuildContext context) {
    // If memberId is still loading, show a loading indicator or handle it
    if (_isMemberIdLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: PageView(
        controller: _pageController,
        // The list of pages should reflect the order of your BottomNavigationBar items.
        // ProfileScreen is now navigated to separately.
        physics: const NeverScrollableScrollPhysics(), // <--- ADD THIS LINE
        children: [
          HomeContent(addItemToCart: _addItemToCart), // Home (index 0)
          ReservasiPage(selectedItem: {}), // Reservasi (index 1)
          RewardPage(memberId: _memberId ?? ''), // Pass _memberId here
          // PaymentHistoryPage needs memberId, so pass the actual _memberId
          PaymentHistoryPage(memberId: _memberId ?? ''), // Pass _memberId here
        ],
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _focusedIndex = null; // Reset fokus saat halaman berubah
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCartButtonTapped,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        child: const Icon(Icons.shopping_cart,
            color: Color(0xFF078603), size: 28),
        elevation: 19,
        shape: const CircleBorder(), // <-- pastikan ini membuatnya bulat
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Material(
        elevation: 8.0,
        shadowColor: Colors.black.withOpacity(0.2),
        child: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0), // Kurangi padding vertikal
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(
                  index: 0,
                  icon: Icons.home,
                  label: 'Home',
                  onTap: _onBottomNavItemTapped,
                  currentIndex: _currentIndex,
                  isFocused: _focusedIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.chair_sharp,
                  label: 'Reservasi',
                  onTap: _onBottomNavItemTapped,
                  currentIndex: _currentIndex,
                  isFocused: _focusedIndex == 1,
                ),
                const SizedBox(width: 48.0), // Spasi untuk FAB
                _buildNavItem(
                  index: 2,
                  icon: Icons.redeem_rounded,
                  label: 'Redeem',
                  onTap: _onBottomNavItemTapped,
                  currentIndex: _currentIndex,
                  isFocused: _focusedIndex == 2,
                ),
                // "Profil" item is now removed from BottomNavigationBar
                // Add the "Riwayat" (Payment History) item here
                _buildNavItem(
                  index: 3, // New index for Riwayat (since Profile is removed)
                  icon: Icons.history, // Choose an appropriate icon
                  label: 'Riwayat',
                  onTap: _onBottomNavItemTapped,
                  currentIndex: _currentIndex,
                  isFocused: _focusedIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Function(int) onTap,
    required int currentIndex,
    bool isFocused = false,
  }) {
    const double iconSize =
        24.0; // Ukuran ikon yang lebih kecil untuk menghindari overflow
    const double textSize = 11.0; // Ukuran teks yang lebih kecil

    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? const Color(0xFF078603) : Colors.grey;
    final double scale = isFocused ? 1.1 : 1.0; // Skala untuk efek "menonjol"

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150), // Durasi animasi
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: textSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bagian HomeContent dan widget lainnya tetap sama seperti sebelumnya.
class HomeContent extends StatelessWidget {
  final Function(String) addItemToCart;

  HomeContent({required this.addItemToCart});
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTopBar(context), // Perhatikan pemanggilan di sini
          _buildCategoryList(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Paket",
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _buildCarousel(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Favorit",
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(
              height: 0.1), // Mengurangi jarak antara "Favorit" dan menu
          _buildMenuList(addItemToCart: addItemToCart), // Pass the callback
        ],
      ),
    );
  }
}

// _buildTopBar harus dipindahkan ke sini atau dijadikan method static di HomeContent
// agar bisa mengakses context dan navigasi
Widget _buildTopBar(BuildContext context) {
  return SafeArea(
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            child: Image.asset(
              'assets/backgroundb.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Green overlay
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 55, 221, 33).withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
          ),
          // Profile icon di pojok kanan atas
          Positioned(
            top: 36,
            right: 35,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfileScreen(), // Navigasi ke ProfileScreen
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                child: Icon(
                  Icons.person,
                  color: Colors.green[800],
                ),
              ),
            ),
          ),
          // Content: Greeting + Logo + Title + Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/bicopi_logo.png', // Ganti dengan path logo kamu
                      height: 50,
                      width: 50,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "BICOPI",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF028A0F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                // Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchMenuPage()),
                    );
                  },
                  child: AbsorbPointer(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Cari menu...",
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF078603),
                            size: 28,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCategoryList(BuildContext context) {
  final categories = [
    {"name": "Makanan", "icon": "assets/icon_miee.png"},
    {"name": "Minuman", "icon": "assets/icon_minuman1.png"},
    {"name": "Snack", "icon": "assets/icon_snack1.png"},
    {"name": "Paket", "icon": "assets/icon_paket1.png"},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((category) {
        return GestureDetector(
          onTap: () {
            if (category["name"] == "Makanan") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => makanan.FoodMenuPage(
                    categoryId: 2,
                    categoryName: '',
                  ), // ID kategori makanan
                ),
              );
            } else if (category["name"] == "Minuman") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DrinkMenuPage(
                          categoryName: '',
                        )),
              );
            } else if (category["name"] == "Snack") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => snack.SnackMenuPage(
                          categoryName: '3',
                        )),
              );
            } else if (category["name"] == "Paket") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PaketMenuPage(
                          categoryName: '4',
                          categoryId: 4,
                        )), // Navigasi ke PaketMenuPage
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 29, 224, 22).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    category["icon"] as String,
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category["name"] as String,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

Widget _buildCarousel() {
  final List<String> imageList = [
    "assets/paketramadhan.png",
    "assets/pakethebat.png",
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: imageList.map((image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      }).toList(),
    ),
  );
}

void _showItemDetails(BuildContext context, Map<String, String> item,
    Function(String itemName) addItemToCart) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Lebih melengkung
        ),
        backgroundColor: Colors.grey[50], // Latar belakang lebih lembut
        title: Text(
          item["name"]!,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // Sedikit lebih tebal
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item["category"]!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item["description"]!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rp ${item["price"]!}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    addItemToCart(item["name"]!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    elevation: 2, // Efek bayangan tipis
                  ),
                  child: const Text("Tambah"),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text("Batal"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end, // Tombol aksi di kanan
      );
    },
  );
}

Widget _buildMenuList({required Function(String) addItemToCart}) {
  return MenuListFromDB(
    addItemToCart: addItemToCart,
    categoryId: 5, // misal kategori Minuman
  );
}
