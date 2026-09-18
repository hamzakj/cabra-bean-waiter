import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SettingsProvider with ChangeNotifier {
  String _cashierPhone = '962791046258';
  String _waiterName = 'أحمد';
  String _cafeName = 'Cabra Bean - كابرا بين';
  String _printerIp = '192.168.1.134';
  int _printerPort = 9100;
  bool _autoPrintBill = false;

  String get cashierPhone => _cashierPhone;
  String get waiterName => _waiterName;
  String get cafeName => _cafeName;
  String get printerIp => _printerIp;
  int get printerPort => _printerPort;
  bool get autoPrintBill => _autoPrintBill;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _cashierPhone = await DBHelper.instance.getSetting('cashier_phone', defaultValue: '962791046258');
    _waiterName = await DBHelper.instance.getSetting('waiter_name', defaultValue: 'أحمد');
    _cafeName = await DBHelper.instance.getSetting('cafe_name', defaultValue: 'Cabra Bean - كابرا بين');
    _printerIp = await DBHelper.instance.getSetting('printer_ip', defaultValue: '192.168.1.134');
    final portStr = await DBHelper.instance.getSetting('printer_port', defaultValue: '9100');
    _printerPort = int.tryParse(portStr) ?? 9100;
    final autoPrintStr = await DBHelper.instance.getSetting('auto_print_bill', defaultValue: '0');
    _autoPrintBill = autoPrintStr == '1';
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

  Future<void> setPrinterIp(String ip) async {
    _printerIp = ip.trim();
    await DBHelper.instance.setSetting('printer_ip', _printerIp);
    notifyListeners();
  }

  Future<void> setPrinterPort(int port) async {
    _printerPort = port;
    await DBHelper.instance.setSetting('printer_port', port.toString());
    notifyListeners();
  }

  Future<void> setAutoPrintBill(bool value) async {
    _autoPrintBill = value;
    await DBHelper.instance.setSetting('auto_print_bill', value ? '1' : '0');
    notifyListeners();
  }
}
