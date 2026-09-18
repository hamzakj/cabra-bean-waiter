import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final String iconName;
  final int sortOrder;

  CategoryItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.iconName = 'coffee',
    this.sortOrder = 0,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  IconData get iconData {
    switch (iconName) {
      case 'coffee':
        return Icons.coffee;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'blender':
        return Icons.blender;
      case 'local_bar':
        return Icons.local_bar;
      case 'wine_bar':
        return Icons.wine_bar;
      case 'icecream':
        return Icons.icecream;
      case 'water_drop':
        return Icons.water_drop;
      case 'cake':
        return Icons.cake;
      case 'fastfood':
        return Icons.fastfood;
      case 'restaurant':
        return Icons.restaurant;
      case 'cookie':
        return Icons.cookie;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'local_drink':
        return Icons.local_drink;
      default:
        return Icons.coffee;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': iconName,
      'sort_order': sortOrder,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      iconName: (map['icon'] as String?) ?? 'coffee',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem.fromMap(json);

  CategoryItem copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? iconName,
    int? sortOrder,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
