class OrderItem {
  final String id;
  final int menuItemId;
  final String nameAr;
  final String nameEn;
  final String size; // 'S', 'M', 'L', 'Standard'
  final double unitPrice;
  int quantity;
  String notes;

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.nameAr,
    required this.nameEn,
    required this.size,
    required this.unitPrice,
    this.quantity = 1,
    this.notes = '',
  });

  double get totalPrice => unitPrice * quantity;

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  Map<String, dynamic> toMap(int? orderId) {
    return {
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'size': size,
      'unit_price': unitPrice,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] != null ? map['id'].toString() : DateTime.now().microsecondsSinceEpoch.toString(),
      menuItemId: map['menu_item_id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      size: (map['size'] as String?) ?? 'Standard',
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as int?) ?? 1,
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'size': size,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      menuItemId: json['menuItemId'] as int,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      size: json['size'] as String? ?? 'Standard',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as int?) ?? 1,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

class Order {
  final int? id;
  final String orderNumber;
  final int tableId;
  final int tableNumber;
  final String tableName;
  final String waiterName;
  String status; // 'new', 'preparing', 'served', 'completed', 'cancelled'
  final double totalAmount;
  final String generalNotes;
  final DateTime createdAt;
  List<OrderItem> items;

  Order({
    this.id,
    required this.orderNumber,
    required this.tableId,
    required this.tableNumber,
    required this.tableName,
    this.waiterName = '',
    this.status = 'new',
    required this.totalAmount,
    this.generalNotes = '',
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_number': orderNumber,
      'table_id': tableId,
      'table_number': tableNumber,
      'table_name': tableName,
      'waiter_name': waiterName,
      'status': status,
      'total_amount': totalAmount,
      'general_notes': generalNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      id: map['id'] as int?,
      orderNumber: map['order_number'] as String,
      tableId: map['table_id'] as int,
      tableNumber: map['table_number'] as int,
      tableName: map['table_name'] as String,
      waiterName: (map['waiter_name'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'new',
      totalAmount: (map['total_amount'] as num).toDouble(),
      generalNotes: (map['general_notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'tableName': tableName,
      'waiterName': waiterName,
      'status': status,
      'totalAmount': totalAmount,
      'generalNotes': generalNotes,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      orderNumber: json['orderNumber'] as String,
      tableId: json['tableId'] as int,
      tableNumber: json['tableNumber'] as int,
      tableName: json['tableName'] as String,
      waiterName: (json['waiterName'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'new',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      generalNotes: (json['generalNotes'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
