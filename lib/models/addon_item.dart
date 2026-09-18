class AddonItem {
  final int? id;
  final String nameAr;
  final String nameEn;
  final double price;
  final String category; // 'all' or category id like 'hot_coffee'
  final bool isAvailable;

  AddonItem({
    this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    this.category = 'all',
    this.isAvailable = true,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'category': category,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory AddonItem.fromMap(Map<String, dynamic> map) {
    return AddonItem(
      id: map['id'] as int?,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      price: (map['price'] as num).toDouble(),
      category: (map['category'] as String?) ?? 'all',
      isAvailable: (map['is_available'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory AddonItem.fromJson(Map<String, dynamic> json) => AddonItem.fromMap(json);

  AddonItem copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    double? price,
    String? category,
    bool? isAvailable,
  }) {
    return AddonItem(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
