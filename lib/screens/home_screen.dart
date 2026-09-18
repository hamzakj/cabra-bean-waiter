import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/category_item.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/item_detail_dialog.dart';
import 'cart_panel.dart';
import 'order_tracker_screen.dart';
import 'menu_management_screen.dart';
import 'tables_management_screen.dart';
import 'categories_management_screen.dart';
import 'addons_management_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.jpg',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  color: AppTheme.primaryAmber,
                  child: const Icon(Icons.coffee, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CABRA BEAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    AppStrings.get('tagline', lang),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFD7CCC8)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Order Tracker with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded),
                tooltip: AppStrings.get('orders', lang),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderTrackerScreen()),
                  );
                },
              ),
              if (ordersProvider.newCount + ordersProvider.preparingCount > 0)
                Positioned(
                  top: 8,
                  right: isAr ? null : 8,
                  left: isAr ? 8 : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryAmber,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${ordersProvider.newCount + ordersProvider.preparingCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Tables Management
          IconButton(
            icon: const Icon(Icons.table_restaurant_outlined),
            tooltip: AppStrings.get('tables', lang),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TablesManagementScreen()),
              );
            },
          ),

          // Menu & Categories & Addons Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.restaurant_menu_rounded),
            tooltip: isAr ? 'إدارة المنيو والتصنيفات' : 'Menu & Catalog',
            onSelected: (val) {
              if (val == 'menu') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
                );
              } else if (val == 'categories') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                );
              } else if (val == 'addons') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddonsManagementScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'menu',
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppTheme.primaryCoffee, size: 20),
                    const SizedBox(width: 10),
                    Text(isAr ? 'إدارة الأصناف والمنيو' : 'Menu Items'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: AppTheme.primaryCoffee, size: 20),
                    const SizedBox(width: 10),
                    Text(isAr ? 'إدارة التصنيفات' : 'Categories Management'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'addons',
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: AppTheme.primaryCoffee, size: 20),
                    const SizedBox(width: 10),
                    Text(isAr ? 'إدارة الإضافات والأسعار' : 'Add-ons & Prices'),
                  ],
                ),
              ),
            ],
          ),

          // Language Switcher
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAr ? 'EN' : 'عربي',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            tooltip: 'تبديل اللغة / Switch Language',
            onPressed: () => localeProvider.toggleLocale(),
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.get('settings', lang),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 750;

          if (isTablet) {
            // Tablet Landscape Split-View: Left Menu (~62%), Right Live Cart (~38%)
            return Row(
              children: [
                Expanded(
                  flex: 62,
                  child: _MenuCatalog(categories: menuProvider.categories),
                ),
                const VerticalDivider(width: 1, color: AppTheme.borderSubtle),
                const Expanded(
                  flex: 38,
                  child: CartPanel(),
                ),
              ],
            );
          } else {
            // Mobile Portrait: Menu + Floating Bottom Order Bar
            return Stack(
              children: [
                _MenuCatalog(categories: menuProvider.categories, isMobile: true),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MobileFloatingCartBar(),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _MenuCatalog extends StatelessWidget {
  final List<CategoryItem> categories;
  final bool isMobile;

  const _MenuCatalog({required this.categories, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) => menuProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث عن قهوة، سموذي، كريب...' : 'Search items...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAmber, size: 22),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),

              // Categories Horizontal Scroll
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 2, // 'all' + categories + 'manage'
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // All Categories Chip
                      final isSelected = menuProvider.selectedCategory == 'all';
                      return ChoiceChip(
                        avatar: Icon(
                          Icons.apps_rounded,
                          size: 18,
                          color: isSelected ? Colors.white : AppTheme.primaryCoffee,
                        ),
                        label: Text(isAr ? 'الكل' : 'All'),
                        selected: isSelected,
                        onSelected: (_) => menuProvider.selectCategory('all'),
                        selectedColor: AppTheme.primaryCoffee,
                        backgroundColor: AppTheme.cardLatte,
                        labelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryCoffee : AppTheme.borderSubtle,
                        ),
                      );
                    }

                    if (index == categories.length + 1) {
                      // Manage Categories Shortcut Chip
                      return ActionChip(
                        avatar: const Icon(Icons.settings_outlined, size: 16, color: AppTheme.primaryAmber),
                        label: Text(isAr ? 'إدارة التصنيفات' : 'Categories'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                          );
                        },
                        backgroundColor: AppTheme.cardLatte,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryCoffee),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        side: const BorderSide(color: AppTheme.primaryAmber),
                      );
                    }

                    final cat = categories[index - 1];
                    final isSelected = menuProvider.selectedCategory == cat.id;

                    return ChoiceChip(
                      avatar: Icon(
                        cat.iconData,
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.primaryCoffee,
                      ),
                      label: Text(cat.getName(lang)),
                      selected: isSelected,
                      onSelected: (_) => menuProvider.selectCategory(cat.id),
                      selectedColor: AppTheme.primaryCoffee,
                      backgroundColor: AppTheme.cardLatte,
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryCoffee : AppTheme.borderSubtle,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppTheme.borderSubtle),

        // Menu Items Grid
        Expanded(
          child: menuProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
              : menuProvider.filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        isAr ? 'لا توجد أصناف مطابقة' : 'No matching items',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, isMobile ? 85 : 14),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile ? 240 : 280,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.76,
                      ),
                      itemCount: menuProvider.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = menuProvider.filteredItems[index];
                        return _MenuItemCard(item: item);
                      },
                    ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  void _quickAddSize(BuildContext context, String size) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';

    cart.addItem(
      menuItem: item,
      size: size,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تمت إضافة "${item.getName(lang)} ($size)" للسلة ✓'
              : 'Added "${item.getName(lang)} ($size)" to cart ✓',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        backgroundColor: AppTheme.statusGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final currency = AppStrings.get('currency', lang);
    final cart = Provider.of<CartProvider>(context);

    // Calculate how many of this item are currently in cart
    final inCartQty = cart.items
        .where((i) => i.menuItemId == item.id)
        .fold(0, (sum, i) => sum + i.quantity);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCartQty > 0 ? AppTheme.primaryAmber : AppTheme.borderSubtle,
          width: inCartQty > 0 ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Tapping the card opens customization with add-ons & notes
          showDialog(
            context: context,
            builder: (_) => ItemDetailDialog(item: item),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Category icon + In-cart Badge or Category Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      color: AppTheme.primaryCoffee,
                      size: 22,
                    ),
                  ),
                  if (inCartQty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.statusGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$inCartQty ${isAr ? 'بالسلة' : 'in cart'} ✓',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLatte,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        AppStrings.get('cat_${item.category}', lang),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryCoffee,
                        ),
                      ),
                    ),
                ],
              ),

              // Center: Names (LARGE & CLEAR)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getName(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17.5,
                      color: AppTheme.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAr ? item.nameEn : item.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              // Bottom Area: Quick 1-Tap Size Buttons OR Single Add Button
              Column(
                children: [
                  const Divider(height: 12, color: AppTheme.borderSubtle),

                  // If multiple sizes, show 1-Tap Size Buttons
                  if (item.availableSizes.length > 1) ...[
                    Row(
                      children: item.availableSizes.map((size) {
                        final price = item.getPrice(size);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: InkWell(
                              onTap: () => _quickAddSize(context, size),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardLatte,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryCoffee.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      size,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryCoffee,
                                      ),
                                    ),
                                    Text(
                                      '${price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    // Customize / Add-on Link
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => ItemDetailDialog(item: item),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tune, size: 14, color: AppTheme.primaryAmber),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'تخصيص وإضافات ⚙️' : 'Customize ⚙️',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.primaryCoffee,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Single size / Standard item: Large Quick-Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.getPrice(item.availableSizes.first).toStringAsFixed(2)} $currency',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryCoffee,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _quickAddSize(context, item.availableSizes.first),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: Text(
                            isAr ? 'إضافة' : 'Add',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCoffee,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => ItemDetailDialog(item: item),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tune, size: 14, color: AppTheme.primaryAmber),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'تخصيص وإضافات ⚙️' : 'Customize ⚙️',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.primaryCoffee,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileFloatingCartBar extends StatelessWidget {
  const _MobileFloatingCartBar();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final cart = Provider.of<CartProvider>(context);
    final currency = AppStrings.get('currency', lang);

    if (cart.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryCoffee,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.totalItemCount} ${AppStrings.get('items', lang)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${cart.totalAmount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(color: AppTheme.accentCaramel, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const SizedBox(
                  height: 600,
                  child: CartPanel(isBottomSheet: true),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              AppStrings.get('view_order', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
