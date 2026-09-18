import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table_info.dart';

class CartProvider with ChangeNotifier {
  TableInfo? _selectedTable;
  final List<OrderItem> _items = [];
  String _generalNotes = '';

  TableInfo? get selectedTable => _selectedTable;
  List<OrderItem> get items => List.unmodifiable(_items);
  String get generalNotes => _generalNotes;

  bool get isEmpty => _items.isEmpty;
  int get totalItemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalAmount => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  void selectTable(TableInfo? table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setGeneralNotes(String notes) {
    _generalNotes = notes;
    notifyListeners();
  }

  void addItem({
    required MenuItem menuItem,
    required String size,
    int quantity = 1,
    String notes = '',
    double? customUnitPrice,
  }) {
    final unitPrice = customUnitPrice ?? menuItem.getPrice(size);

    // Check if identical item with same size and notes already exists
    final existingIndex = _items.indexWhere(
      (i) => i.menuItemId == menuItem.id && i.size == size && i.notes == notes && (i.unitPrice - unitPrice).abs() < 0.01,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        OrderItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          menuItemId: menuItem.id ?? 0,
          nameAr: menuItem.nameAr,
          nameEn: menuItem.nameEn,
          size: size,
          unitPrice: unitPrice,
          quantity: quantity,
          notes: notes,
        ),
      );
    }
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemNotes(int index, String newNotes) {
    if (index >= 0 && index < _items.length) {
      _items[index].notes = newNotes;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _generalNotes = '';
    notifyListeners();
  }
}
