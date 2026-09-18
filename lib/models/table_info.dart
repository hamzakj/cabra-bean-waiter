class TableInfo {
  final int? id;
  final int number;
  final String nameAr;
  final String nameEn;
  final String section; // indoor, terrace, bar, vip
  final bool isOccupied;

  TableInfo({
    this.id,
    required this.number,
    required this.nameAr,
    required this.nameEn,
    this.section = 'indoor',
    this.isOccupied = false,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'number': number,
      'name_ar': nameAr,
      'name_en': nameEn,
      'section': section,
      'is_occupied': isOccupied ? 1 : 0,
    };
  }

  factory TableInfo.fromMap(Map<String, dynamic> map) {
    return TableInfo(
      id: map['id'] as int?,
      number: map['number'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      section: (map['section'] as String?) ?? 'indoor',
      isOccupied: (map['is_occupied'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory TableInfo.fromJson(Map<String, dynamic> json) => TableInfo.fromMap(json);

  TableInfo copyWith({
    int? id,
    int? number,
    String? nameAr,
    String? nameEn,
    String? section,
    bool? isOccupied,
  }) {
    return TableInfo(
      id: id ?? this.id,
      number: number ?? this.number,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      section: section ?? this.section,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
