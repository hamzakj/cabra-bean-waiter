import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/addon_item.dart';
import '../providers/cart_provider.dart';
import '../providers/addons_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class ItemDetailDialog extends StatefulWidget {
  final MenuItem item;

  const ItemDetailDialog({super.key, required this.item});

  @override
  State<ItemDetailDialog> createState() => _ItemDetailDialogState();
}

class _ItemDetailDialogState extends State<ItemDetailDialog> {
  late String _selectedSize;
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();
  final Set<AddonItem> _selectedAddons = {};

  @override
  void initState() {
    super.initState();
    final sizes = widget.item.availableSizes;
    if (sizes.contains('M')) {
      _selectedSize = 'M';
    } else if (sizes.isNotEmpty) {
      _selectedSize = sizes.first;
    } else {
      _selectedSize = 'Standard';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleAddon(AddonItem addon) {
    setState(() {
      final existing = _selectedAddons.where((a) => (a.id != null && a.id == addon.id) || a.nameAr == addon.nameAr);
      if (existing.isNotEmpty) {
        _selectedAddons.remove(existing.first);
      } else {
        _selectedAddons.add(addon);
      }
    });
  }

  bool _isAddonSelected(AddonItem addon) {
    return _selectedAddons.any((a) => (a.id != null && a.id == addon.id) || a.nameAr == addon.nameAr);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final addonsProvider = Provider.of<AddonsProvider>(context);
    final availableAddons = addonsProvider.getAddonsForCategory(widget.item.category);

    final baseUnitPrice = widget.item.getPrice(_selectedSize);
    final addonsTotal = _selectedAddons.fold(0.0, (sum, a) => sum + a.price);
    final unitPrice = baseUnitPrice + addonsTotal;
    final totalPrice = unitPrice * _quantity;
    final currency = AppStrings.get('currency', lang);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Names + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      color: AppTheme.primaryCoffee,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.getName(lang),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr ? widget.item.nameEn : widget.item.nameAr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              if (widget.item.description != null && widget.item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLatte,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.item.description!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Size Selector (if multiple sizes exist)
              if (widget.item.availableSizes.length > 1) ...[
                Text(
                  isAr ? 'اختر الحجم المطلوب:' : 'Select Size:',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: widget.item.availableSizes.map((size) {
                    final isSelected = _selectedSize == size;
                    final sizePrice = widget.item.getPrice(size);
                    String label = size;
                    if (size == 'S') label = AppStrings.get('size_small', lang);
                    if (size == 'M') label = AppStrings.get('size_medium', lang);
                    if (size == 'L') label = AppStrings.get('size_large', lang);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _selectedSize = size),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryAmber : AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryAmber : AppTheme.borderSubtle,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sizePrice.toStringAsFixed(2)} $currency',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.primaryCoffee,
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
                const SizedBox(height: 20),
              ],

              // Add-ons & Modifiers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'الإضافات والخيارات (مع السعر):' : 'Add-ons & Options:',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_selectedAddons.isNotEmpty)
                    Text(
                      '+${addonsTotal.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (availableAddons.isEmpty)
                Text(
                  isAr ? 'لا توجد إضافات مسجلة' : 'No add-ons available',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableAddons.map((addon) {
                    final isSelected = _isAddonSelected(addon);
                    final isFree = addon.price <= 0.0;
                    final priceLabel = isFree ? (isAr ? 'مجاني' : 'Free') : '+${addon.price.toStringAsFixed(2)} $currency';

                    return FilterChip(
                      label: Text('${addon.getName(lang)} ($priceLabel)'),
                      selected: isSelected,
                      onSelected: (_) => _toggleAddon(addon),
                      backgroundColor: AppTheme.cardLatte,
                      selectedColor: AppTheme.primaryAmber.withOpacity(0.22),
                      checkmarkColor: AppTheme.primaryCoffee,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppTheme.primaryCoffee : AppTheme.textDark,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryAmber : AppTheme.borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),

              // Custom Note TextField
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظة خاصة إضافية (اختياري)' : 'Special Request (Optional)',
                  hintText: isAr ? 'مثال: تقديم بعد العشاء، كاس دبل...' : 'e.g. serve after food...',
                  prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryAmber),
                  isDense: true,
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get('quantity', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardLatte,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 22, color: AppTheme.primaryCoffee),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 22, color: AppTheme.primaryCoffee),
                          onPressed: () {
                            setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add to Order Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final notesList = <String>[];
                    if (_selectedAddons.isNotEmpty) {
                      notesList.add(
                        _selectedAddons
                            .map((a) => a.price > 0 ? '${a.getName(lang)} (+${a.price.toStringAsFixed(2)})' : a.getName(lang))
                            .join(' ، '),
                      );
                    }
                    final custom = _notesController.text.trim();
                    if (custom.isNotEmpty) {
                      notesList.add(custom);
                    }
                    final combinedNotes = notesList.join(' | ');

                    Provider.of<CartProvider>(context, listen: false).addItem(
                      menuItem: widget.item,
                      size: _selectedSize,
                      quantity: _quantity,
                      notes: combinedNotes,
                      customUnitPrice: unitPrice,
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    '${AppStrings.get('add_to_order', lang)}  •  ${totalPrice.toStringAsFixed(2)} $currency',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCoffee,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
