class OrderDetailModel {
  final String id;
  final String pesananId;
  final String itemName;
  final int quantity;
  final double subTotal;

  OrderDetailModel({
    required this.id,
    required this.pesananId,
    required this.itemName,
    required this.quantity,
    required this.subTotal,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'],
      pesananId: json['pesanan_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      subTotal: (json['sub_total'] as num).toDouble(),
    );
  }
}