import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/category_item.dart';
import '../database/db_helper.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _items = [];
  List<CategoryItem> _categories = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  List<MenuItem> get items => _items;
  List<CategoryItem> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  MenuProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await DBHelper.instance.getAllCategories();
      _items = await DBHelper.instance.getAllMenuItems();
    } catch (e) {
      debugPrint('Error loading menu data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMenuItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await DBHelper.instance.getAllMenuItems();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await DBHelper.instance.getAllCategories();
      notifyListeners();
    } catch (e) {
      _categories = [];
    }
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

  Future<void> addCategory(CategoryItem category) async {
    await DBHelper.instance.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryItem category) async {
    await DBHelper.instance.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await DBHelper.instance.deleteCategory(id);
    if (_selectedCategory == id) {
      _selectedCategory = 'all';
    }
    await loadCategories();
  }
}
