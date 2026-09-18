import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
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
  final Set<String> _selectedQuickNotes = {};

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

  void _toggleQuickNote(String note) {
    setState(() {
      if (_selectedQuickNotes.contains(note)) {
        _selectedQuickNotes.remove(note);
      } else {
        _selectedQuickNotes.add(note);
      }
    });
  }

  String _getCombinedNotes() {
    final custom = _notesController.text.trim();
    final all = <String>[..._selectedQuickNotes];
    if (custom.isNotEmpty) {
      all.add(custom);
    }
    return all.join(' ، ');
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).langCode;
    final isAr = lang == 'ar';
    final unitPrice = widget.item.getPrice(_selectedSize);
    final totalPrice = unitPrice * _quantity;
    final currency = AppStrings.get('currency', lang);

    final quickNotes = [
      AppStrings.get('quick_notes_sugar_none', lang),
      AppStrings.get('quick_notes_sugar_light', lang),
      AppStrings.get('quick_notes_sugar_extra', lang),
      AppStrings.get('quick_notes_no_ice', lang),
      AppStrings.get('quick_notes_extra_ice', lang),
      AppStrings.get('quick_notes_extra_shot', lang),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      color: AppTheme.primaryCoffee,
                      size: 28,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          isAr ? widget.item.nameEn : widget.item.nameAr,
                          style: const TextStyle(
                            fontSize: 13,
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
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Size Selector (if multiple sizes exist)
              if (widget.item.availableSizes.length > 1) ...[
                Text(
                  isAr ? 'الحجم المطلوب' : 'Select Size',
                  style: const TextStyle(
                    fontSize: 14,
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
                          onTap: () {
                            setState(() {
                              _selectedSize = size;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryAmber : AppTheme.cardLatte,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryAmber : AppTheme.borderSubtle,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sizePrice.toStringAsFixed(2)} $currency',
                                  style: TextStyle(
                                    fontSize: 12,
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

              // Quick Notes
              Text(
                AppStrings.get('notes', lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quickNotes.map((note) {
                  final isSelected = _selectedQuickNotes.contains(note);
                  return FilterChip(
                    label: Text(note),
                    selected: isSelected,
                    onSelected: (_) => _toggleQuickNote(note),
                    backgroundColor: AppTheme.cardLatte,
                    selectedColor: AppTheme.primaryAmber.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryCoffee,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryCoffee : AppTheme.textDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryAmber : AppTheme.borderSubtle,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Custom Note TextField
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: AppStrings.get('item_notes_hint', lang),
                  prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryAmber),
                  isDense: true,
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 22),

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get('quantity', lang),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardLatte,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20, color: AppTheme.primaryCoffee),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20, color: AppTheme.primaryCoffee),
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
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final combinedNotes = _getCombinedNotes();
                    Provider.of<CartProvider>(context, listen: false).addItem(
                      menuItem: widget.item,
                      size: _selectedSize,
                      quantity: _quantity,
                      notes: combinedNotes,
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    '${AppStrings.get('add_to_order', lang)}  •  ${totalPrice.toStringAsFixed(2)} $currency',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
