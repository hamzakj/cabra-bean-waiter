import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/addon_item.dart';
import '../providers/addons_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class AddonsManagementScreen extends StatelessWidget {
  const AddonsManagementScreen({super.key});

  void _showAddonDialog(BuildContext context, {AddonItem? addon}) {
    final addonsProvider = Provider.of<AddonsProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';
    final isEditing = addon != null;

    final nameArController = TextEditingController(text: addon?.nameAr ?? '');
    final nameEnController = TextEditingController(text: addon?.nameEn ?? '');
    final priceController = TextEditingController(
      text: addon != null ? addon.price.toStringAsFixed(2) : '0.25',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isEditing
              ? (isAr ? 'تعديل الإضافة وسعرها' : 'Edit Add-on')
              : (isAr ? 'إضافة خيار أو صوص جديد' : 'Add New Customization'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم الإضافة بالعربية' : 'Add-on Name (Arabic)',
                    hintText: 'مثال: صوص بستاشيو، شوت إضافي، حليب صويا...',
                    prefixIcon: const Icon(Icons.tune, color: AppTheme.primaryAmber),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم الإضافة بالإنجليزية' : 'Add-on Name (English)',
                    hintText: 'e.g. Pistachio Sauce, Extra Shot...',
                    prefixIcon: const Icon(Icons.language, color: AppTheme.primaryAmber),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isAr ? 'سعر الإضافة (د.أ)' : 'Price (JOD)',
                    hintText: '0.50 (ضع 0 إذا كانت مجانية)',
                    prefixText: 'د.أ ',
                    prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryAmber),
                    helperText: isAr ? 'ضع 0 إذا كانت الإضافة مجانية (مثل: بدون سكر أو ثلج زيادة)' : 'Set 0 for free options',
                  ),
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
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;

              if (nameAr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'الرجاء إدخال اسم الإضافة بالعربية' : 'Please enter Arabic name'),
                    backgroundColor: AppTheme.statusOrange,
                  ),
                );
                return;
              }

              final item = AddonItem(
                id: addon?.id,
                nameAr: nameAr,
                nameEn: nameEn.isNotEmpty ? nameEn : nameAr,
                price: price,
                category: addon?.category ?? 'all',
                isAvailable: addon?.isAvailable ?? true,
              );

              if (isEditing) {
                await addonsProvider.updateAddon(item);
              } else {
                await addonsProvider.addAddon(item);
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, AddonItem addon) {
    final addonsProvider = Provider.of<AddonsProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).langCode;
    final isAr = lang == 'ar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف الإضافة' : 'Delete Add-on'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من حذف "${addon.getName(lang)}"؟'
              : 'Delete "${addon.getName(lang)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (addon.id != null) {
                await addonsProvider.deleteAddon(addon.id!);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRed,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addonsProvider = Provider.of<AddonsProvider>(context);
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final currency = AppStrings.get('currency', lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الإضافات والخيارات' : 'Add-ons & Modifiers'),
      ),
      body: addonsProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
          : addonsProvider.addons.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لا توجد إضافات حالياً' : 'No add-ons found',
                    style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addonsProvider.addons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final addon = addonsProvider.addons[index];
                    final isFree = addon.price <= 0.0;

                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isFree
                                    ? AppTheme.cardLatte
                                    : AppTheme.primaryAmber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFree ? AppTheme.borderSubtle : AppTheme.primaryAmber,
                                ),
                              ),
                              child: Icon(
                                isFree ? Icons.tune : Icons.add_circle,
                                color: isFree ? AppTheme.primaryCoffee : AppTheme.primaryCoffee,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addon.nameAr,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: addon.isAvailable ? AppTheme.textDark : AppTheme.textMuted,
                                      decoration: addon.isAvailable ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addon.nameEn,
                                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            // Price Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? Colors.grey.shade200
                                    : AppTheme.primaryAmber.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isFree ? Colors.grey.shade400 : AppTheme.primaryAmber,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                isFree ? (isAr ? 'مجاني' : 'Free') : '+${addon.price.toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isFree ? Colors.grey.shade700 : AppTheme.primaryCoffee,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: addon.isAvailable,
                              activeColor: AppTheme.statusGreen,
                              onChanged: (_) => addonsProvider.toggleAvailability(addon),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryCoffee, size: 20),
                              tooltip: isAr ? 'تعديل' : 'Edit',
                              onPressed: () => _showAddonDialog(context, addon: addon),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.statusRed, size: 20),
                              tooltip: isAr ? 'حذف' : 'Delete',
                              onPressed: () => _confirmDelete(context, addon),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddonDialog(context),
        backgroundColor: AppTheme.primaryCoffee,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          isAr ? 'إضافة خيار أو صوص جديد' : 'Add Customization',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
