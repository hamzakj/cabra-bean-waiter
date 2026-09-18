import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
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
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    final categories = [
      {'id': 'all', 'label': AppStrings.get('all_categories', lang), 'icon': Icons.apps},
      {'id': 'hot_coffee', 'label': AppStrings.get('cat_hot_coffee', lang), 'icon': Icons.coffee},
      {'id': 'hot_milk', 'label': AppStrings.get('cat_hot_milk', lang), 'icon': Icons.local_cafe},
      {'id': 'other_hot', 'label': AppStrings.get('cat_other_hot', lang), 'icon': Icons.emoji_food_beverage},
      {'id': 'iced_coffee', 'label': AppStrings.get('cat_iced_coffee', lang), 'icon': Icons.ac_unit},
      {'id': 'frappe', 'label': AppStrings.get('cat_frappe', lang), 'icon': Icons.blender},
      {'id': 'mojito', 'label': AppStrings.get('cat_mojito', lang), 'icon': Icons.local_bar},
      {'id': 'iced_tea', 'label': AppStrings.get('cat_iced_tea', lang), 'icon': Icons.wine_bar},
      {'id': 'milkshake', 'label': AppStrings.get('cat_milkshake', lang), 'icon': Icons.icecream},
      {'id': 'smoothie', 'label': AppStrings.get('cat_smoothie', lang), 'icon': Icons.water_drop},
      {'id': 'sweets', 'label': AppStrings.get('cat_sweets', lang), 'icon': Icons.cake},
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
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
            const SizedBox(width: 12),
            Column(
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
                ),
              ],
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

          // Menu Management
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded),
            tooltip: AppStrings.get('menu', lang),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
              );
            },
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
                  child: _MenuCatalog(categories: categories),
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
                _MenuCatalog(categories: categories, isMobile: true),
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
  final List<Map<String, dynamic>> categories;
  final bool isMobile;

  const _MenuCatalog({required this.categories, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) => menuProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'ابحث عن قهوة، سموذي، كريب...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAmber, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Categories Horizontal Scroll
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = menuProvider.selectedCategory == cat['id'];
                    return ChoiceChip(
                      avatar: Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.primaryCoffee,
                      ),
                      label: Text(cat['label'] as String),
                      selected: isSelected,
                      onSelected: (_) => menuProvider.selectCategory(cat['id'] as String),
                      selectedColor: AppTheme.primaryCoffee,
                      backgroundColor: AppTheme.cardLatte,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                        'لا توجد أصناف مطابقة',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, isMobile ? 80 : 14),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile ? 220 : 250,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.88,
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final currency = AppStrings.get('currency', lang);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
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
              // Top: Icon + Category Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      color: AppTheme.primaryCoffee,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.cardLatte,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      AppStrings.get('cat_${item.category}', lang),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCoffee,
                      ),
                    ),
                  ),
                ],
              ),

              // Center: Names
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getName(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang == 'ar' ? item.nameEn : item.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              // Bottom: Sizes & Prices + Add Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price badges
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (item.hasSmall)
                          _sizeBadge('S', item.priceSmall!, currency),
                        if (item.hasMedium)
                          _sizeBadge('M', item.priceMedium!, currency),
                        if (item.hasLarge)
                          _sizeBadge('L', item.priceLarge!, currency),
                        if (!item.hasSmall && !item.hasMedium && !item.hasLarge)
                          Text(
                            '0.00 $currency',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),

                  // Add button circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryCoffee,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizeBadge(String size, double price, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppTheme.cardLatte,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        '$size: ${price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryCoffee,
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${cart.totalAmount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(color: AppTheme.accentCaramel, fontWeight: FontWeight.bold, fontSize: 15),
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
            label: Text(AppStrings.get('view_order', lang)),
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
