import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/table_info.dart';
import '../database/db_helper.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  String _statusFilter = 'all';
  int? _tableFilter;
  bool _isLoading = false;

  List<Order> get orders => _orders;
  String get statusFilter => _statusFilter;
  int? get tableFilter => _tableFilter;
  bool get isLoading => _isLoading;

  OrdersProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await DBHelper.instance.getAllOrders();
    } catch (e) {
      _orders = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTableFilter(int? tableNumber) {
    _tableFilter = tableNumber;
    notifyListeners();
  }

  List<Order> get filteredOrders {
    return _orders.where((order) {
      final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;
      final matchesTable = _tableFilter == null || order.tableNumber == _tableFilter;
      return matchesStatus && matchesTable;
    }).toList();
  }

  int get newCount => _orders.where((o) => o.status == 'new').length;
  int get preparingCount => _orders.where((o) => o.status == 'preparing').length;
  int get servedCount => _orders.where((o) => o.status == 'served').length;
  int get completedCount => _orders.where((o) => o.status == 'completed').length;

  Future<Order?> getActiveOrderByTable(int tableNumber) async {
    return await DBHelper.instance.getActiveOrderByTable(tableNumber);
  }

  Future<Order> createOrder({
    required TableInfo table,
    required List<OrderItem> items,
    required String generalNotes,
    required String waiterName,
  }) async {
    final now = DateTime.now();
    final orderNum = '#${table.number}-${now.hour}${now.minute}${now.second % 100}';
    final total = items.fold(0.0, (sum, i) => sum + i.totalPrice);

    final order = Order(
      orderNumber: orderNum,
      tableId: table.id ?? table.number,
      tableNumber: table.number,
      tableName: table.nameAr,
      waiterName: waiterName,
      status: 'new',
      totalAmount: total,
      generalNotes: generalNotes,
      createdAt: now,
      items: items,
    );

    final orderId = await DBHelper.instance.insertOrder(order);
    final savedOrder = Order(
      id: orderId,
      orderNumber: order.orderNumber,
      tableId: order.tableId,
      tableNumber: order.tableNumber,
      tableName: order.tableName,
      waiterName: order.waiterName,
      status: order.status,
      totalAmount: order.totalAmount,
      generalNotes: order.generalNotes,
      createdAt: order.createdAt,
      items: order.items,
    );

    await loadOrders();
    return savedOrder;
  }

  // Merges into existing active order for this table if occupied, otherwise creates new
  Future<({Order order, bool isMerged, List<OrderItem> addedItems, double previousTotal})> createOrMergeOrder({
    required TableInfo table,
    required List<OrderItem> items,
    required String generalNotes,
    required String waiterName,
  }) async {
    final existingActiveOrder = await DBHelper.instance.getActiveOrderByTable(table.number);

    if (existingActiveOrder != null && existingActiveOrder.id != null) {
      final prevTotal = existingActiveOrder.totalAmount;
      final updatedOrder = await DBHelper.instance.appendItemsToOrder(
        existingActiveOrder.id!,
        items,
        additionalNotes: generalNotes,
      );
      await loadOrders();
      return (
        order: updatedOrder,
        isMerged: true,
        addedItems: items,
        previousTotal: prevTotal,
      );
    } else {
      final newOrder = await createOrder(
        table: table,
        items: items,
        generalNotes: generalNotes,
        waiterName: waiterName,
      );
      return (
        order: newOrder,
        isMerged: false,
        addedItems: items,
        previousTotal: 0.0,
      );
    }
  }

  Future<void> updateStatus(int orderId, String newStatus) async {
    await DBHelper.instance.updateOrderStatus(orderId, newStatus);
    await loadOrders();
  }
}
