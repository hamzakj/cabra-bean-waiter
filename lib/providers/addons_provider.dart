import 'package:flutter/material.dart';
import '../models/addon_item.dart';
import '../database/db_helper.dart';

class AddonsProvider with ChangeNotifier {
  List<AddonItem> _addons = [];
  bool _isLoading = false;

  List<AddonItem> get addons => _addons;
  bool get isLoading => _isLoading;

  List<AddonItem> get availableAddons => _addons.where((a) => a.isAvailable).toList();

  AddonsProvider() {
    loadAddons();
  }

  Future<void> loadAddons() async {
    _isLoading = true;
    notifyListeners();
    try {
      _addons = await DBHelper.instance.getAllAddons();
    } catch (e) {
      _addons = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  List<AddonItem> getAddonsForCategory(String category) {
    return _addons.where((a) => a.isAvailable && (a.category == 'all' || a.category == category)).toList();
  }

  Future<void> addAddon(AddonItem addon) async {
    await DBHelper.instance.insertAddon(addon);
    await loadAddons();
  }

  Future<void> updateAddon(AddonItem addon) async {
    await DBHelper.instance.updateAddon(addon);
    await loadAddons();
  }

  Future<void> deleteAddon(int id) async {
    await DBHelper.instance.deleteAddon(id);
    await loadAddons();
  }

  Future<void> toggleAvailability(AddonItem addon) async {
    final updated = addon.copyWith(isAvailable: !addon.isAvailable);
    await updateAddon(updated);
  }
}
