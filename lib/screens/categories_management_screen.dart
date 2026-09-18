import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_item.dart';
import '../providers/menu_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class CategoriesManagementScreen extends StatelessWidget {
  const CategoriesManagementScreen({super.key});

  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'coffee', 'icon': Icons.coffee, 'label': 'قهوة'},
    {'name': 'local_cafe', 'icon': Icons.local_cafe, 'label': 'كافيه'},
    {'name': 'emoji_food_beverage', 'icon': Icons.emoji_food_beverage, 'label': 'مشروب ساخن'},
    {'name': 'ac_unit', 'icon': Icons.ac_unit, 'label': 'مشروب مثلج'},
    {'name': 'blender', 'icon': Icons.blender, 'label': 'سموذي / فرابيه'},
    {'name': 'local_bar', 'icon': Icons.local_bar, 'label': 'موهيتو / بار'},
    {'name': 'wine_bar', 'icon': Icons.wine_bar, 'label': 'شاي مثلج'},
    {'name': 'icecream', 'icon': Icons.icecream, 'label': 'ميلك شيك / آيس كريم'},
    {'name': 'water_drop', 'icon': Icons.water_drop, 'label': 'عصائر'},
    {'name': 'cake', 'icon': Icons.cake, 'label': 'حلويات / كيك'},
    {'name': 'cookie', 'icon': Icons.cookie, 'label': 'كوكيز / بسكويت'},
    {'name': 'bakery_dining', 'icon': Icons.bakery_dining, 'label': 'مخبوزات'},
    {'name': 'fastfood', 'icon': Icons.fastfood, 'label': 'وجبات خفيفة'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'مطعم / طعام'},
    {'name': 'local_pizza', 'icon': Icons.local_pizza, 'label': 'بيتزا / معجنات'},
    {'name': 'local_drink', 'icon': Icons.local_drink, 'label': 'مشروبات'},
  ];

  void _showCategoryDialog(BuildContext context, {CategoryItem? category}) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';

    final idController = TextEditingController(text: category?.id ?? '');
    final nameArController = TextEditingController(text: category?.nameAr ?? '');
    final nameEnController = TextEditingController(text: category?.nameEn ?? '');
    String selectedIcon = category?.iconName ?? 'coffee';
    final isEditing = category != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              isEditing
                  ? (isAr ? 'تعديل التصنيف' : 'Edit Category')
                  : (isAr ? 'إضافة تصنيف جديد' : 'Add New Category'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: isAr ? 'معرف التصنيف (بالإنجليزية بدون مسافات)' : 'Category ID (e.g. cold_brew)',
                          hintText: 'مثال: cold_brew',
                          prefixIcon: const Icon(Icons.key, color: AppTheme.primaryAmber),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم التصنيف بالعربية' : 'Category Name (Arabic)',
                        hintText: 'مثال: كولد برو / قهوة مثلجة',
                        prefixIcon: const Icon(Icons.translate, color: AppTheme.primaryAmber),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم التصنيف بالإنجليزية' : 'Category Name (English)',
                        hintText: 'e.g. Cold Brew',
                        prefixIcon: const Icon(Icons.language, color: AppTheme.primaryAmber),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isAr ? 'اختر أيقونة التصنيف:' : 'Select Icon:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((ic) {
                        final isSelected = selectedIcon == ic['name'];
                        return InkWell(
                          onTap: () => setState(() => selectedIcon = ic['name'] as String),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryCoffee : AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryCoffee : AppTheme.borderSubtle,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              ic['icon'] as IconData,
                              color: isSelected ? Colors.white : AppTheme.primaryCoffee,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nameAr = nameArController.text.trim();
                  final nameEn = nameEnController.text.trim();
                  final id = isEditing
                      ? category.id
                      : idController.text.trim().toLowerCase().replaceAll(' ', '_');

                  if (nameAr.isEmpty || id.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'الرجاء إدخال الاسم والمعرّف' : 'Please fill all required fields'),
                        backgroundColor: AppTheme.statusOrange,
                      ),
                    );
                    return;
                  }

                  final newCat = CategoryItem(
                    id: id,
                    nameAr: nameAr,
                    nameEn: nameEn.isNotEmpty ? nameEn : nameAr,
                    iconName: selectedIcon,
                    sortOrder: category?.sortOrder ?? menuProvider.categories.length + 1,
                  );

                  if (isEditing) {
                    await menuProvider.updateCategory(newCat);
                  } else {
                    await menuProvider.addCategory(newCat);
                  }

                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCoffee,
                  foregroundColor: Colors.white,
                ),
                child: Text(isAr ? 'حفظ' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryItem category) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';
    final itemsCount = menuProvider.items.where((i) => i.category == category.id).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف التصنيف' : 'Delete Category'),
        content: Text(
          itemsCount > 0
              ? (isAr
                  ? 'هذا التصنيف يحتوي على $itemsCount أصناف. هل أنت متأكد من حذفه؟'
                  : 'This category contains $itemsCount items. Are you sure you want to delete it?')
              : (isAr ? 'هل أنت متأكد من حذف "${category.getName(lang)}"؟' : 'Delete "${category.getName(lang)}"?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await menuProvider.deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusRed, foregroundColor: Colors.white),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة التصنيفات' : 'Categories Management'),
      ),
      body: menuProvider.categories.isEmpty
          ? Center(
              child: Text(
                isAr ? 'لا توجد تصنيفات حالياً' : 'No categories found',
                style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: menuProvider.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = menuProvider.categories[index];
                final count = menuProvider.items.where((i) => i.category == cat.id).length;

                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.cardLatte,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Icon(cat.iconData, color: AppTheme.primaryCoffee, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.nameAr,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cat.nameEn} • (${cat.id})',
                                style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count ${isAr ? 'أصناف' : 'items'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryCoffee,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryCoffee, size: 20),
                          tooltip: isAr ? 'تعديل' : 'Edit',
                          onPressed: () => _showCategoryDialog(context, category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.statusRed, size: 20),
                          tooltip: isAr ? 'حذف' : 'Delete',
                          onPressed: () => _confirmDelete(context, cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: AppTheme.primaryCoffee,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          isAr ? 'إضافة تصنيف جديد' : 'Add Category',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
