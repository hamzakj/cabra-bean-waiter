import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../database/db_helper.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _items = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  List<MenuItem> get items => _items;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  MenuProvider() {
    loadMenuItems();
  }

  Future<void> loadMenuItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await DBHelper.instance.getAllMenuItems();
    } catch (e) {
      _items = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  List<MenuItem> get filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.nameAr.toLowerCase().contains(_searchQuery) ||
          item.nameEn.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> addItem(MenuItem item) async {
    await DBHelper.instance.insertMenuItem(item);
    await loadMenuItems();
  }

  Future<void> updateItem(MenuItem item) async {
    await DBHelper.instance.updateMenuItem(item);
    await loadMenuItems();
  }

  Future<void> deleteItem(int id) async {
    await DBHelper.instance.deleteMenuItem(id);
    await loadMenuItems();
  }
}
