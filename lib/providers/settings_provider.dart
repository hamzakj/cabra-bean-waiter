import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SettingsProvider with ChangeNotifier {
  String _cashierPhone = '962791046258';
  String _waiterName = 'أحمد';
  String _cafeName = 'Cabra Bean - كابرا بين';

  String get cashierPhone => _cashierPhone;
  String get waiterName => _waiterName;
  String get cafeName => _cafeName;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _cashierPhone = await DBHelper.instance.getSetting('cashier_phone', defaultValue: '962791046258');
    _waiterName = await DBHelper.instance.getSetting('waiter_name', defaultValue: 'أحمد');
    _cafeName = await DBHelper.instance.getSetting('cafe_name', defaultValue: 'Cabra Bean - كابرا بين');
    notifyListeners();
  }

  Future<void> setCashierPhone(String phone) async {
    _cashierPhone = phone.trim();
    await DBHelper.instance.setSetting('cashier_phone', _cashierPhone);
    notifyListeners();
  }

  Future<void> setWaiterName(String name) async {
    _waiterName = name.trim();
    await DBHelper.instance.setSetting('waiter_name', _waiterName);
    notifyListeners();
  }
}
