import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/category_item.dart';
import '../providers/menu_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'categories_management_screen.dart';
import 'addons_management_screen.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  void _showItemDialog(BuildContext context, {MenuItem? item}) {
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    final nameArController = TextEditingController(text: item?.nameAr ?? '');
    final nameEnController = TextEditingController(text: item?.nameEn ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceSmallController = TextEditingController(
      text: item?.priceSmall != null ? item!.priceSmall!.toStringAsFixed(2) : '',
    );
    final priceMediumController = TextEditingController(
      text: item?.priceMedium != null ? item!.priceMedium!.toStringAsFixed(2) : '',
    );
    final priceLargeController = TextEditingController(
      text: item?.priceLarge != null ? item!.priceLarge!.toStringAsFixed(2) : '',
    );

    final categories = menuProvider.categories;
    String selectedCategory = item?.category ?? (categories.isNotEmpty ? categories.first.id : 'hot_coffee');
    if (categories.isNotEmpty && !categories.any((c) => c.id == selectedCategory)) {
      selectedCategory = categories.first.id;
    }

    bool hasSmall = item?.hasSmall ?? false;
    bool hasMedium = item?.hasMedium ?? true;
    bool hasLarge = item?.hasLarge ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              item == null ? AppStrings.get('add_new_item', lang) : AppStrings.get('edit_item', lang),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('item_name_ar', lang),
                        prefixIcon: const Icon(Icons.translate),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('item_name_en', lang),
                        prefixIcon: const Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dynamic Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('category', lang),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.iconData, size: 18, color: AppTheme.primaryCoffee),
                              const SizedBox(width: 8),
                              Text(cat.getName(lang)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sizes and Prices
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'الأحجام والأسعار (د.أ)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Small Size
                    CheckboxListTile(
                      title: Text(AppStrings.get('size_small', lang)),
                      value: hasSmall,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => setState(() => hasSmall = val ?? false),
                    ),
                    if (hasSmall)
                      TextField(
                        controller: priceSmallController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: AppStrings.get('price_small', lang),
                          prefixText: 'د.أ ',
                          isDense: true,
                        ),
                      ),

                    // Medium Size
                    CheckboxListTile(
                      title: Text(AppStrings.get('size_medium', lang)),
                      value: hasMedium,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => setState(() => hasMedium = val ?? false),
                    ),
                    if (hasMedium)
                      TextField(
                        controller: priceMediumController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: AppStrings.get('price_medium', lang),
                          prefixText: 'د.أ ',
                          isDense: true,
                        ),
                      ),

                    // Large Size
                    CheckboxListTile(
                      title: Text(AppStrings.get('size_large', lang)),
                      value: hasLarge,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => setState(() => hasLarge = val ?? false),
                    ),
                    if (hasLarge)
                      TextField(
                        controller: priceLargeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: AppStrings.get('price_large', lang),
                          prefixText: 'د.أ ',
                          isDense: true,
                        ),
                      ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (اختياري)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.get('cancel', lang)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nameAr = nameArController.text.trim();
                  final nameEn = nameEnController.text.trim();
                  if (nameAr.isEmpty && nameEn.isEmpty) return;

                  final pSmall = hasSmall ? double.tryParse(priceSmallController.text) : null;
                  final pMed = hasMedium ? double.tryParse(priceMediumController.text) : null;
                  final pLarge = hasLarge ? double.tryParse(priceLargeController.text) : null;

                  final newItem = MenuItem(
                    id: item?.id,
                    nameAr: nameAr.isNotEmpty ? nameAr : nameEn,
                    nameEn: nameEn.isNotEmpty ? nameEn : nameAr,
                    category: selectedCategory,
                    priceSmall: pSmall,
                    priceMedium: pMed,
                    priceLarge: pLarge,
                    description: descController.text.trim(),
                  );

                  if (item == null) {
                    await menuProvider.addItem(newItem);
                  } else {
                    await menuProvider.updateItem(newItem);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(AppStrings.get('save', lang)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final menuProvider = Provider.of<MenuProvider>(context);
    final currency = AppStrings.get('currency', lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('menu_management', lang)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(context),
        backgroundColor: AppTheme.primaryAmber,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.get('add_new_item', lang)),
      ),
      body: Column(
        children: [
          // Quick Shortcuts: Categories & Add-ons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLatte,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryCoffee.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCoffee,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.category_outlined, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr ? 'إدارة التصنيفات' : 'Categories',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryCoffee),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddonsManagementScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLatte,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr ? 'إدارة الإضافات' : 'Add-ons & Prices',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryCoffee),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryCoffee),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: TextField(
              onChanged: (val) => menuProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث عن صنف بالاسم...' : 'Search items...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAmber),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Items List
          Expanded(
            child: menuProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: menuProvider.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = menuProvider.filteredItems[index];
                      final cat = menuProvider.categories.firstWhere(
                        (c) => c.id == item.category,
                        orElse: () => CategoryItem(id: item.category, nameAr: item.category, nameEn: item.category),
                      );

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryAmber.withOpacity(0.15),
                            child: Icon(cat.iconData, color: AppTheme.primaryCoffee, size: 20),
                          ),
                          title: Text(
                            item.getName(lang),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.getName(lang),
                                style: const TextStyle(fontSize: 12.5, color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.hasSmall)
                                    Text('S: ${item.priceSmall!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  if (item.hasMedium)
                                    Text('M: ${item.priceMedium!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  if (item.hasLarge)
                                    Text('L: ${item.priceLarge!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryCoffee),
                                onPressed: () => _showItemDialog(context, item: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.statusRed),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(AppStrings.get('delete_item', lang)),
                                      content: Text(AppStrings.get('confirm_delete', lang)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(AppStrings.get('cancel', lang)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (item.id != null) {
                                              menuProvider.deleteItem(item.id!);
                                            }
                                            Navigator.pop(ctx);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusRed),
                                          child: Text(AppStrings.get('delete', lang)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
