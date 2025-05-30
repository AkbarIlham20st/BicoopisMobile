import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'payment.dart';

final formatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class CartPage extends StatefulWidget {
  final Map<String, int> cartItems;

  const CartPage({
    super.key,
    required this.cartItems,
    required Map<String, int> menu_makanan,
    required Map menu_snack,
    required Map menu_paket,
    required Map<String, int> menu_minuman,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<String, int> cartItems;
  Map<String, int> semuaHargaMenu = {};
  int serviceFee = 2000;
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    cartItems = Map.from(widget.cartItems);
    final user = Supabase.instance.client.auth.currentUser;
    userId = user?.id;
    _initializeCart();
    _loadCartFromSupabase();
    _loadHargaMenu();
  }

  Future<void> _initializeCart() async {
    await _loadHargaMenu();
    await _loadCartFromSupabase();
  }

  Future<void> _loadHargaMenu() async {
    final response = await Supabase.instance.client
        .from('menu')
        .select('nama_menu, harga_menu');

    if (response != null && response.isNotEmpty) {
      setState(() {
        semuaHargaMenu = {
          for (var item in response)
            item['nama_menu']: (item['harga_menu'] as num).toInt(),
        };
      });
    }
  }

  Future<void> _loadCartFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (userId == null) return;

    try {
      final response =
          await supabase.from('keranjang').select().eq('user_id', userId!);

      for (var item in response) {
        String name = item['item_name'];
        int quantity = item['quantity'];
        cartItems[name] = quantity;
      }
      setState(() {});
    } catch (e) {
      print('Gagal memuat data keranjang: $e');
    }
  }

  Future<void> _updateQuantityInSupabase(String itemName, int quantity) async {
    final supabase = Supabase.instance.client;
    if (userId == null) return;

    final price = semuaHargaMenu[itemName] ?? 0;
    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await supabase.from('keranjang').upsert({
        'user_id': userId,
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
          .eq('user_id', userId!)
          .eq('item_name', itemName);
    }
  }

  void _increaseQuantity(String itemName) async {
    if (!cartItems.containsKey(itemName)) return;
    setState(() {
      cartItems[itemName] = cartItems[itemName]! + 1;
    });
    await _updateQuantityInSupabase(itemName, cartItems[itemName]!);
  }

  void _decreaseQuantity(String itemName) async {
    if (!cartItems.containsKey(itemName)) return;
    final currentQty = cartItems[itemName]!;
    if (currentQty > 1) {
      setState(() {
        cartItems[itemName] = currentQty - 1;
      });
      await _updateQuantityInSupabase(itemName, currentQty - 1);
    } else {
      setState(() {
        cartItems.remove(itemName);
      });
      await _updateQuantityInSupabase(itemName, 0);
    }
  }

  int _calculateSubtotal() {
    return cartItems.entries.fold(0, (sum, entry) {
      int price = semuaHargaMenu[entry.key] ?? 0;
      return sum + (price * entry.value);
    });
  }

  int _calculateTotalPrice() {
    return _calculateSubtotal() + serviceFee;
  }

  Future<void> _saveCartToSupabase() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();

    if (userId == null) return;

    try {
      for (var entry in cartItems.entries) {
        final itemName = entry.key;
        final quantity = entry.value;
        final price = semuaHargaMenu[itemName] ?? 0;

        if (quantity > 0) {
          await supabase.from('keranjang').upsert({
            'user_id': userId,
            'item_name': itemName,
            'quantity': quantity,
            'price': price,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error saat menyimpan ke Supabase: $e');
    }
  }

  Future<String?> _fetchMemberIdFromProfiles() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    print("Mencoba mendapatkan member ID untuk user: $userId");
    if (userId == null) {
      print("User ID null, mengembalikan null");
      return null;
    }
    try {
      final response = await supabase
          .from('profil')
          .select('id_user')
          .eq('id_user', userId)
          .single();

      print("Respon dari Supabase: $response");
      if (response == null) {
        print("Respon null, mengembalikan null");
        return null;
      }
      final memberId = response['id_user'] as String?;
      print("Member ID ditemukan: $memberId");
      return memberId;
    } catch (e) {
      print('Error fetching member ID: $e');
      return null;
    }
  }

  Future<void> _clearAllCartItems() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                "Hapus Semua Item?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Apakah Anda yakin ingin menghapus semua item dari keranjang Anda? Tindakan ini tidak dapat dibatalkan.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldProceed == true) {
      setState(() => isLoading = true);
      final supabase = Supabase.instance.client;
      if (userId == null) return;

      try {
        await supabase.from('keranjang').delete().eq('user_id', userId!);

        setState(() {
          cartItems.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Semua item di keranjang telah dihapus.")),
        );
      } catch (e) {
        print('Error clearing cart: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus keranjang.")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _checkout(BuildContext context) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Checkout"),
        content:
            const Text("Apakah Anda yakin ingin melanjutkan ke pembayaran?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Lanjutkan"),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      setState(() => isLoading = true);
      print("Checkout dimulai");
      try {
        print("Mencoba menyimpan keranjang");
        await _saveCartToSupabase();
        print("Keranjang berhasil disimpan");
        final totalPrice = _calculateTotalPrice();
        print("Total harga: $totalPrice");
        if (!mounted) {
          print("Widget tidak lagi mounted, membatalkan navigasi");
          return;
        }
        print("Navigasi ke PaymentPage");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              totalPrice: totalPrice,
              getMemberId: _fetchMemberIdFromProfiles,
            ),
          ),
        );
        print("Navigasi selesai");
      } catch (e) {
        print("Error saat checkout: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal melakukan checkout.")),
        );
      } finally {
        setState(() => isLoading = false);
        print("Checkout selesai (loading diatur ke false)");
      }
    } else {
      print("Pengguna membatalkan checkout");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Lighter background
      body: Column(
        children: [
          CustomAppBar(
            onClearCart: _clearAllCartItems, // Pass the new method here
          ),
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      "Keranjang masih kosong",
                      style: TextStyle(
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              String itemName = cartItems.keys.elementAt(index);
                              int quantity = cartItems[itemName]!;
                              int itemPrice = semuaHargaMenu[itemName] ?? 0;

                              return CartItemCard(
                                itemName: itemName,
                                quantity: quantity,
                                itemPrice: itemPrice,
                                onIncrease: () => _increaseQuantity(itemName),
                                onDecrease: () => _decreaseQuantity(itemName),
                              );
                            },
                          ),
                        ),
                        PaymentSummaryCard(
                          subtotal: _calculateSubtotal(),
                          serviceFee: serviceFee,
                          total: _calculateTotalPrice(),
                          isLoading: isLoading,
                          onCheckout: () => _checkout(context),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Komponen UI

class CartItemCard extends StatelessWidget {
  final String itemName;
  final int quantity;
  final int itemPrice;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartItemCard({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.itemPrice,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = itemPrice * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Slightly less rounded
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 12), // Reduced padding
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                        fontSize: 13, // Reduced from 15
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    "${formatter.format(itemPrice)} x $quantity",
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey), // Reduced from 12
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  Text(
                    "Total: ${formatter.format(totalPrice)}",
                    style: const TextStyle(
                        fontSize: 11, // Reduced from 13
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF078603)),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius:
                    BorderRadius.circular(16), // Smaller border radius
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 20), // Smaller icon size
                    tooltip: 'Kurangi jumlah',
                  ),
                  Text(
                    "$quantity",
                    style: const TextStyle(
                        fontSize: 12, // Reduced from 14
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333)),
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFF078603),
                        size: 20), // Smaller icon size
                    tooltip: 'Tambah jumlah',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final int subtotal;
  final int serviceFee;
  final int total;
  final bool isLoading;
  final VoidCallback onCheckout;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Detail Pembayaran",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow("Subtotal", subtotal, Colors.black87),
            const SizedBox(height: 8),
            _buildSummaryRow("Biaya Layanan", serviceFee, Colors.black87),
            const Divider(height: 30, thickness: 1.5, color: Colors.grey),
            _buildSummaryRow("Total", total, const Color(0xFF078603),
                isTotal: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF078603),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Checkout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, int amount, Color color,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF078603) : color,
          ),
        ),
      ],
    );
  }
}

class CustomAppBar extends StatelessWidget {
  final VoidCallback? onClearCart; // New callback for clearing cart

  const CustomAppBar({super.key, this.onClearCart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF078603),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Keranjang Anda",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "Bicopi, Indonesia",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(), // Add a spacer to push the clear button to the right
          if (onClearCart !=
              null) // Only show the button if the callback is provided
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: onClearCart,
              tooltip: 'Hapus Semua Keranjang',
            ),
        ],
      ),
    );
  }
}
