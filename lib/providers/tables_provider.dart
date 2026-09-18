import 'package:flutter/material.dart';
import '../models/table_info.dart';
import '../database/db_helper.dart';

class TablesProvider with ChangeNotifier {
  List<TableInfo> _tables = [];
  bool _isLoading = false;

  List<TableInfo> get tables => _tables;
  bool get isLoading => _isLoading;

  TablesProvider() {
    loadTables();
  }

  Future<void> loadTables() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tables = await DBHelper.instance.getAllTables();
    } catch (e) {
      _tables = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTable(TableInfo table) async {
    await DBHelper.instance.insertTable(table);
    await loadTables();
  }

  Future<void> updateTable(TableInfo table) async {
    await DBHelper.instance.updateTable(table);
    await loadTables();
  }

  Future<void> deleteTable(int id) async {
    await DBHelper.instance.deleteTable(id);
    await loadTables();
  }

  TableInfo? getTableByNumber(int number) {
    try {
      return _tables.firstWhere((t) => t.number == number);
    } catch (_) {
      return null;
    }
  }

  TableInfo? getTableById(int id) {
    try {
      return _tables.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
