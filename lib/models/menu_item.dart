class MenuItem {
  final int? id;
  final String nameAr;
  final String nameEn;
  final String category;
  final double? priceSmall;
  final double? priceMedium;
  final double? priceLarge;
  final String? description;
  final bool isAvailable;

  MenuItem({
    this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    this.priceSmall,
    this.priceMedium,
    this.priceLarge,
    this.description,
    this.isAvailable = true,
  });

  bool get hasSmall => priceSmall != null && priceSmall! > 0;
  bool get hasMedium => priceMedium != null && priceMedium! > 0;
  bool get hasLarge => priceLarge != null && priceLarge! > 0;

  List<String> get availableSizes {
    final sizes = <String>[];
    if (hasSmall) sizes.add('S');
    if (hasMedium) sizes.add('M');
    if (hasLarge) sizes.add('L');
    if (sizes.isEmpty) sizes.add('Standard');
    return sizes;
  }

  double getPrice(String size) {
    if (size == 'S' && hasSmall) return priceSmall!;
    if (size == 'M' && hasMedium) return priceMedium!;
    if (size == 'L' && hasLarge) return priceLarge!;
    return priceMedium ?? priceSmall ?? priceLarge ?? 0.0;
  }

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'category': category,
      'price_small': priceSmall,
      'price_medium': priceMedium,
      'price_large': priceLarge,
      'description': description,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      category: map['category'] as String,
      priceSmall: map['price_small'] != null ? (map['price_small'] as num).toDouble() : null,
      priceMedium: map['price_medium'] != null ? (map['price_medium'] as num).toDouble() : null,
      priceLarge: map['price_large'] != null ? (map['price_large'] as num).toDouble() : null,
      description: map['description'] as String?,
      isAvailable: (map['is_available'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem.fromMap(json);

  MenuItem copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? category,
    double? priceSmall,
    double? priceMedium,
    double? priceLarge,
    String? description,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      priceSmall: priceSmall ?? this.priceSmall,
      priceMedium: priceMedium ?? this.priceMedium,
      priceLarge: priceLarge ?? this.priceLarge,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
