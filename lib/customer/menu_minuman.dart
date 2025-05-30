import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class DrinkMenuPage extends StatefulWidget {
  final String categoryName;
  const DrinkMenuPage({super.key, required this.categoryName});

  @override
  _DrinkMenuPageState createState() => _DrinkMenuPageState();
}

class _DrinkMenuPageState extends State<DrinkMenuPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> menuItems = [];
  bool isLoading = true;

  Map<String, int> cartQuantities = {};
  int _totalCartItems = 0;

  @override
  void initState() {
    super.initState();
    fetchMenu();
    _loadCartFromDatabase();
  }

  void _calculateTotalCartItems() {
    int total = 0;
    cartQuantities.forEach((key, value) {
      total += value;
    });
    setState(() {
      _totalCartItems = total;
    });
  }

  Future<void> fetchMenu() async {
    try {
      final response = await supabase
          .from('menu')
          .select('nama_menu, foto_menu, deskripsi_menu, harga_menu')
          .eq('id_kategori_menu', 1);

      setState(() {
        menuItems = response.map<Map<String, dynamic>>((item) {
          return {
            "nama_menu": item["nama_menu"],
            "foto_menu": item["foto_menu"],
            "deskripsi_menu": (item["deskripsi_menu"] is String && item["deskripsi_menu"].isNotEmpty)
                ? item["deskripsi_menu"]
                : "Tidak ada deskripsi",
            "harga_menu": (item["harga_menu"] is double)
                ? item["harga_menu"].toInt()
                : item["harga_menu"] ?? 0,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching menu: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCartFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _calculateTotalCartItems();
      return;
    }

    try {
      final response = await supabase
          .from('keranjang')
          .select('item_name, quantity')
          .eq('user_id', user.id);

      setState(() {
        cartQuantities = {
          for (var item in response)
            item['item_name']: item['quantity'] as int,
        };
      });
      _calculateTotalCartItems();
    } catch (e) {
      print("Error loading cart: $e");
    }
  }

  Future<void> _updateCartInDatabase(String itemName, int quantity, int price) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await supabase.from('keranjang').upsert({
        'user_id': user.id,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,item_name');
    } else {
      await supabase
          .from('keranjang')
          .delete()
          .eq('user_id', user.id)
          .eq('item_name', itemName);
    }
    _calculateTotalCartItems();
  }

  void _increaseQuantity(String itemName, int price) {
    setState(() {
      cartQuantities[itemName] = (cartQuantities[itemName] ?? 0) + 1;
    });
    _updateCartInDatabase(itemName, cartQuantities[itemName]!, price);
  }

  void _decreaseQuantity(String itemName, int price) {
    if (cartQuantities[itemName] == null || cartQuantities[itemName]! <= 0) return;

    setState(() {
      cartQuantities[itemName] = cartQuantities[itemName]! - 1;
    });

    if (cartQuantities[itemName]! > 0) {
      _updateCartInDatabase(itemName, cartQuantities[itemName]!, price);
    } else {
      cartQuantities.remove(itemName);
      _updateCartInDatabase(itemName, 0, price);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF078603),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Menu Minuman",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Bicopi, Indonesia",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final harga = item["harga_menu"];
                      final quantity = cartQuantities[item["nama_menu"]] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gambar Menu
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item["foto_menu"] ?? '',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    'assets/no_image.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Detail Nama, Deskripsi (di sisi kiri)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["nama_menu"],
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["deskripsi_menu"],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Harga dan Tombol Tambah/Kontrol Kuantitas (di sisi kanan)
                              SizedBox(
                                width: 100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Rp $harga",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF078603),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    quantity == 0
                                        ? ElevatedButton(
                                            onPressed: () => _increaseQuantity(item["nama_menu"], harga),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF078603),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              // Menyesuaikan padding agar sama dengan FoodMenuPage (misal: 12 vertikal)
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              "Tambah",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _decreaseQuantity(item["nama_menu"], harga),
                                                child: Container(
                                                  // Padding ikon yang lebih besar agar sama dengan FoodMenuPage (misal: 8)
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Icon(Icons.remove, color: Colors.red, size: 20),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  '$quantity',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _increaseQuantity(item["nama_menu"], harga),
                                                child: Container(
                                                  // Padding ikon yang lebih besar agar sama dengan FoodMenuPage (misal: 8)
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF078603).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Icon(Icons.add, color: Color(0xFF078603), size: 20),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _totalCartItems > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      cartItems: cartQuantities,
                      menu_makanan: {},
                      menu_minuman: {
                        for (var item in menuItems)
                          item["nama_menu"]: item["harga_menu"]
                      },
                      menu_snack: {},
                      menu_paket: {},
                    ),
                  ),
                ).then((_) {
                  _loadCartFromDatabase();
                });
              },
              backgroundColor: const Color(0xFF078603),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                "Lihat Keranjang (${_totalCartItems} item)",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            )
          : null,
    );
  }
}