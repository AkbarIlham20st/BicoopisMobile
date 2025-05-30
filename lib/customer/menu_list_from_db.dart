import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class MenuListFromDB extends StatefulWidget {
  final int categoryId;

  const MenuListFromDB({
    Key? key,
    required this.categoryId,
    required Function(String p1) addItemToCart,
  }) : super(key: key);

  @override
  State<MenuListFromDB> createState() => _MenuListFromDBState();
}

class _MenuListFromDBState extends State<MenuListFromDB> {
  final Map<String, int> cartQuantities = {};
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> menuMakanan = {};
  Map<String, int> menuMinuman = {};
  Map<String, int> menuSnack = {};
  Map<String, int> menuPaket = {};

  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchMenuData();
    _loadCartFromDatabase();
  }

  // Future<void> fetchMenuData() async {
  //   final supabase = Supabase.instance.client;
  //   final response = await supabase
  //       .from('menu')
  //       .select()
  //       .eq('id_kategori_menu', widget.categoryId)
  //       .execute();
  //
  //   if (response.error != null) {
  //     throw Exception('Failed to load data: ${response.error!.message}');
  //   }
  //
  //   final data = List<Map<String, dynamic>>.from(response.data);
  //   if (!mounted) return;
  //   setState(() {
  //     menuItems = data;
  //     for (var item in data) {
  //       final String itemName = item['nama_menu'];
  //       final int price = _parsePrice(item['harga_menu']);
  //       final String category = item['kategori'] ?? '';
  //
  //       if (category == 'makanan') {
  //         menuMakanan[itemName] = price;
  //       } else if (category == 'minuman') {
  //         menuMinuman[itemName] = price;
  //       } else if (category == 'snack') {
  //         menuSnack[itemName] = price;
  //       } else if (category == 'paket') {
  //         menuPaket[itemName] = price;
  //       }
  //     }
  //   });
  // }

  Future<void> fetchMenuData() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('menu')
          .select()
          .eq('id_kategori_menu', widget.categoryId);

      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data);

      if (!mounted) return;

      setState(() {
        menuItems = items;
        for (var item in items) {
          final String itemName = item['nama_menu'];
          final int price = _parsePrice(item['harga_menu']);
          final String category = item['kategori'] ?? '';

          if (category == 'makanan') {
            menuMakanan[itemName] = price;
          } else if (category == 'minuman') {
            menuMinuman[itemName] = price;
          } else if (category == 'snack') {
            menuSnack[itemName] = price;
          } else if (category == 'paket') {
            menuPaket[itemName] = price;
          }
        }
      });
    } catch (e) {
      print('Gagal mengambil data: $e');
      // Tambahkan error handling sesuai kebutuhan
    }
  }


  int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll('.', '').replaceAll(',', '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  // Future<void> _loadCartFromDatabase() async {
  //   final user = Supabase.instance.client.auth.currentUser;
  //   if (user == null) return;
  //
  //   final response = await Supabase.instance.client
  //       .from('keranjang')
  //       .select('item_name, quantity')
  //       .eq('user_id', user.id)
  //       .execute();
  //
  //   if (response.error == null) {
  //     final data = List<Map<String, dynamic>>.from(response.data);
  //     if (!mounted) return;
  //     setState(() {
  //       for (var item in data) {
  //         cartQuantities[item['item_name']] = item['quantity'] as int;
  //       }
  //     });
  //   }
  // }

  Future<void> _loadCartFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('keranjang')
          .select('item_name, quantity')
          .eq('user_id', user.id);

      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data);

      if (!mounted) return;
      setState(() {
        for (var item in items) {
          cartQuantities[item['item_name']] = item['quantity'] as int;
        }
      });
    } catch (e) {
      print('Failed to load cart from database: $e');
      // Tambahkan error handling lain jika perlu
    }
  }


  Future<void> _updateCartInDatabase(String itemName, int quantity, int price) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await Supabase.instance.client.from('keranjang').upsert({
        'user_id': user.id,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,item_name');
    } else {
      await Supabase.instance.client
          .from('keranjang')
          .delete()
          .eq('user_id', user.id)
          .eq('item_name', itemName);
    }
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

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    final String itemName = item['nama_menu'];
    final int price = _parsePrice(item['harga_menu']);
    final int quantity = cartQuantities[itemName] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  cartItems: cartQuantities,
                  menu_makanan: menuMakanan,
                  menu_minuman: menuMinuman,
                  menu_snack: menuSnack,
                  menu_paket: menuPaket,
                ),
              ),
            ).then((_) {
              _loadCartFromDatabase();
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF078603),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.white),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quantity > 0 ? "Jumlah Pesanan: $quantity" : "0 Pesanan",
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      formatter.format(price * quantity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final itemName = item['nama_menu'];
          final harga = _parsePrice(item['harga_menu']);
          final quantity = cartQuantities[itemName] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFF8F6FF), // ungu muda
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['foto_menu'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['deskripsi_menu'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(harga),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF078603), // hijau
                        ),
                      ),
                      const SizedBox(height: 8),
                      quantity == 0
                          ? SizedBox(
                              width: 80,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _increaseQuantity(itemName, harga),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF078603),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Tambah",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.red),
                                  onPressed: () => _decreaseQuantity(itemName, harga),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Color(0xFF078603)),
                                  onPressed: () => _increaseQuantity(itemName, harga),
                                ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}