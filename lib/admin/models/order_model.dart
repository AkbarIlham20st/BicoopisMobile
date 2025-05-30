class OrderModel {
  final int id;
  final DateTime createdAt;
  final String orderNo;
  final String nomorMeja;
  final List<dynamic> items;
  final int totalItem;
  final double totalHarga;
  final String status;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.orderNo,
    required this.nomorMeja,
    required this.items,
    required this.totalItem,
    required this.totalHarga,
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      orderNo: json['order_no'],
      nomorMeja: json['nomor_meja'],
      items: json['items'],
      totalItem: json['total_item'],
      totalHarga: (json['total_harga'] as num).toDouble(),
      status: json['status'],
    );
  }
}
