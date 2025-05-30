import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class FoodMenuPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const FoodMenuPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> cartQuantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
    _loadCartFromDatabase();
  }

  Future<void> fetchMenuItems() async {
    try {
      final response = await supabase
          .from('menu')
          .select()
          .eq('id_kategori_menu', widget.categoryId);

      setState(() {
        menuItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal fetch data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCartFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
    } catch (e) {
      debugPrint('Gagal memuat data keranjang: $e');
    }
  }

  Future<void> _updateCartInDatabase(
      String itemName, int quantity, int price) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
  }

  int _parseHarga(dynamic harga) {
    try {
      if (harga == null) return 0;
      return (harga as num).toInt();
    } catch (e) {
      debugPrint('Gagal parsing harga: $harga, error: $e');
      return 0;
    }
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = cartQuantities[item["nama_menu"]] ?? 0;
    int price = _parseHarga(item["harga_menu"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF078603),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Pesanan: $quantity",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item["nama_menu"],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Rp ${price * quantity}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(
                          cartItems: cartQuantities,
                          menu_makanan: {
                            for (var item in menuItems)
                              item["nama_menu"]: _parseHarga(item["harga_menu"])
                          },
                          menu_minuman: {},
                          menu_snack: {},
                          menu_paket: {},
                        ),
                      ),
                    ).then((_) {
                      _loadCartFromDatabase();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF078603),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Lihat Keranjang",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF078603),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                          Text(
                            "Menu Makanan",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      const SizedBox(height: 4),
                      const Text(
                        "Bicopi, Indonesia",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Item List
          isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF078603)),
                  ),
                )
              : Expanded(
                  child: menuItems.isEmpty
                      ? const Center(
                          child: Text(
                            "Tidak ada item menu untuk kategori ini.",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            final harga = _parseHarga(item["harga_menu"]);
                            final quantity = cartQuantities[item["nama_menu"]] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center, // Keep center for row alignment
                                  children: [
                                    // Item Image
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
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
                                    ),
                                    const SizedBox(width: 15),

                                    // Item Details (Left side)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["nama_menu"],
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item["deskripsi_menu"] ?? 'No description available.',
                                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // Price is now moved to the right column
                                          // const SizedBox(height: 8), // Removed this spacing
                                        ],
                                      ),
                                    ),

                                    // Quantity Controls / Add Button (Right side)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end, // Align contents to the right
                                      children: [
                                        // Price is now here, above the button/controls
                                        Text(
                                          "Rp $harga",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF078603),
                                          ),
                                        ),
                                        const SizedBox(height: 8), // Spacing between price and button/controls
                                        if (quantity == 0)
                                          ElevatedButton(
                                            onPressed: () => _increaseQuantity(item["nama_menu"], harga),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF078603),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: const Size(80, 35),
                                            ),
                                            child: const Text(
                                              "Tambah",
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          )
                                        else
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                                                  onPressed: () =>
                                                      _decreaseQuantity(item["nama_menu"], harga),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                Text(
                                                  '$quantity',
                                                  style: const TextStyle(
                                                      fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Color(0xFF078603), size: 20),
                                                  onPressed: () =>
                                                      _increaseQuantity(item["nama_menu"], harga),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
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
      // Floating Action Button for Cart
      floatingActionButton: cartQuantities.values.any((qty) => qty > 0)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      cartItems: cartQuantities,
                      menu_makanan: {
                        for (var item in menuItems)
                          item["nama_menu"]: _parseHarga(item["harga_menu"])
                      },
                      menu_minuman: {},
                      menu_snack: {},
                      menu_paket: {},
                    ),
                  ),
                ).then((_) {
                  _loadCartFromDatabase();
                });
              },
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: Text(
                  "Lihat Keranjang (${cartQuantities.values.fold(0, (sum, qty) => sum + qty)})",
                  style: const TextStyle(fontSize: 15)),
              backgroundColor: const Color(0xFF078603),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 6,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}