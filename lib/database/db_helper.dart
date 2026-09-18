import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';
import '../models/table_info.dart';
import '../models/order.dart';
import '../models/category_item.dart';
import '../models/addon_item.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  // Web in-memory store
  bool _webInitialized = false;
  final List<MenuItem> _webMenuItems = [];
  final List<TableInfo> _webTables = [];
  final List<Order> _webOrders = [];
  final List<CategoryItem> _webCategories = [];
  final List<AddonItem> _webAddons = [];
  final Map<String, String> _webSettings = {
    'cashier_phone': '962791046258',
    'waiter_name': 'أحمد (النادل)',
    'language': 'ar',
    'cafe_name': 'Cabra Bean - كابرا بين',
  };

  bool _tablesEnsured = false;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      if (!_tablesEnsured) {
        _tablesEnsured = true;
        await _ensureNewTables(_database!);
      }
      return _database!;
    }
    _database = await _initDB('cabra_waiter.db');
    if (!_tablesEnsured) {
      _tablesEnsured = true;
      await _ensureNewTables(_database!);
    }
    return _database!;
  }

  Future<void> _ensureNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'coffee',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS addons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0.0,
        category TEXT NOT NULL DEFAULT 'all',
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    final catCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    if (catCount == 0) {
      for (var cat in _getInitialCategories()) {
        await db.insert('categories', cat.toMap());
      }
    }

    final addonCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM addons')) ?? 0;
    if (addonCount == 0) {
      for (var addon in _getInitialAddons()) {
        await db.insert('addons', addon.toMap());
      }
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        category TEXT NOT NULL,
        price_small REAL,
        price_medium REAL,
        price_large REAL,
        description TEXT,
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL UNIQUE,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        section TEXT NOT NULL DEFAULT 'indoor',
        is_occupied INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL,
        table_id INTEGER NOT NULL,
        table_number INTEGER NOT NULL,
        table_name TEXT NOT NULL,
        waiter_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'new',
        total_amount REAL NOT NULL,
        general_notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_item_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        size TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    await db.insert('settings', {'key': 'cashier_phone', 'value': '962791046258'});
    await db.insert('settings', {'key': 'waiter_name', 'value': 'أحمد (النادل)'});
    await db.insert('settings', {'key': 'language', 'value': 'ar'});
    await db.insert('settings', {'key': 'cafe_name', 'value': 'Cabra Bean - كابرا بين'});

    for (var t in _getInitialTables()) {
      await db.insert('tables', t);
    }

    for (var item in _getInitialItems()) {
      await db.insert('menu_items', item);
    }

    for (var cat in _getInitialCategories()) {
      await db.insert('categories', cat.toMap());
    }

    for (var addon in _getInitialAddons()) {
      await db.insert('addons', addon.toMap());
    }
  }

  void _initWebStore() {
    if (_webInitialized) return;
    int itemId = 1;
    for (var m in _getInitialItems()) {
      _webMenuItems.add(MenuItem(
        id: itemId++,
        nameAr: m['name_ar'] as String,
        nameEn: m['name_en'] as String,
        category: m['category'] as String,
        priceSmall: m['price_small'] as double?,
        priceMedium: m['price_medium'] as double?,
        priceLarge: m['price_large'] as double?,
        description: m['description'] as String?,
      ));
    }

    int tableId = 1;
    for (var t in _getInitialTables()) {
      _webTables.add(TableInfo(
        id: tableId++,
        number: t['number'] as int,
        nameAr: t['name_ar'] as String,
        nameEn: t['name_en'] as String,
        section: t['section'] as String,
        isOccupied: false,
      ));
    }

    if (_webCategories.isEmpty) {
      _webCategories.addAll(_getInitialCategories());
    }

    if (_webAddons.isEmpty) {
      _webAddons.addAll(_getInitialAddons());
    }

    _webInitialized = true;
  }

  List<Map<String, dynamic>> _getInitialTables() {
    return [
      {'number': 1, 'name_ar': 'طاولة 1', 'name_en': 'Table 1', 'section': 'indoor', 'is_occupied': 0},
      {'number': 2, 'name_ar': 'طاولة 2', 'name_en': 'Table 2', 'section': 'indoor', 'is_occupied': 0},
      {'number': 3, 'name_ar': 'طاولة 3', 'name_en': 'Table 3', 'section': 'indoor', 'is_occupied': 0},
      {'number': 4, 'name_ar': 'طاولة 4', 'name_en': 'Table 4', 'section': 'indoor', 'is_occupied': 0},
      {'number': 5, 'name_ar': 'طاولة 5', 'name_en': 'Table 5', 'section': 'indoor', 'is_occupied': 0},
      {'number': 6, 'name_ar': 'طاولة 6', 'name_en': 'Table 6', 'section': 'indoor', 'is_occupied': 0},
      {'number': 7, 'name_ar': 'طاولة 7', 'name_en': 'Table 7', 'section': 'indoor', 'is_occupied': 0},
      {'number': 8, 'name_ar': 'طاولة 8', 'name_en': 'Table 8', 'section': 'indoor', 'is_occupied': 0},
      {'number': 9, 'name_ar': 'تراس 1', 'name_en': 'Terrace 1', 'section': 'terrace', 'is_occupied': 0},
      {'number': 10, 'name_ar': 'تراس 2', 'name_en': 'Terrace 2', 'section': 'terrace', 'is_occupied': 0},
      {'number': 11, 'name_ar': 'تراس 3', 'name_en': 'Terrace 3', 'section': 'terrace', 'is_occupied': 0},
      {'number': 12, 'name_ar': 'تراس 4', 'name_en': 'Terrace 4', 'section': 'terrace', 'is_occupied': 0},
      {'number': 13, 'name_ar': 'VIP 1', 'name_en': 'VIP 1', 'section': 'vip', 'is_occupied': 0},
      {'number': 14, 'name_ar': 'VIP 2', 'name_en': 'VIP 2', 'section': 'vip', 'is_occupied': 0},
      {'number': 15, 'name_ar': 'بار كاونتر', 'name_en': 'Bar Counter', 'section': 'bar', 'is_occupied': 0},
    ];
  }

  List<Map<String, dynamic>> _getInitialItems() {
    return [
      // --- Black-Coffee (قهوة ساخنة سوداء) ---
      {
        'name_ar': 'اسبريسو ماكياتو',
        'name_en': 'Macchiato',
        'category': 'hot_coffee',
        'price_small': 1.25,
        'price_medium': null,
        'price_large': null,
        'description': 'اسبريسو مع رغوة حليب خفيفة'
      },
      {
        'name_ar': 'قهوة امريكية',
        'name_en': 'Brewed Coffee',
        'category': 'hot_coffee',
        'price_small': 1.50,
        'price_medium': 1.75,
        'price_large': null,
        'description': 'قهوة مفلترة طازجة'
      },
      {
        'name_ar': 'اسبريسو',
        'name_en': 'Espresso',
        'category': 'hot_coffee',
        'price_small': 1.25,
        'price_medium': null,
        'price_large': null,
        'description': 'شوت اسبريسو غني ومركز'
      },
      {
        'name_ar': 'امريكانو ساخن',
        'name_en': 'Hot Americano',
        'category': 'hot_coffee',
        'price_small': 1.25,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'اسبريسو مع ماء ساخن'
      },
      {
        'name_ar': 'لونجو',
        'name_en': 'Lungo',
        'category': 'hot_coffee',
        'price_small': 1.50,
        'price_medium': null,
        'price_large': null,
        'description': 'اسبريسو مستخلص بمدة أطول'
      },
      {
        'name_ar': 'ريد آي',
        'name_en': 'Red Eye',
        'category': 'hot_coffee',
        'price_small': null,
        'price_medium': 2.25,
        'price_large': null,
        'description': 'قهوة مقطرة مع شوت اسبريسو إضافي'
      },
      {
        'name_ar': 'V 60 ساخن',
        'name_en': 'V60 Hot',
        'category': 'hot_coffee',
        'price_small': null,
        'price_medium': 2.75,
        'price_large': null,
        'description': 'قهوة مختصة مقطرة بطريقة V60'
      },

      // --- Milk-Based Coffee (قهوة بالحليب) ---
      {
        'name_ar': 'موكا / وايت موكا ساخن',
        'name_en': 'Hot Mocha / White',
        'category': 'hot_milk',
        'price_small': 2.00,
        'price_medium': 2.50,
        'price_large': null,
        'description': 'اسبريسو مع شوكولاتة أو وايت موكا وحليب مبخر'
      },
      {
        'name_ar': 'سبانيش لاتيه ساخن',
        'name_en': 'Hot Spanish Latte',
        'category': 'hot_milk',
        'price_small': null,
        'price_medium': 2.25,
        'price_large': null,
        'description': 'اسبريسو مع حليب مكثف محلى وحليب طازج'
      },
      {
        'name_ar': 'كراميل مكياتو ساخن',
        'name_en': 'Hot Caramel Macchiato',
        'category': 'hot_milk',
        'price_small': 2.25,
        'price_medium': 2.75,
        'price_large': null,
        'description': 'فانيلا وحليب مبخر يعلوه الاسبريسو وصوص الكراميل'
      },
      {
        'name_ar': 'فلات وايت',
        'name_en': 'Flat White',
        'category': 'hot_milk',
        'price_small': 1.75,
        'price_medium': null,
        'price_large': null,
        'description': 'دبل اسبريسو مع حليب ميكروفوم حريري'
      },
      {
        'name_ar': 'كابتشينو',
        'name_en': 'Cappuccino',
        'category': 'hot_milk',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'اسبريسو مع حليب ورغوة غنية'
      },
      {
        'name_ar': 'كورتادو',
        'name_en': 'Cortado',
        'category': 'hot_milk',
        'price_small': 1.75,
        'price_medium': null,
        'price_large': null,
        'description': 'نسب متساوية من الاسبريسو والحليب الدافئ'
      },
      {
        'name_ar': 'لاتيه ساخن',
        'name_en': 'Hot Latte',
        'category': 'hot_milk',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'اسبريسو سلس مع حليب مبخر'
      },

      // --- Other Hot (مشروبات ساخنة أخرى) ---
      {
        'name_ar': 'هوت شوكليت',
        'name_en': 'Hot Chocolate',
        'category': 'other_hot',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'شوكولاتة ساخنة كلاسيكية غنية'
      },
      {
        'name_ar': 'شوكليت بالقهوة',
        'name_en': 'Espresso Hot Chocolate',
        'category': 'other_hot',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'شوكولاتة ساخنة ممزوجة بجرعة اسبريسو'
      },
      {
        'name_ar': 'شوكليت بالقرفة',
        'name_en': 'Cinnamon Hot Chocolate',
        'category': 'other_hot',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'شوكولاتة دافئة مع نكهة القرفة العطرية'
      },
      {
        'name_ar': 'شوكليت بالكاراميل',
        'name_en': 'Caramel Hot Chocolate',
        'category': 'other_hot',
        'price_small': 1.50,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'شوكولاتة ساخنة مع صوص الكراميل اللذيذ'
      },
      {
        'name_ar': 'سحلب كابرا',
        'name_en': 'Sahlab',
        'category': 'other_hot',
        'price_small': 1.00,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'سحلب دافئ بالقرفة والمكسرات'
      },
      {
        'name_ar': 'نسكافيه',
        'name_en': 'Nescafe',
        'category': 'other_hot',
        'price_small': 0.75,
        'price_medium': 1.25,
        'price_large': null,
        'description': 'نسكافيه تقليدي بالحليب أو سادة'
      },
      {
        'name_ar': 'شاي كرك',
        'name_en': 'Karak Chai',
        'category': 'other_hot',
        'price_small': 0.75,
        'price_medium': 1.25,
        'price_large': null,
        'description': 'شاي كرك أصيل ومبهر بالهيل والزعفران'
      },
      {
        'name_ar': 'هوت لوتس',
        'name_en': 'Hot Lotus',
        'category': 'other_hot',
        'price_small': 2.00,
        'price_medium': 2.25,
        'price_large': null,
        'description': 'مشروب بسكويت وزبدة اللوتس الساخن'
      },

      // --- Iced Coffee (القهوة الباردة) ---
      {
        'name_ar': 'أمريكانو مثلج',
        'name_en': 'Iced Americano',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': 1.75,
        'description': 'اسبريسو مثلج منعش مع الماء البارد'
      },
      {
        'name_ar': 'الفريدو اسبريسو',
        'name_en': 'Alfredo Espresso',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': 1.75,
        'description': 'اسبريسو بارد ومخفوق رغوي'
      },
      {
        'name_ar': 'لاتيه مثلج',
        'name_en': 'Iced Latte',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'اسبريسو وحليب بارد مع الثلج'
      },
      {
        'name_ar': 'سبانيش لاتيه مثلج',
        'name_en': 'Iced Spanish Latte',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.25,
        'price_large': 3.00,
        'description': 'المفضل! اسبريسو وحليب مكثف وثلج'
      },
      {
        'name_ar': 'بستاشيو لاتيه مثلج',
        'name_en': 'Iced Pistachio Latte',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.75,
        'price_large': 3.00,
        'description': 'صوص الفستق الحلبي الأصلي مع الاسبريسو'
      },
      {
        'name_ar': 'كراميل مكياتو بارد',
        'name_en': 'Iced Caramel Macchiato',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.75,
        'price_large': 3.00,
        'description': 'كراميل وحليب مثلج واسبريسو مركز'
      },
      {
        'name_ar': 'موكا / وايت موكا بارد',
        'name_en': 'Iced Mocha / White Mocha',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'موكا باردة منعشة مع الثلج'
      },
      {
        'name_ar': 'دبل شيكن',
        'name_en': 'Double Shaken',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'دبل شوت اسبريسو مخفوق يدوي مع الثلج'
      },
      {
        'name_ar': 'V 60 مثلج',
        'name_en': 'V60 Iced',
        'category': 'iced_coffee',
        'price_small': null,
        'price_medium': 3.00,
        'price_large': null,
        'description': 'قهوة مختصة مقطرة على الثلج'
      },

      // --- Frappe (الفرابيه) ---
      {
        'name_ar': 'كاراميل فرابيه',
        'name_en': 'Caramel Frappe',
        'category': 'frappe',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فرابيه مثلج مخفوق بالكراميل والكريمة'
      },
      {
        'name_ar': 'توفي نت فرابيه',
        'name_en': 'Toffee Nut Frappe',
        'category': 'frappe',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فرابيه بنكهة التوفي نت الفاخرة'
      },
      {
        'name_ar': 'كوفي فرابيه',
        'name_en': 'Coffee Frappe',
        'category': 'frappe',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فرابيه القهوة الكلاسيكي المثلج'
      },
      {
        'name_ar': 'موكا / وايت فرابيه',
        'name_en': 'Mocha / White Frappe',
        'category': 'frappe',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فرابيه الشوكولاتة الداكنة أو البيضاء'
      },

      // --- Mojito (الموهيتو) ---
      {
        'name_ar': 'موهيتو بوم بوم',
        'name_en': 'BoomBoom Mojito',
        'category': 'mojito',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'موهيتو منعش مع مشروب بوم بوم والنكهات'
      },
      {
        'name_ar': 'موهيتو سفن اب',
        'name_en': '7up Mojito',
        'category': 'mojito',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'موهيتو كلاسيكي بالليمون والنعناع وسفن أب'
      },
      {
        'name_ar': 'موهيتو كودريد',
        'name_en': 'Codered Mojito',
        'category': 'mojito',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': null,
        'description': 'موهيتو طاقة مع مشروب كودريد والنكهات'
      },
      {
        'name_ar': 'موهيتو بي ام',
        'name_en': 'BM Mojito',
        'category': 'mojito',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'موهيتو بي ام مع خيارات نكهات كابرا المتنوعة'
      },

      // --- Iced Tea (الشاي المثلج) ---
      {
        'name_ar': 'شاي مثلج بالدراق',
        'name_en': 'Peach Iced Tea',
        'category': 'iced_tea',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': 1.75,
        'description': 'شاي مثلج طبيعي بنكهة الدراق المنعشة'
      },
      {
        'name_ar': 'شاي مثلج بالليمون',
        'name_en': 'Lemon Iced Tea',
        'category': 'iced_tea',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': 1.75,
        'description': 'شاي مثلج بشرائح الليمون الطبيعي'
      },
      {
        'name_ar': 'شاي فواكه استوائية',
        'name_en': 'Passion Fruit Tea',
        'category': 'iced_tea',
        'price_small': null,
        'price_medium': 1.75,
        'price_large': 2.25,
        'description': 'شاي مثلج بنكهة الباشن فروت الاستوائية'
      },
      {
        'name_ar': 'شاي التوت المشكل',
        'name_en': 'Mix Berry Tea',
        'category': 'iced_tea',
        'price_small': null,
        'price_medium': 1.75,
        'price_large': 2.25,
        'description': 'شاي مثلج غني بنكهات التوت البري المشكل'
      },

      // --- Milkshake (ميلك شيك) ---
      {
        'name_ar': 'ميلك شيك اوريو',
        'name_en': 'Oreo Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'ميلك شيك غني بقطع بسكويت الأوريو والكريمة'
      },
      {
        'name_ar': 'ميلك شيك سنيكرز',
        'name_en': 'Snickers Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'شوكولاتة وفول سوداني وكراميل سنيكرز'
      },
      {
        'name_ar': 'ميلك شيك بستاشيو',
        'name_en': 'Pistachio Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'ميلك شيك كريمي بصلصة الفستق الحلبي'
      },
      {
        'name_ar': 'ميلك شيك لوتس',
        'name_en': 'Lotus Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'بسكويت لوتس بيسكوف وزبدة اللوتس الشهية'
      },
      {
        'name_ar': 'ميلك شيك تشيز كيك',
        'name_en': 'Cheese Cake Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'مذاق التشيز كيك الغني في ميلك شيك فاخر'
      },
      {
        'name_ar': 'ميلك شيك فانيلا',
        'name_en': 'Vanilla Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فانيلا مدغشقر الكلاسيكية الناعمة'
      },
      {
        'name_ar': 'ميلك شيك كروكان',
        'name_en': 'Krokan Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'ميلك شيك مقرمش بحبات الكروكان الفاخرة'
      },
      {
        'name_ar': 'ميلك شيك تشوكليت',
        'name_en': 'Chocolate Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'شوكولاتة بلجيكية غنية وكثيفة'
      },
      {
        'name_ar': 'ميلك شيك فراولة',
        'name_en': 'Strawberry Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'فراولة طازجة وحليب مثلج'
      },
      {
        'name_ar': 'ميلك شيك باشن فروت',
        'name_en': 'Passionfruit Milkshake',
        'category': 'milkshake',
        'price_small': null,
        'price_medium': 2.50,
        'price_large': 3.00,
        'description': 'مزيج فاكهة الآلام الاستوائية اللذيذة'
      },

      // --- Smoothie (سموذي) ---
      {
        'name_ar': 'سموذي باشن فروت',
        'name_en': 'Passionfruit Smoothie',
        'category': 'smoothie',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'سموذي باشن فروت طبيعي ومثلج'
      },
      {
        'name_ar': 'سموذي ليمون ونعنع',
        'name_en': 'Lemon & Mint Smoothie',
        'category': 'smoothie',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'ليموناضة مثلجة مع أوراق النعناع الطازجة'
      },
      {
        'name_ar': 'سموذي توت مشكل',
        'name_en': 'Mix Berry Smoothie',
        'category': 'smoothie',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'توت أزرق وأحمر وأسود مهروس مع الثلج'
      },
      {
        'name_ar': 'سموذي تفاح اخضر',
        'name_en': 'Green Apple Smoothie',
        'category': 'smoothie',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'تفاح أخضر مقرمش وحامض حلو منعش'
      },
      {
        'name_ar': 'سموذي فراولة',
        'name_en': 'Strawberry Smoothie',
        'category': 'smoothie',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': 2.50,
        'description': 'سموذي الفراولة الطبيعية المنعشة'
      },

      // --- Sweets & Desserts (الحلويات والكريب) ---
      {
        'name_ar': 'مكس كريب',
        'name_en': 'Mix Crepe',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'كريب فرنسي رقيق مع مكس صوصات بلجيكية ولوتس'
      },
      {
        'name_ar': 'كريب نيوتيلا',
        'name_en': 'Nutella Crepe',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'كريب محشو بصوص شوكولاتة نوتيلا الأصلية'
      },
      {
        'name_ar': 'مكس وافل',
        'name_en': 'Mix Waffle',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 2.00,
        'price_large': null,
        'description': 'وافل بلجيكي مقرمش مع تشكيلة صوصات غنية'
      },
      {
        'name_ar': 'وافل نيوتيلا',
        'name_en': 'Nutella Waffle',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'وافل بلجيكي ذهبي مغطى بالنوتيلا'
      },
      {
        'name_ar': 'مكس بان كيك',
        'name_en': 'Mix Pancake',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 1.50,
        'price_large': null,
        'description': 'ميني بان كيك هش مع مكس صوصات لذيذة'
      },
      {
        'name_ar': 'بان كيك نيوتيلا',
        'name_en': 'Nutella Pancake',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 1.00,
        'price_large': null,
        'description': 'حبات بان كيك هشة بصوص النوتيلا'
      },

      // --- Special Offers (العروض الخاصة) ---
      {
        'name_ar': 'عرض خاص: بان كيك + هوت سبانيش',
        'name_en': 'Special Offer: Pancake + Hot Spanish',
        'category': 'sweets',
        'price_small': null,
        'price_medium': 3.00,
        'price_large': null,
        'description': 'طبق ميني بان كيك لذيذ مع كوب سبانيش لاتيه ساخن'
      },
    ];
  }

  static List<CategoryItem> _getInitialCategories() {
    return [
      CategoryItem(id: 'hot_coffee', nameAr: 'قهوة ساخنة', nameEn: 'Hot Coffee', iconName: 'coffee', sortOrder: 1),
      CategoryItem(id: 'hot_milk', nameAr: 'قهوة بالحليب', nameEn: 'Coffee with Milk', iconName: 'local_cafe', sortOrder: 2),
      CategoryItem(id: 'other_hot', nameAr: 'مشروبات ساخنة', nameEn: 'Hot Drinks', iconName: 'emoji_food_beverage', sortOrder: 3),
      CategoryItem(id: 'iced_coffee', nameAr: 'قهوة باردة', nameEn: 'Iced Coffee', iconName: 'ac_unit', sortOrder: 4),
      CategoryItem(id: 'frappe', nameAr: 'فرابيه', nameEn: 'Frappe', iconName: 'blender', sortOrder: 5),
      CategoryItem(id: 'mojito', nameAr: 'موهيتو', nameEn: 'Mojito', iconName: 'local_bar', sortOrder: 6),
      CategoryItem(id: 'iced_tea', nameAr: 'شاي مثلج', nameEn: 'Iced Tea', iconName: 'wine_bar', sortOrder: 7),
      CategoryItem(id: 'milkshake', nameAr: 'ميلك شيك', nameEn: 'Milkshake', iconName: 'icecream', sortOrder: 8),
      CategoryItem(id: 'smoothie', nameAr: 'سموذي', nameEn: 'Smoothie', iconName: 'water_drop', sortOrder: 9),
      CategoryItem(id: 'sweets', nameAr: 'حلويات وكريب', nameEn: 'Sweets & Crepe', iconName: 'cake', sortOrder: 10),
    ];
  }

  static List<AddonItem> _getInitialAddons() {
    return [
      AddonItem(nameAr: 'شوت اسبريسو إضافي', nameEn: 'Extra Espresso Shot', price: 0.50, category: 'all'),
      AddonItem(nameAr: 'حليب شوفان أو لوز', nameEn: 'Oat or Almond Milk', price: 0.50, category: 'all'),
      AddonItem(nameAr: 'صوص كراميل', nameEn: 'Caramel Syrup', price: 0.25, category: 'all'),
      AddonItem(nameAr: 'صوص فانيلا', nameEn: 'Vanilla Syrup', price: 0.25, category: 'all'),
      AddonItem(nameAr: 'صوص بندق (هازلتوت)', nameEn: 'Hazelnut Syrup', price: 0.25, category: 'all'),
      AddonItem(nameAr: 'كريمة مخفوقة', nameEn: 'Whipped Cream', price: 0.35, category: 'all'),
      AddonItem(nameAr: 'شوكولاتة / نوتيلا إضافية', nameEn: 'Extra Nutella / Choco', price: 0.50, category: 'all'),
      AddonItem(nameAr: 'سكر زيادة', nameEn: 'Extra Sugar', price: 0.00, category: 'all'),
      AddonItem(nameAr: 'سكر خفيف', nameEn: 'Light Sugar', price: 0.00, category: 'all'),
      AddonItem(nameAr: 'بدون سكر', nameEn: 'No Sugar', price: 0.00, category: 'all'),
      AddonItem(nameAr: 'ثلج زيادة', nameEn: 'Extra Ice', price: 0.00, category: 'all'),
      AddonItem(nameAr: 'بدون ثلج', nameEn: 'No Ice', price: 0.00, category: 'all'),
    ];
  }

  // --- CRUD Categories ---
  Future<List<CategoryItem>> getAllCategories() async {
    if (kIsWeb) {
      _initWebStore();
      return List.unmodifiable(_webCategories);
    }
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC, id ASC');
    if (maps.isEmpty) {
      for (var cat in _getInitialCategories()) {
        await db.insert('categories', cat.toMap());
      }
      final newMaps = await db.query('categories', orderBy: 'sort_order ASC, id ASC');
      return newMaps.map((m) => CategoryItem.fromMap(m)).toList();
    }
    return maps.map((m) => CategoryItem.fromMap(m)).toList();
  }

  Future<void> insertCategory(CategoryItem category) async {
    if (kIsWeb) {
      _initWebStore();
      _webCategories.add(category);
      return;
    }
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryItem category) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webCategories.indexWhere((c) => c.id == category.id);
      if (idx != -1) _webCategories[idx] = category;
      return;
    }
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    if (kIsWeb) {
      _initWebStore();
      _webCategories.removeWhere((c) => c.id == id);
      return;
    }
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Addons ---
  Future<List<AddonItem>> getAllAddons() async {
    if (kIsWeb) {
      _initWebStore();
      return List.unmodifiable(_webAddons);
    }
    final db = await database;
    final maps = await db.query('addons', orderBy: 'id ASC');
    if (maps.isEmpty) {
      for (var addon in _getInitialAddons()) {
        await db.insert('addons', addon.toMap());
      }
      final newMaps = await db.query('addons', orderBy: 'id ASC');
      return newMaps.map((m) => AddonItem.fromMap(m)).toList();
    }
    return maps.map((m) => AddonItem.fromMap(m)).toList();
  }

  Future<int> insertAddon(AddonItem addon) async {
    if (kIsWeb) {
      _initWebStore();
      final newId = _webAddons.length + 1;
      _webAddons.add(addon.copyWith(id: newId));
      return newId;
    }
    final db = await database;
    return await db.insert('addons', addon.toMap());
  }

  Future<int> updateAddon(AddonItem addon) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webAddons.indexWhere((a) => a.id == addon.id);
      if (idx != -1) _webAddons[idx] = addon;
      return 1;
    }
    final db = await database;
    return await db.update(
      'addons',
      addon.toMap(),
      where: 'id = ?',
      whereArgs: [addon.id],
    );
  }

  Future<int> deleteAddon(int id) async {
    if (kIsWeb) {
      _initWebStore();
      _webAddons.removeWhere((a) => a.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete('addons', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Menu Items ---
  Future<List<MenuItem>> getAllMenuItems() async {
    if (kIsWeb) {
      _initWebStore();
      return List.unmodifiable(_webMenuItems);
    }
    final db = await database;
    final maps = await db.query('menu_items', orderBy: 'id ASC');
    return maps.map((m) => MenuItem.fromMap(m)).toList();
  }

  Future<int> insertMenuItem(MenuItem item) async {
    if (kIsWeb) {
      _initWebStore();
      final newId = _webMenuItems.length + 1;
      _webMenuItems.add(item.copyWith(id: newId));
      return newId;
    }
    final db = await database;
    return await db.insert('menu_items', item.toMap());
  }

  Future<int> updateMenuItem(MenuItem item) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webMenuItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _webMenuItems[idx] = item;
      }
      return 1;
    }
    final db = await database;
    return await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMenuItem(int id) async {
    if (kIsWeb) {
      _initWebStore();
      _webMenuItems.removeWhere((i) => i.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Tables ---
  Future<List<TableInfo>> getAllTables() async {
    if (kIsWeb) {
      _initWebStore();
      return List.unmodifiable(_webTables);
    }
    final db = await database;
    final maps = await db.query('tables', orderBy: 'number ASC');
    return maps.map((m) => TableInfo.fromMap(m)).toList();
  }

  Future<int> insertTable(TableInfo table) async {
    if (kIsWeb) {
      _initWebStore();
      final newId = _webTables.length + 1;
      _webTables.add(table.copyWith(id: newId));
      return newId;
    }
    final db = await database;
    return await db.insert('tables', table.toMap());
  }

  Future<int> updateTable(TableInfo table) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webTables.indexWhere((t) => t.id == table.id);
      if (idx != -1) {
        _webTables[idx] = table;
      }
      return 1;
    }
    final db = await database;
    return await db.update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<int> deleteTable(int id) async {
    if (kIsWeb) {
      _initWebStore();
      _webTables.removeWhere((t) => t.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setTableOccupied(int tableNumber, bool occupied) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webTables.indexWhere((t) => t.number == tableNumber);
      if (idx != -1) {
        _webTables[idx] = _webTables[idx].copyWith(isOccupied: occupied);
      }
      return;
    }
    final db = await database;
    await db.update(
      'tables',
      {'is_occupied': occupied ? 1 : 0},
      where: 'number = ?',
      whereArgs: [tableNumber],
    );
  }

  // --- Orders ---
  Future<int> insertOrder(Order order) async {
    if (kIsWeb) {
      _initWebStore();
      final orderId = _webOrders.length + 1;
      final savedOrder = Order(
        id: orderId,
        orderNumber: order.orderNumber,
        tableId: order.tableId,
        tableNumber: order.tableNumber,
        tableName: order.tableName,
        waiterName: order.waiterName,
        status: order.status,
        totalAmount: order.totalAmount,
        generalNotes: order.generalNotes,
        createdAt: order.createdAt,
        items: order.items,
      );
      _webOrders.insert(0, savedOrder);
      setTableOccupied(order.tableNumber, true);
      return orderId;
    }
    final db = await database;
    return await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap());
      for (var item in order.items) {
        await txn.insert('order_items', item.toMap(orderId));
      }
      await txn.update(
        'tables',
        {'is_occupied': 1},
        where: 'id = ?',
        whereArgs: [order.tableId],
      );
      return orderId;
    });
  }

  Future<List<Order>> getAllOrders() async {
    if (kIsWeb) {
      _initWebStore();
      return List.unmodifiable(_webOrders);
    }
    final db = await database;
    final orderMaps = await db.query('orders', orderBy: 'id DESC');
    final List<Order> orders = [];

    for (var oMap in orderMaps) {
      final orderId = oMap['id'] as int;
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemMaps.map((im) => OrderItem.fromMap(im)).toList();
      orders.add(Order.fromMap(oMap, items));
    }
    return orders;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _webOrders[idx].status = status;
        if (status == 'completed' || status == 'cancelled') {
          final tNum = _webOrders[idx].tableNumber;
          final hasOtherActive = _webOrders.any(
            (o) => o.tableNumber == tNum && ['new', 'preparing', 'served'].contains(o.status),
          );
          if (!hasOtherActive) {
            setTableOccupied(tNum, false);
          }
        }
      }
      return;
    }
    final db = await database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (status == 'completed' || status == 'cancelled') {
      final orderRes = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (orderRes.isNotEmpty) {
        final tableId = orderRes.first['table_id'] as int;
        final activeOrders = await db.query(
          'orders',
          where: 'table_id = ? AND status IN ("new", "preparing", "served")',
          whereArgs: [tableId],
        );
        if (activeOrders.isEmpty) {
          await db.update('tables', {'is_occupied': 0}, where: 'id = ?', whereArgs: [tableId]);
        }
      }
    }
  }

  // --- Settings ---
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    if (kIsWeb) {
      return _webSettings[key] ?? defaultValue;
    }
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String;
    }
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      _webSettings[key] = value;
      return;
    }
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- JSON Export / Import ---
  Future<Map<String, dynamic>> exportAllData() async {
    if (kIsWeb) {
      _initWebStore();
      return {
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'cafe': 'Cabra Bean',
        'menu_items': _webMenuItems.map((m) => m.toMap()).toList(),
        'tables': _webTables.map((t) => t.toMap()).toList(),
        'categories': _webCategories.map((c) => c.toMap()).toList(),
        'addons': _webAddons.map((a) => a.toMap()).toList(),
        'settings': _webSettings.entries.map((e) => {'key': e.key, 'value': e.value}).toList(),
        'orders': _webOrders.map((o) => o.toJson()).toList(),
      };
    }
    final db = await database;
    final menuItems = await db.query('menu_items');
    final tables = await db.query('tables');
    final categories = await db.query('categories');
    final addons = await db.query('addons');
    final settings = await db.query('settings');
    final orders = await getAllOrders();

    return {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'cafe': 'Cabra Bean',
      'menu_items': menuItems,
      'tables': tables,
      'categories': categories,
      'addons': addons,
      'settings': settings,
      'orders': orders.map((o) => o.toJson()).toList(),
    };
  }

  Future<bool> importData(Map<String, dynamic> data) async {
    if (kIsWeb) {
      _initWebStore();
      try {
        if (data['settings'] != null) {
          for (var s in data['settings']) {
            _webSettings[s['key']] = s['value'];
          }
        }
        if (data['menu_items'] != null) {
          _webMenuItems.clear();
          int i = 1;
          for (var item in data['menu_items']) {
            _webMenuItems.add(MenuItem.fromMap(Map<String, dynamic>.from(item)).copyWith(id: i++));
          }
        }
        if (data['tables'] != null) {
          _webTables.clear();
          int t = 1;
          for (var tbl in data['tables']) {
            _webTables.add(TableInfo.fromMap(Map<String, dynamic>.from(tbl)).copyWith(id: t++));
          }
        }
        if (data['categories'] != null) {
          _webCategories.clear();
          for (var cat in data['categories']) {
            _webCategories.add(CategoryItem.fromMap(Map<String, dynamic>.from(cat)));
          }
        }
        if (data['addons'] != null) {
          _webAddons.clear();
          int a = 1;
          for (var addon in data['addons']) {
            _webAddons.add(AddonItem.fromMap(Map<String, dynamic>.from(addon)).copyWith(id: a++));
          }
        }
        return true;
      } catch (e) {
        return false;
      }
    }
    final db = await database;
    try {
      await db.transaction((txn) async {
        if (data['settings'] != null) {
          for (var s in data['settings']) {
            await txn.insert(
              'settings',
              {'key': s['key'], 'value': s['value']},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        if (data['menu_items'] != null) {
          await txn.delete('menu_items');
          for (var item in data['menu_items']) {
            final map = Map<String, dynamic>.from(item);
            map.remove('id');
            await txn.insert('menu_items', map);
          }
        }

        if (data['tables'] != null) {
          await txn.delete('tables');
          for (var t in data['tables']) {
            final map = Map<String, dynamic>.from(t);
            map.remove('id');
            await txn.insert('tables', map);
          }
        }

        if (data['categories'] != null) {
          await txn.delete('categories');
          for (var cat in data['categories']) {
            final map = Map<String, dynamic>.from(cat);
            await txn.insert('categories', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (data['addons'] != null) {
          await txn.delete('addons');
          for (var addon in data['addons']) {
            final map = Map<String, dynamic>.from(addon);
            map.remove('id');
            await txn.insert('addons', map);
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Active Order by Table (for Merging) ---
  Future<Order?> getActiveOrderByTable(int tableNumber) async {
    if (kIsWeb) {
      _initWebStore();
      try {
        return _webOrders.firstWhere(
          (o) => o.tableNumber == tableNumber && ['new', 'preparing', 'served'].contains(o.status),
        );
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final orderMaps = await db.query(
      'orders',
      where: 'table_number = ? AND status IN ("new", "preparing", "served")',
      whereArgs: [tableNumber],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (orderMaps.isEmpty) return null;

    final oMap = orderMaps.first;
    final orderId = oMap['id'] as int;
    final itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    final items = itemMaps.map((im) => OrderItem.fromMap(im)).toList();
    return Order.fromMap(oMap, items);
  }

  Future<Order> appendItemsToOrder(int orderId, List<OrderItem> newItems, {String additionalNotes = ''}) async {
    if (kIsWeb) {
      _initWebStore();
      final idx = _webOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final existing = _webOrders[idx];
        final combinedItems = List<OrderItem>.from(existing.items);
        for (var newItem in newItems) {
          final existingItemIdx = combinedItems.indexWhere(
            (i) => i.menuItemId == newItem.menuItemId && i.size == newItem.size && i.notes == newItem.notes,
          );
          if (existingItemIdx != -1) {
            combinedItems[existingItemIdx].quantity += newItem.quantity;
          } else {
            combinedItems.add(newItem);
          }
        }
        final newTotal = combinedItems.fold(0.0, (sum, i) => sum + i.totalPrice);
        final newNotes = additionalNotes.isNotEmpty
            ? (existing.generalNotes.isNotEmpty ? '${existing.generalNotes} | $additionalNotes' : additionalNotes)
            : existing.generalNotes;

        final updatedOrder = Order(
          id: existing.id,
          orderNumber: existing.orderNumber,
          tableId: existing.tableId,
          tableNumber: existing.tableNumber,
          tableName: existing.tableName,
          waiterName: existing.waiterName,
          status: existing.status,
          totalAmount: newTotal,
          generalNotes: newNotes,
          createdAt: existing.createdAt,
          items: combinedItems,
        );
        _webOrders[idx] = updatedOrder;
        setTableOccupied(updatedOrder.tableNumber, true);
        return updatedOrder;
      }
    }

    final db = await database;
    return await db.transaction((txn) async {
      for (var newItem in newItems) {
        await txn.insert('order_items', newItem.toMap(orderId));
      }
      final itemMaps = await txn.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final allItems = itemMaps.map((im) => OrderItem.fromMap(im)).toList();
      final newTotal = allItems.fold(0.0, (sum, i) => sum + i.totalPrice);

      final orderRes = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      final existingNotes = (orderRes.first['general_notes'] as String?) ?? '';
      final newNotes = additionalNotes.isNotEmpty
          ? (existingNotes.isNotEmpty ? '$existingNotes | $additionalNotes' : additionalNotes)
          : existingNotes;

      await txn.update(
        'orders',
        {'total_amount': newTotal, 'general_notes': newNotes},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      final updatedOrderRes = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      return Order.fromMap(updatedOrderRes.first, allItems);
    });
  }

}
