import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

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

    String selectedCategory = item?.category ?? 'hot_coffee';
    bool hasSmall = item?.hasSmall ?? false;
    bool hasMedium = item?.hasMedium ?? true;
    bool hasLarge = item?.hasLarge ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('category', lang),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: [
                        'hot_coffee',
                        'hot_milk',
                        'other_hot',
                        'iced_coffee',
                        'frappe',
                        'mojito',
                        'iced_tea',
                        'milkshake',
                        'smoothie',
                        'sweets',
                      ].map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(AppStrings.get('cat_$cat', lang)),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (val) => menuProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'ابحث عن صنف بالاسم...',
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
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryAmber.withOpacity(0.15),
                            child: const Icon(Icons.coffee, color: AppTheme.primaryCoffee, size: 20),
                          ),
                          title: Text(
                            item.getName(lang),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('cat_${item.category}', lang),
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryAmber),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.hasSmall)
                                    Text('S: ${item.priceSmall!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                                  if (item.hasMedium)
                                    Text('M: ${item.priceMedium!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                                  if (item.hasLarge)
                                    Text('L: ${item.priceLarge!.toStringAsFixed(2)} $currency',
                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
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
