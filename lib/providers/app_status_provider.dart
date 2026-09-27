import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';

class AppStatusProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String configUrl = 'http://5.181.49.137/cabra_config.json';

  bool _isEnabled = true;
  bool _isChecking = false;
  String? _errorMessage;

  bool get isEnabled => _isEnabled;
  bool get isChecking => _isChecking;
  String? get errorMessage => _errorMessage;

  AppStatusProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initStatus();
  }

  Future<void> _initStatus() async {
    // 1. Read last cached status from database
    try {
      final cached = await DBHelper.instance.getSetting('app_enabled', defaultValue: '1');
      if (cached == '0') {
        _isEnabled = false;
        notifyListeners();
      }
    } catch (_) {}

    // 2. Perform background check on app entry
    await checkStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check only upon re-entering the app from background
    if (state == AppLifecycleState.resumed) {
      checkStatus();
    }
  }

  Future<bool> checkStatus() async {
    _isChecking = true;
    _errorMessage = null;

    try {
      final response = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map && data.containsKey('enabled')) {
          final bool serverEnabled = data['enabled'] == true;
          _isEnabled = serverEnabled;

          // Save last verified status
          try {
            await DBHelper.instance.setSetting('app_enabled', serverEnabled ? '1' : '0');
          } catch (_) {}

          _isChecking = false;
          notifyListeners();
          return _isEnabled;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isChecking = false;
    notifyListeners();
    return _isEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
