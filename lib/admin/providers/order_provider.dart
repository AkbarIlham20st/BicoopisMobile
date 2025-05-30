import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> inOrderList = [];
  List<OrderModel> inProcessList = [];
  List<OrderModel> completedList = [];

  Future<void> fetchAllOrders() async {
    print('Fetching all order statuses...');
    inOrderList = await _orderService.fetchOrdersByStatus('In Order');
    print('In Order fetched: ${inOrderList.length}');

    inProcessList = await _orderService.fetchOrdersByStatus('In Process');
    print('In Process fetched: ${inProcessList.length}');

    completedList = await _orderService.fetchOrdersByStatus('Completed');
    print('Completed fetched: ${completedList.length}');

    notifyListeners();
  }
}
